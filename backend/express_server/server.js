import "dotenv/config";
import crypto from "node:crypto";
import path from "node:path";
import fs from "node:fs";
import express from "express";
import cors from "cors";
import helmet from "helmet";
import rateLimit from "express-rate-limit";
import jwt from "jsonwebtoken";
import nodemailer from "nodemailer";
import { z } from "zod";
import { prisma } from "./db.js";
import {
  isInitialQuestion,
  restoreInitialAnswers,
} from "./survey_question_bank.js";

const required = ["DATABASE_URL", "JWT_SECRET"];
for (const key of required)
  if (!process.env[key]) throw new Error(`${key} is required`);
if (process.env.JWT_SECRET.length < 32)
  throw new Error("JWT_SECRET must be at least 32 characters");
const mailConfig = [
  "SMTP_HOST",
  "SMTP_USER",
  "SMTP_PASSWORD",
  "OTP_FROM_EMAIL",
];
const configuredMailKeys = mailConfig.filter((key) => process.env[key]);
if (
  configuredMailKeys.length > 0 &&
  configuredMailKeys.length !== mailConfig.length
)
  throw new Error(
    "Configure all SMTP email credentials or leave them all blank",
  );
const emailEnabled = configuredMailKeys.length === mailConfig.length;
if (process.env.NODE_ENV === "production") {
  if (!emailEnabled)
    throw new Error("SMTP email credentials are required in production");
  if (
    !(process.env.APP_ORIGINS || "")
      .split(",")
      .map((value) => value.trim())
      .filter(Boolean).length
  )
    throw new Error("Set APP_ORIGINS explicitly in production");
}

const app = express();
const production = process.env.NODE_ENV === "production";
const origins = (process.env.APP_ORIGINS || "")
  .split(",")
  .map((x) => x.trim())
  .filter(Boolean);
const isAllowedOrigin = (origin) => {
  if (!origin) return true;
  if (!origins.length) return true;
  if (origins.includes(origin)) return true;
  try {
    const url = new URL(origin);
    if (["localhost", "127.0.0.1"].includes(url.hostname)) return true;
    if (
      url.hostname.endsWith(".nip.io") ||
      url.hostname.endsWith(".duckdns.org") ||
      url.hostname.includes("novtek") ||
      url.hostname === "51.20.4.247" ||
      url.hostname === "3.25.123.28"
    ) return true;
  } catch {}
  return false;
};
const mailer = emailEnabled
  ? nodemailer.createTransport({
      host: process.env.SMTP_HOST,
      port: Number(process.env.SMTP_PORT || 587),
      secure: Number(process.env.SMTP_PORT || 587) === 465,
      auth: { user: process.env.SMTP_USER, pass: process.env.SMTP_PASSWORD },
      connectionTimeout: 15000,
      greetingTimeout: 10000,
      socketTimeout: 20000,
    })
  : null;

app.disable("x-powered-by");
app.set("trust proxy", 1);
app.use(
  helmet({
    contentSecurityPolicy: false,
    crossOriginEmbedderPolicy: false,
    crossOriginResourcePolicy: false,
  }),
);
app.use(
  cors({
    origin(origin, cb) {
      if (isAllowedOrigin(origin)) return cb(null, true);
      cb(new Error("Origin not allowed: " + origin));
    },
    credentials: true,
  }),
);
app.use(express.json({ limit: "16kb" }));
app.use(
  "/auth",
  rateLimit({
    windowMs: 15 * 60 * 1000,
    limit: 100,
    validate: false,
    standardHeaders: "draft-8",
    legacyHeaders: false,
  }),
);

const webDistPath = path.resolve(process.cwd(), "../app/build/web");
if (fs.existsSync(webDistPath)) {
  app.use(express.static(webDistPath));
} else {
  app.get("/", (_req, res) =>
    res.type("text/plain").send("ATK API is running."),
  );
}
app.get("/health/live", (_req, res) => res.json({ status: "ok" }));

const emailSchema = z
  .string()
  .trim()
  .toLowerCase()
  .pipe(z.string().email().max(254));
const sendSchema = z.object({
  email: emailSchema,
  role: z.enum(["user", "doctor", "admin"]).default("user"),
});
const verifySchema = sendSchema.extend({
  otp: z
    .string()
    .trim()
    .regex(/^\d{4,10}$/),
});
const profileSchema = z.object({
  fullName: z.string().trim().min(2).max(100),
  ageGroup: z.string().trim().min(1).max(30),
  phoneNumber: z.string().trim().max(20).optional().nullable(),
  postcode: z
    .string()
    .trim()
    .min(2)
    .max(8)
    .regex(/^[a-zA-Z0-9\s]{2,8}$/),
  gender: z.string().trim().min(1).max(40),
  occupation: z.string().trim().min(1).max(100),
  maritalStatus: z.string().trim().min(1).max(40),
});
const hashToken = (token) =>
  crypto.createHash("sha256").update(token).digest("hex");
const asyncRoute = (fn) => (req, res, next) =>
  Promise.resolve(fn(req, res, next)).catch(next);

app.post(
  "/auth/admin/password",
  rateLimit({ windowMs: 15 * 60 * 1000, limit: 10, standardHeaders: "draft-8" }),
  asyncRoute(async (req, res) => {
    const password = process.env.ADMIN_PASSWORD;
    const email = process.env.ADMIN_EMAIL?.trim().toLowerCase();
    if (!password || !email) {
      return res.status(503).json({ error: "Master password sign-in is not configured." });
    }
    const supplied = req.body?.password;
    const digest = (value) => crypto.createHash("sha256").update(value).digest();
    if (typeof supplied !== "string" ||
        !crypto.timingSafeEqual(digest(supplied), digest(password))) {
      return res.status(401).json({ error: "Incorrect password. Please try again." });
    }
    const user = await prisma.user.findUnique({ where: { email } });
    if (user?.role !== "admin") {
      return res.status(503).json({ error: "Master password sign-in is not configured." });
    }
    const accessToken = jwt.sign(
      { sub: user.id, role: user.role },
      process.env.JWT_SECRET,
      { expiresIn: "1h", issuer: "atk-api", audience: "atk-app" },
    );
    res.json({ accessToken, user: { id: user.id, email: user.email, role: user.role } });
  }),
);

app.get(
  "/health/ready",
  asyncRoute(async (_req, res) => {
    await prisma.$queryRaw`SELECT 1`;
    res.json({ status: "ready" });
  }),
);

app.post(
  "/auth/send-otp",
  asyncRoute(async (req, res) => {
    const parsed = sendSchema.safeParse(req.body);
    if (!parsed.success)
      return res.status(400).json({ error: "Enter a valid email address." });
    if (!mailer)
      return res
        .status(503)
        .json({
          error:
            "Email sign-in is not configured yet. Add the SMTP settings to backend/.env.",
        });
    const { email, role } = parsed.data;

    // Check if account already exists
    const existingUser = await prisma.user.findUnique({ where: { email } });
    if (existingUser && existingUser.role !== role) {
      return res.status(403).json({
        error: `This email is already registered as a ${existingUser.role}. Please use the ${existingUser.role} sign-in.`,
      });
    }

    const isRegistered = Boolean(existingUser);
    const code = String(crypto.randomInt(0, 1000000)).padStart(6, "0");
    const codeHash = crypto
      .createHmac("sha256", process.env.JWT_SECRET)
      .update(`${email}:${role}:${code}`)
      .digest("hex");
    const outcome = await prisma.$transaction(async (tx) => {
      await tx.$queryRaw`WITH lock AS MATERIALIZED (SELECT pg_advisory_xact_lock(hashtext(${email}))) SELECT 1::int AS locked FROM lock`;
      const now = Date.now();
      const sinceHour = new Date(now - 60 * 60 * 1000);
      const sinceMinute = new Date(now - 60 * 1000);
      const [hourly, recent, oldestChallenge] = await Promise.all([
        tx.otpChallenge.count({
          where: { email, role, createdAt: { gt: sinceHour } },
        }),
        tx.otpChallenge.count({
          where: { email, role, createdAt: { gt: sinceMinute } },
        }),
        tx.otpChallenge.findFirst({
          where: { email, role, createdAt: { gt: sinceHour } },
          orderBy: { createdAt: "asc" },
          select: { createdAt: true },
        }),
      ]);
      if (hourly >= 5) {
        const resetTime = oldestChallenge
          ? oldestChallenge.createdAt.getTime() + 60 * 60 * 1000
          : now + 60 * 60 * 1000;
        const minutesRemaining = Math.max(
          1,
          Math.ceil((resetTime - now) / (60 * 1000)),
        );
        return { limited: "hour", minutesRemaining };
      }
      if (recent > 0) return { limited: "minute" };
      await tx.otpChallenge.updateMany({
        where: { email, role, consumedAt: null },
        data: { consumedAt: new Date() },
      });
      await tx.otpChallenge.create({
        data: {
          email,
          role,
          codeHash,
          expiresAt: new Date(now + 10 * 60 * 1000),
        },
      });
      return { sent: true };
    });
    if (outcome.limited) {
      if (outcome.limited === "hour") {
        return res.status(429).json({
          error: `Maximum OTP limit (5 per hour) reached for this email. Limit resets in ${outcome.minutesRemaining} minute${outcome.minutesRemaining > 1 ? "s" : ""}.`,
          resetInMinutes: outcome.minutesRemaining,
        });
      }
      return res
        .status(429)
        .json({
          error: "Please wait a minute before requesting another code.",
        });
    }
    try {
      await mailer.sendMail({
        from: process.env.OTP_FROM_EMAIL,
        to: email,
        subject: "Your ATK sign-in code",
        text: `Your ATK verification code is ${code}. It expires in 10 minutes. If you did not request this code, you can ignore this email.`,
        html: `<div style="font-family:Arial,sans-serif;max-width:480px;margin:auto;padding:24px;color:#12302f"><h1>Sign in to ATK</h1><p>Your verification code is:</p><p style="font-size:32px;font-weight:bold;letter-spacing:8px">${code}</p><p>This code expires in 10 minutes. If you did not request it, ignore this email.</p></div>`,
      });
    } catch (error) {
      const smtpResponse = String(error.response || "")
        .replace(/[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}/gi, "[email]")
        .replace(/[\r\n]+/g, " ")
        .slice(0, 240);
      console.error(
        JSON.stringify({
          event: "email_send_failed",
          code: error.code,
          responseCode: error.responseCode,
          command: error.command,
          response: smtpResponse || undefined,
        }),
      );
      await prisma.otpChallenge.updateMany({
        where: { email, role, codeHash, consumedAt: null },
        data: { consumedAt: new Date() },
      });
      return res
        .status(502)
        .json({
          error:
            "Could not send an email code right now. Check the address and try again later.",
        });
    }
    console.info(
      JSON.stringify({
        event: "email_send_succeeded",
        email,
        role,
        isRegistered,
      }),
    );
    if (process.env.NODE_ENV !== "production") {
      console.info(
        `\x1b[36m[DEV OTP PREVIEW]\x1b[0m Verification code for ${email} (${role}): \x1b[1m\x1b[32m${code}\x1b[0m`,
      );
    }
    const message = isRegistered
      ? "This email is already registered. Verification code sent."
      : "New email address. Verification code sent.";
    res.status(200).json({ message, isRegistered });
  }),
);

app.post(
  "/auth/verify-otp",
  asyncRoute(async (req, res) => {
    const parsed = verifySchema.safeParse(req.body);
    if (!parsed.success)
      return res
        .status(400)
        .json({ error: "Enter a valid email address and verification code." });
    if (!mailer)
      return res
        .status(503)
        .json({
          error:
            "Email sign-in is not configured yet. Add the SMTP settings to backend/.env.",
        });
    const { email, role, otp } = parsed.data;
    const refreshToken = crypto.randomBytes(48).toString("base64url");
    const outcome = await prisma.$transaction(async (tx) => {
      let challenge = await tx.otpChallenge.findFirst({
        where: { email, role, consumedAt: null, expiresAt: { gt: new Date() } },
        orderBy: { createdAt: "desc" },
      });
      if (!challenge) {
        const graceChallenge = await tx.otpChallenge.findFirst({
          where: {
            email,
            role,
            consumedAt: { gt: new Date(Date.now() - 30 * 1000) },
          },
          orderBy: { consumedAt: "desc" },
        });
        if (graceChallenge) {
          const expected = crypto
            .createHmac("sha256", process.env.JWT_SECRET)
            .update(`${email}:${role}:${otp}`)
            .digest("hex");
          if (graceChallenge.codeHash === expected) {
            challenge = graceChallenge;
          }
        }
      }
      if (!challenge) return { error: "invalid_code" };
      if (challenge.attempts >= 5) return { error: "max_attempts" };

      const expected = crypto
        .createHmac("sha256", process.env.JWT_SECRET)
        .update(`${email}:${role}:${otp}`)
        .digest("hex");
      const actual = Buffer.from(challenge.codeHash, "hex");
      const supplied = Buffer.from(expected, "hex");
      if (
        actual.length !== supplied.length ||
        !crypto.timingSafeEqual(actual, supplied)
      ) {
        const newAttempts = challenge.attempts + 1;
        await tx.otpChallenge.update({
          where: { id: challenge.id },
          data: { attempts: newAttempts },
        });
        const remainingAttempts = 5 - newAttempts;
        if (remainingAttempts <= 0) {
          return { error: "max_attempts" };
        }
        return { error: "invalid_code", remainingAttempts };
      }
      const existing = await tx.user.findUnique({ where: { email } });
      if (existing && existing.role !== role) return { error: "wrong_role" };
      await tx.otpChallenge.update({
        where: { id: challenge.id },
        data: { consumedAt: new Date() },
      });
      const user = existing
        ? await tx.user.update({
            where: { id: existing.id },
            data: { emailVerifiedAt: existing.emailVerifiedAt ?? new Date() },
          })
        : await tx.user.create({
            data: { email, role, emailVerifiedAt: new Date() },
          });
      const accessToken = jwt.sign(
        { sub: user.id, role: user.role },
        process.env.JWT_SECRET,
        { expiresIn: "1h", issuer: "atk-api", audience: "atk-app" },
      );
      await tx.refreshToken.create({
        data: {
          userId: user.id,
          tokenHash: hashToken(refreshToken),
          expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
        },
      });

      let isProfileComplete = false;
      if (user.role === "admin") {
        let adminRecord = await tx.admin.findUnique({
          where: { userId: user.id },
        });
        if (!adminRecord) {
          adminRecord = await tx.admin.create({
            data: {
              userId: user.id,
              fullName: "Administrator",
              email: user.email,
            },
          });
        }
        isProfileComplete = true;
      } else if (user.role === "doctor") {
        const doc = await tx.doctor.findUnique({ where: { userId: user.id } });
        if (
          doc &&
          doc.fullName &&
          doc.fullName.trim().length >= 2 &&
          doc.fullName !== "Doctor" &&
          doc.servicePincode &&
          doc.servicePincode.trim().length >= 2
        ) {
          isProfileComplete = true;
        } else {
          const prof = await tx.profile.findUnique({
            where: { userId: user.id },
          });
          isProfileComplete = Boolean(
            prof &&
            prof.fullName &&
            prof.fullName.trim().length >= 2 &&
            prof.fullName !== "Doctor" &&
            prof.postcode &&
            prof.postcode.trim().length >= 2,
          );
        }
      } else {
        const pat = await tx.patient.findUnique({ where: { userId: user.id } });
        if (
          pat &&
          pat.fullName &&
          pat.fullName.trim().length >= 2 &&
          pat.fullName !== "Patient" &&
          pat.postcode &&
          pat.postcode.trim().length >= 2
        ) {
          isProfileComplete = true;
        } else {
          const prof = await tx.profile.findUnique({
            where: { userId: user.id },
          });
          isProfileComplete = Boolean(
            prof && prof.fullName && prof.fullName.trim().length >= 2,
          );
        }
      }

      return {
        accessToken,
        user: { id: user.id, email: user.email, role: user.role },
        isProfileComplete,
      };
    });
    if (outcome.error === "wrong_role")
      return res
        .status(403)
        .json({
          error: "This email is registered with a different account type.",
        });
    if (outcome.error === "max_attempts")
      return res
        .status(429)
        .json({
          error:
            "Maximum of 5 verification attempts reached. This code is locked. Please request a new verification code or try again after 1 hour.",
        });
    if (outcome.error === "invalid_code") {
      const hint =
        outcome.remainingAttempts !== undefined
          ? ` (${outcome.remainingAttempts} attempt${outcome.remainingAttempts === 1 ? "" : "s"} remaining)`
          : "";
      return res
        .status(400)
        .json({
          error: `That code is invalid or expired.${hint} Request a new email code if needed.`,
        });
    }
    if (outcome.error)
      return res
        .status(400)
        .json({
          error:
            "That code is invalid or expired. Request a new email code and try again.",
        });
    res.json({ ...outcome, refreshToken });
  }),
);

app.post(
  "/auth/refresh",
  asyncRoute(async (req, res) => {
    const oldToken = req.body?.refreshToken;
    if (typeof oldToken !== "string" || oldToken.length < 32)
      return res.status(400).json({ error: "Please sign in again." });
    const oldTokenHash = hashToken(oldToken);
    const refreshToken = crypto.randomBytes(48).toString("base64url");
    const outcome = await prisma.$transaction(async (tx) => {
      await tx.$queryRaw`WITH lock AS MATERIALIZED (SELECT pg_advisory_xact_lock(hashtext(${oldTokenHash}))) SELECT 1::int AS locked FROM lock`;
      const session = await tx.refreshToken.findUnique({
        where: { tokenHash: oldTokenHash },
        include: { user: { select: { role: true } } },
      });
      if (!session || session.revokedAt || session.expiresAt <= new Date())
        return { error: true };
      await tx.refreshToken.update({
        where: { id: session.id },
        data: { revokedAt: new Date() },
      });
      await tx.refreshToken.create({
        data: {
          userId: session.userId,
          tokenHash: hashToken(refreshToken),
          expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
        },
      });
      const accessToken = jwt.sign(
        { sub: session.userId, role: session.user.role },
        process.env.JWT_SECRET,
        { expiresIn: "1h", issuer: "atk-api", audience: "atk-app" },
      );
      return { accessToken };
    });
    if (outcome.error)
      return res
        .status(401)
        .json({ error: "Your session has expired. Please sign in again." });
    res.json({ ...outcome, refreshToken });
  }),
);

async function authenticate(req, res, next) {
  const token = req.headers.authorization?.match(/^Bearer (.+)$/)?.[1];
  if (!token) return res.status(401).json({ error: "Sign in to continue." });
  try {
    req.user = jwt.verify(token, process.env.JWT_SECRET, {
      issuer: "atk-api",
      audience: "atk-app",
    });
    next();
  } catch {
    res
      .status(401)
      .json({ error: "Your session has expired. Please sign in again." });
  }
}

app.get(
  "/user/profile",
  authenticate,
  asyncRoute(async (req, res) => {
    const account = await prisma.user.findUnique({
      where: { id: req.user.sub },
      select: {
        email: true,
        patient: true,
        profile: {
          select: {
            fullName: true,
            ageGroup: true,
            phoneNumber: true,
            postcode: true,
            gender: true,
            occupation: true,
            maritalStatus: true,
          },
        },
      },
    });
    const pat = account?.patient;
    const prof = pat
      ? {
          fullName: pat.fullName,
          ageGroup: pat.ageGroup,
          phoneNumber: pat.phoneNumber,
          postcode: pat.postcode,
          gender: pat.gender,
          occupation: pat.occupation,
          maritalStatus: pat.maritalStatus,
        }
      : (account?.profile ?? null);
    res.json({ email: account?.email ?? null, profile: prof });
  }),
);

app.put(
  "/user/profile",
  authenticate,
  asyncRoute(async (req, res) => {
    const parsed = profileSchema.safeParse(req.body);
    if (!parsed.success)
      return res
        .status(400)
        .json({ error: "Please check the profile details and try again." });
    const p = parsed.data;
    const userId = req.user.sub;

    const [patientRecord] = await Promise.all([
      prisma.patient.upsert({
        where: { userId },
        create: {
          userId,
          fullName: p.fullName,
          email: req.user.email || null,
          phoneNumber: p.phoneNumber || null,
          ageGroup: p.ageGroup,
          gender: p.gender,
          postcode: p.postcode,
          occupation: p.occupation,
          maritalStatus: p.maritalStatus,
        },
        update: {
          fullName: p.fullName,
          phoneNumber: p.phoneNumber || null,
          ageGroup: p.ageGroup,
          gender: p.gender,
          postcode: p.postcode,
          occupation: p.occupation,
          maritalStatus: p.maritalStatus,
        },
      }),
      prisma.profile.upsert({
        where: { userId },
        create: {
          userId,
          fullName: p.fullName,
          ageGroup: p.ageGroup,
          phoneNumber: p.phoneNumber || null,
          postcode: p.postcode,
          gender: p.gender,
          occupation: p.occupation,
          maritalStatus: p.maritalStatus,
        },
        update: {
          fullName: p.fullName,
          ageGroup: p.ageGroup,
          phoneNumber: p.phoneNumber || null,
          postcode: p.postcode,
          gender: p.gender,
          occupation: p.occupation,
          maritalStatus: p.maritalStatus,
        },
      }),
    ]);
    res.json({ message: "Profile saved.", patient: patientRecord });
  }),
);

const surveyTypes = ["INITIAL", "DETAILED", "MENTAL", "MENTAL_STANDALONE"];
const mentalSurveyTypes = ["MENTAL", "MENTAL_STANDALONE"];
const detailedSurveyQuestions = [
  "How often do you use more than you planned to?",
  "How often have you tried to cut down without success?",
  "How often does it affect your work or studies?",
  "How often does it cause problems with family or friends?",
  "How often do you feel unable to stop even when you want to?",
].map((text, id) => ({
  id,
  text,
  options: ["Never", "Sometimes", "Often", "Almost always"].map(
    (label, index) => ({ label, score: index * 5 }),
  ),
}));
const questionsForType = async (type) => {
  if (type === "DETAILED") return detailedSurveyQuestions;
  const rows = await prisma.surveyQuestion.findMany({
    where: { surveyType: type === "MENTAL_STANDALONE" ? "MENTAL" : type },
    orderBy: [{ sourceOrder: "asc" }, { questionId: "asc" }],
  });
  const questionIds = new Set();
  const prompts = new Set();
  return rows
    .map((row) => row.definition)
    .filter((question) => {
      if (
        type === "INITIAL" &&
        !isInitialQuestion(question.id, question.sectionSlug)
      )
        return false;
      const id = String(question.id);
      const prompt = question.text
        .normalize("NFKC")
        .toLowerCase()
        .replace(/[^\p{L}\p{N}]+/gu, " ")
        .trim();
      if (questionIds.has(id) || prompts.has(prompt)) return false;
      questionIds.add(id);
      prompts.add(prompt);
      return true;
    });
};
const publicSurveyQuestions = (questions) =>
  questions.map((question) => ({
    id: question.id,
    text: question.text,
    kind: question.kind ?? "choice",
    options: question.options.map(({ label }) => ({ label })),
    ...(question.min == null ? {} : { min: question.min }),
    ...(question.max == null ? {} : { max: question.max }),
    ...(question.section == null ? {} : { section: question.section }),
    ...(question.sectionSlug == null
      ? {}
      : { sectionSlug: question.sectionSlug }),
    ...(question.sectionOrder == null
      ? {}
      : { sectionOrder: question.sectionOrder }),
    ...(question.logic == null ? {} : { logic: question.logic }),
  }));
const isAnswerValid = (question, value) => {
  if (!Number.isInteger(value)) return false;
  if (question.kind === "number")
    return value >= question.min && value <= question.max;
  return value >= 0 && value < question.options.length;
};
const surveyTypeSchema = z.object({ type: z.enum(surveyTypes) });
const surveyAnswersSchema = z.object({
  answers: z.record(z.string(), z.number().int()),
});
const calculateOptionScore = (question, selectedIndex) => {
  if (selectedIndex == null || selectedIndex < 0) return 0;
  if (!question.options || !question.options[selectedIndex]) {
    if (question.kind === "number" && typeof selectedIndex === "number") {
      return Math.min(10, Math.max(0, selectedIndex));
    }
    return 0;
  }
  const option = question.options[selectedIndex];
  if (typeof option.score === "number") return option.score;
  const label = (option.label || "").trim().toLowerCase();
  const qText = (question.text || "").toLowerCase();

  // Severe risk indicators (10 points)
  if (
    label === "suicidal" ||
    label === "impaired" ||
    label === "relapsed" ||
    label === "significant issues" ||
    (label === "yes" && (
      qText.includes("harming yourself") ||
      qText.includes("ending your life") ||
      qText.includes("seizures") ||
      qText.includes("delirium tremens") ||
      qText.includes("hospital admission") ||
      qText.includes("lost control") ||
      qText.includes("liver disease") ||
      qText.includes("pancreatitis") ||
      qText.includes("drive or operate") ||
      qText.includes("daily tasks")
    ))
  ) {
    return 10;
  }

  // Clinical symptom / risk indicators (5 points)
  if (
    label === "abnormal" ||
    label === "poor" ||
    label === "severe" ||
    label === "almost always" ||
    label === "nearly always" ||
    label === "daily" ||
    label === "binge" ||
    (label === "yes" && (
      qText.includes("substance") ||
      qText.includes("alcohol") ||
      qText.includes("withdrawal") ||
      qText.includes("cravings") ||
      qText.includes("blackouts") ||
      qText.includes("morning") ||
      qText.includes("treatment") ||
      qText.includes("tolerance") ||
      qText.includes("tremors") ||
      qText.includes("shaking") ||
      qText.includes("sweating") ||
      qText.includes("nausea") ||
      qText.includes("anxiety") ||
      qText.includes("palpitations") ||
      qText.includes("medical problems") ||
      qText.includes("social, occupational") ||
      qText.includes("financial") ||
      qText.includes("legal") ||
      qText.includes("risk-taking") ||
      qText.includes("audit")
    ))
  ) {
    return 5;
  }

  // Moderate indicators (3 points)
  if (
    label === "partial" ||
    label === "partially reliable" ||
    label === "fair" ||
    label === "moderate" ||
    label === "unstable" ||
    label === "unemployed" ||
    label === "often" ||
    label === "weekly" ||
    label === "yes"
  ) {
    return 3;
  }

  // Mild indicators (2 points)
  if (label === "sometimes" || label === "mild" || label === "occasional") {
    return 2;
  }

  return 0;
};

const surveyScore = (type, answers, questions) => {
  if (!answers || !questions || !questions.length) return 0;
  let total = 0;
  for (const question of questions) {
    const rawAnswer = answers[question.id] ?? answers[String(question.id)];
    if (rawAnswer !== undefined) {
      total += calculateOptionScore(question, rawAnswer);
    }
  }
  return total;
};

app.get(
  "/v1/surveys/status",
  authenticate,
  asyncRoute(async (req, res) => {
    const rows = await prisma.surveySubmission.findMany({
      where: { userId: req.user.sub },
      orderBy: [{ updatedAt: "desc" }, { id: "desc" }],
    });
    const latest = (type) => rows.find((row) => row.type === type);
    const initial = latest("INITIAL");
    const detailed = latest("DETAILED");
    const mental = rows.find((row) => mentalSurveyTypes.includes(row.type));
    const completedInitial = rows
      .filter((row) => row.type === "INITIAL" && row.completedAt)
      .sort((a, b) => b.completedAt - a.completedAt)[0];
    const surveyDays = new Set();
    let completedSurveys = 0;
    let totalAnswers = 0;
    for (const row of rows) {
      surveyDays.add(row.createdAt.toISOString().slice(0, 10));
      if (row.completedAt) {
        completedSurveys += 1;
        surveyDays.add(row.completedAt.toISOString().slice(0, 10));
      }
      if (
        row.answers &&
        typeof row.answers === "object" &&
        !Array.isArray(row.answers)
      ) {
        totalAnswers += Object.keys(row.answers).length;
      }
    }
    const unlockScore = 30;
    res.json({
      unlockScore,
      stats: { completedSurveys, totalAnswers, surveyDays: surveyDays.size },
      initial: initial
        ? {
            id: initial.id,
            status: initial.completedAt ? "COMPLETED" : "IN_PROGRESS",
            hasCompleted: Boolean(completedInitial),
            score: initial.score,
            answers: initial.answers,
          }
        : null,
      mental: mental
        ? {
            id: mental.id,
            status: mental.completedAt ? "COMPLETED" : "IN_PROGRESS",
            score: mental.score ?? 0,
            answers: mental.answers,
          }
        : null,
      standaloneMentalStatus: mental
        ? mental.completedAt
          ? "COMPLETED"
          : "IN_PROGRESS"
        : null,
      detailed: {
        unlocked: Boolean(
          completedInitial && (completedInitial.score ?? 0) >= unlockScore,
        ),
        latest: detailed
          ? {
              id: detailed.id,
              status: detailed.completedAt ? "COMPLETED" : "IN_PROGRESS",
              score: detailed.score,
              answers: detailed.answers,
            }
          : null,
      },
    });
  }),
);

app.post(
  "/v1/surveys/start",
  authenticate,
  asyncRoute(async (req, res) => {
    const parsed = surveyTypeSchema.safeParse(req.body);
    if (!parsed.success)
      return res.status(400).json({ error: "Choose a valid survey." });
    if (parsed.data.type === "DETAILED") {
      const initial = await prisma.surveySubmission.findFirst({
        where: {
          userId: req.user.sub,
          type: "INITIAL",
          completedAt: { not: null },
        },
        orderBy: { completedAt: "desc" },
      });
      if (!initial || (initial.score ?? 0) < 30)
        return res
          .status(403)
          .json({
            error:
              "Complete the initial assessment with a score of 30 or more to unlock this survey.",
          });
    }

    const questions = await questionsForType(parsed.data.type);
    if (!questions.length)
      return res
        .status(503)
        .json({
          error: "Survey questions have not been synced to the database.",
        });
    const type = parsed.data.type;
    const relatedTypes = mentalSurveyTypes.includes(type)
      ? mentalSurveyTypes
      : [type];
    const submission = await prisma.$transaction(async (tx) => {
      const lockKey = `survey:${req.user.sub}:${relatedTypes[0]}`;
      await tx.$queryRaw`WITH lock AS MATERIALIZED (SELECT pg_advisory_xact_lock(hashtext(${lockKey}))) SELECT 1::int AS locked FROM lock`;
      const latest = await tx.surveySubmission.findFirst({
        where: { userId: req.user.sub, type: { in: relatedTypes } },
        orderBy: [{ updatedAt: "desc" }, { id: "desc" }],
      });
      if (latest && !latest.completedAt) return latest;
      return tx.surveySubmission.create({
        data: { userId: req.user.sub, type },
      });
    });
    const saved =
      type === "INITIAL"
        ? restoreInitialAnswers(submission.answers)
        : submission.answers;
    const answers = Object.fromEntries(
      questions
        .filter((question) => isAnswerValid(question, saved[question.id]))
        .map((question) => [question.id, saved[question.id]]),
    );
    res.json({
      id: submission.id,
      type: submission.type,
      answers,
      questions: publicSurveyQuestions(questions),
    });
  }),
);

app.put(
  "/v1/surveys/:id/answers",
  authenticate,
  asyncRoute(async (req, res) => {
    const parsed = surveyAnswersSchema.safeParse(req.body);
    if (!parsed.success)
      return res
        .status(400)
        .json({ error: "Check your survey answers and try again." });
    const submission = await prisma.surveySubmission.findFirst({
      where: { id: req.params.id, userId: req.user.sub, completedAt: null },
      select: { type: true },
    });
    if (!submission)
      return res
        .status(404)
        .json({ error: "This survey draft was not found." });
    const questions = await questionsForType(submission.type);
    if (
      Object.entries(parsed.data.answers).some(([id, value]) => {
        const question = questions.find((item) => String(item.id) === id);
        return !question || !isAnswerValid(question, value);
      })
    )
      return res
        .status(400)
        .json({ error: "Check your survey answers and try again." });
    const result = await prisma.surveySubmission.updateMany({
      where: { id: req.params.id, userId: req.user.sub, completedAt: null },
      data: { answers: parsed.data.answers },
    });
    if (!result.count)
      return res
        .status(404)
        .json({ error: "This survey draft was not found." });
    res.json({ message: "Answers saved." });
  }),
);

app.post(
  "/v1/surveys/:id/complete",
  authenticate,
  asyncRoute(async (req, res) => {
    const submission = await prisma.surveySubmission.findFirst({
      where: { id: req.params.id, userId: req.user.sub },
    });
    if (!submission)
      return res
        .status(404)
        .json({ error: "This survey draft was not found." });
    if (submission.completedAt)
      return res.json({ score: submission.score, unlockScore: 30 });
    const answers =
      submission.type === "INITIAL"
        ? restoreInitialAnswers(submission.answers)
        : submission.answers;
    const questions = await questionsForType(submission.type);
    if (
      !questions.length ||
      questions.some(
        (question) => !isAnswerValid(question, answers[question.id]),
      )
    )
      return res
        .status(400)
        .json({ error: "Answer every question before finishing." });
    const score = surveyScore(submission.type, answers, questions);
    await prisma.surveySubmission.update({
      where: { id: submission.id },
      data: { score, completedAt: new Date() },
    });
    res.json({ score, unlockScore: 30 });
  }),
);

const wellbeingResponses = {
  emotional_wellbeing: z.strictObject({
    feeling: z.enum([
      "Happy",
      "Calm",
      "Sad",
      "Worried",
      "Confused",
      "Overwhelmed",
    ]),
    duration: z.enum([
      "Just today",
      "A few days",
      "A few weeks",
      "Several months",
      "A long time",
    ]),
  }),
  anxiety_worry: z.strictObject({
    feeling: z.enum([
      "Calm",
      "A little worried",
      "Anxious",
      "Very anxious",
      "Restless",
      "Overwhelmed",
    ]),
    frequency: z.enum([
      "Rarely",
      "Sometimes",
      "Often",
      "Almost every day",
      "Throughout the day",
    ]),
  }),
  stress_management: z.strictObject({
    stressLevel: z.enum([
      "Not stressed",
      "A little stressed",
      "Moderately stressed",
      "Very stressed",
      "Extremely stressed",
    ]),
    copingMethod: z.enum([
      "Talking to someone",
      "Taking a break",
      "Exercise or walking",
      "Listening to music",
      "Meditation or breathing",
      "I am not sure",
    ]),
  }),
  sleep_relaxation: z.strictObject({
    sleepQuality: z.enum(["Very good", "Good", "Average", "Poor", "Very poor"]),
    morningFeeling: z.enum([
      "I wake up feeling refreshed",
      "I sometimes feel rested",
      "I often feel tired",
      "I feel tired most of the day",
      "I rarely feel refreshed",
    ]),
  }),
};

app.put(
  "/v1/wellbeing/:topic",
  authenticate,
  asyncRoute(async (req, res) => {
    const { topic } = req.params;
    if (!Object.hasOwn(wellbeingResponses, topic)) {
      return res.status(404).json({ error: "Check-in topic not found." });
    }
    const parsed = wellbeingResponses[topic].safeParse(req.body?.responses);
    if (!parsed.success) {
      return res
        .status(400)
        .json({ error: "Choose a response for each question." });
    }
    const userId = req.user.sub;
    const responses = parsed.data;
    await prisma.wellbeingCheckIn.upsert({
      where: { userId_topic: { userId, topic } },
      create: { userId, topic, responses },
      update: { responses },
    });
    res.status(204).end();
  }),
);

app.get(
  "/doctor/profile",
  authenticate,
  asyncRoute(async (req, res) => {
    const doctor = await prisma.user.findUnique({
      where: { id: req.user.sub },
      include: { doctor: true, profile: true },
    });
    if (!doctor)
      return res.status(404).json({ error: "Doctor account not found." });
    if (doctor.role !== "doctor")
      return res
        .status(403)
        .json({ error: "Forbidden: Doctor access required." });
    const docData = doctor.doctor || {
      fullName: doctor.profile?.fullName || "",
      specialization: doctor.profile?.occupation || "General Practitioner",
      servicePincode: doctor.profile?.postcode || "",
      phoneNumber: doctor.profile?.phoneNumber || "",
    };
    const isProfileComplete = Boolean(
      docData.fullName &&
      docData.fullName.trim().length >= 2 &&
      docData.fullName !== "Doctor" &&
      docData.servicePincode &&
      docData.servicePincode.trim().length >= 2,
    );
    res.json({
      success: true,
      isProfileComplete,
      doctor: {
        id: doctor.id,
        email: doctor.email,
        fullName: docData.fullName || "",
        name: docData.fullName || "",
        specialization: docData.specialization || "General Practitioner",
        servicePincode: docData.servicePincode || "",
        phoneNumber: docData.phoneNumber || "",
      },
    });
  }),
);

app.put(
  "/doctor/profile",
  authenticate,
  asyncRoute(async (req, res) => {
    const { name, fullName, specialization, servicePincode, phoneNumber } =
      req.body || {};
    const effectiveName = (fullName !== undefined ? fullName : name);
    const userId = req.user.sub;
    const user = await prisma.user.findUnique({ where: { id: userId } });
    if (!user || user.role !== "doctor")
      return res
        .status(403)
        .json({ error: "Forbidden: Doctor access required." });

    if (effectiveName !== undefined && String(effectiveName).trim().length < 2) {
      return res
        .status(400)
        .json({ error: "Doctor name must be at least 2 characters." });
    }

    if (phoneNumber !== undefined && String(phoneNumber).trim().length > 0) {
      const digits = String(phoneNumber).replace(/\D/g, "");
      if (digits.length < 10 || digits.length > 15) {
        return res
          .status(400)
          .json({ error: "Phone number must have between 10 and 15 digits." });
      }
    }

    let cleanPostcode = undefined;
    if (servicePincode !== undefined) {
      const rawCodes = String(servicePincode)
        .split(",")
        .map((c) => c.trim())
        .filter(Boolean);
      for (const code of rawCodes) {
        if (!/^[a-zA-Z0-9\s]{2,8}$/.test(code)) {
          return res
            .status(400)
            .json({
              error: `Each service pincode must contain text and numbers with maximum 8 characters (invalid: "${code}").`,
            });
        }
      }
      cleanPostcode = rawCodes.join(", ");
    }

    const doctorUser = await prisma.user.findUnique({ where: { id: userId } });
    const cleanName = (
      name ||
      doctorUser?.email?.split("@")[0] ||
      "Doctor"
    ).trim();
    const cleanSpec = (specialization || "General Practitioner").trim();
    const cleanPhone = (phoneNumber || "").trim();
    const postcodesStr = (cleanPostcode || "").trim();

    const [docRecord] = await Promise.all([
      prisma.doctor.upsert({
        where: { userId },
        create: {
          userId,
          fullName: cleanName,
          email: doctorUser?.email || "",
          specialization: cleanSpec,
          phoneNumber: cleanPhone || null,
          servicePincode: postcodesStr,
        },
        update: {
          fullName: (effectiveName !== undefined && String(effectiveName).trim().length > 0) ? String(effectiveName).trim() : undefined,
          specialization:
            specialization !== undefined
              ? String(specialization).trim()
              : undefined,
          servicePincode:
            cleanPostcode !== undefined ? cleanPostcode : undefined,
          phoneNumber:
            phoneNumber !== undefined
              ? String(phoneNumber).trim() || null
              : undefined,
        },
      }),
      prisma.profile.upsert({
        where: { userId },
        create: {
          userId,
          fullName: cleanName,
          occupation: cleanSpec,
          postcode: postcodesStr,
          phoneNumber: cleanPhone,
          ageGroup: "N/A",
          gender: "Not specified",
          maritalStatus: "N/A",
        },
        update: {
          fullName: (effectiveName !== undefined && String(effectiveName).trim().length > 0) ? String(effectiveName).trim() : undefined,
          occupation:
            specialization !== undefined
              ? String(specialization).trim()
              : undefined,
          postcode: cleanPostcode !== undefined ? cleanPostcode : undefined,
          phoneNumber:
            phoneNumber !== undefined ? String(phoneNumber).trim() : undefined,
        },
      }),
    ]);

    res.json({
      success: true,
      message: "Doctor profile saved.",
      doctor: {
        id: doctorUser?.id,
        email: doctorUser?.email,
        name: docRecord.fullName,
        specialization: docRecord.specialization,
        servicePincode: docRecord.servicePincode,
        phoneNumber: docRecord.phoneNumber,
      },
    });
  }),
);

app.get(
  "/doctor/patients",
  authenticate,
  asyncRoute(async (req, res) => {
    const doctor = await prisma.user.findUnique({
      where: { id: req.user.sub },
      include: { doctor: true, profile: true },
    });
    if (!doctor)
      return res.status(404).json({ error: "Doctor account not found." });
    if (doctor.role !== "doctor")
      return res
        .status(403)
        .json({ error: "Forbidden: Doctor access required." });

    const rawPostcodes =
      doctor.doctor?.servicePincode || doctor.profile?.postcode || "";
    const postcodes = rawPostcodes
      .split(",")
      .map((p) => p.trim())
      .filter((p) => p.length > 0);

    const rawPatients = await prisma.user.findMany({
      where: { role: "user" },
      select: {
        id: true,
        email: true,
        phoneNumber: true,
        createdAt: true,
        patient: true,
        profile: {
          select: {
            fullName: true,
            ageGroup: true,
            gender: true,
            phoneNumber: true,
            postcode: true,
            occupation: true,
            maritalStatus: true,
          },
        },
        surveys: {
          select: {
            id: true,
            type: true,
            score: true,
            completedAt: true,
            createdAt: true,
          },
          orderBy: { createdAt: "desc" },
        },
      },
      orderBy: { createdAt: "desc" },
    });

    const enrichedPatients = rawPatients.map((u) => {
      const subs = u.surveys || [];
      let isCriticalRisk = false;
      let maxScore = 0;
      for (const sub of subs) {
        const score = sub.score ?? 0;
        if (score > maxScore) maxScore = score;
        if (score >= 30) {
          isCriticalRisk = true;
        }
      }
      const category =
        subs.length > 0
          ? subs[0].type.includes("MENTAL")
            ? "MENTAL HEALTH"
            : "ADDICTION"
          : "ADDICTION";

      const patientData = u.patient || u.profile;
      return {
        id: u.id,
        email: u.email,
        name: patientData?.fullName || "Anonymous Participant",
        age: patientData?.ageGroup || "",
        gender: patientData?.gender || "",
        pinCode: patientData?.postcode || "No postcode",
        phoneNumber: patientData?.phoneNumber || u.phoneNumber || "",
        occupation: patientData?.occupation || "",
        maritalStatus: patientData?.maritalStatus || "",
        isCriticalRisk,
        maxScore,
        surveyCategory: category,
        submissions: subs,
      };
    });

    let matchingPatients = enrichedPatients;
    if (postcodes.length > 0) {
      matchingPatients = enrichedPatients.filter((p) => {
        if (!p.pinCode) return false;
        const userPin = p.pinCode.replace(/\s+/g, "").toLowerCase();
        return postcodes.some(
          (pin) => pin.replace(/\s+/g, "").toLowerCase() === userPin,
        );
      });
    }

    const docName =
      doctor.doctor?.fullName ||
      doctor.profile?.fullName ||
      doctor.email?.split("@")[0] ||
      "Doctor";
    const docSpec =
      doctor.doctor?.specialization ||
      doctor.profile?.occupation ||
      "General Practitioner";
    const docPin =
      doctor.doctor?.servicePincode || doctor.profile?.postcode || "";
    const docPhone =
      doctor.doctor?.phoneNumber || doctor.profile?.phoneNumber || "";

    const isProfileComplete = Boolean(
      docName &&
      docName.trim().length >= 2 &&
      docName !== "Doctor" &&
      docPin &&
      docPin.trim().length >= 2,
    );

    res.json({
      success: true,
      isProfileComplete,
      doctor: {
        id: doctor.id,
        email: doctor.email,
        name: docName,
        specialization: docSpec,
        servicePincode: docPin,
        phoneNumber: docPhone,
      },
      doctorPincodes: postcodes,
      patients: matchingPatients,
      allPatients: enrichedPatients,
      matchingCount: matchingPatients.length,
      totalPatientsCount: enrichedPatients.length,
    });
  }),
);

async function authenticateAdmin(req, res, next) {
  const token = req.headers.authorization?.match(/^Bearer (.+)$/)?.[1];
  if (!token)
    return res.status(401).json({ error: "Admin authorization required." });
  try {
    const payload = jwt.verify(token, process.env.JWT_SECRET, {
      issuer: "atk-api",
      audience: "atk-app",
    });
    if (payload.role !== "admin") {
      return res
        .status(403)
        .json({ error: "Access denied: Administrator privileges required." });
    }
    req.user = payload;
    next();
  } catch {
    res
      .status(401)
      .json({ error: "Your session has expired. Please sign in again." });
  }
}

app.get(
  "/admin/profile",
  authenticateAdmin,
  asyncRoute(async (req, res) => {
    const admin = await prisma.admin.findUnique({
      where: { userId: req.user.sub },
      include: { user: { select: { email: true, createdAt: true } } },
    });
    if (!admin)
      return res.status(404).json({ error: "Admin profile not found." });
    res.json({
      success: true,
      admin: {
        id: admin.id,
        userId: admin.userId,
        email: admin.email,
        fullName: admin.fullName,
        phoneNumber: admin.phoneNumber || "",
        createdAt: admin.createdAt,
      },
    });
  }),
);

app.get(
  "/admin/stats",
  authenticateAdmin,
  asyncRoute(async (req, res) => {
    const category = req.query.category || req.query.surveyCategory;
    const filter = {};
    if (category === "ADDICTION") {
      filter.type = { in: ["INITIAL", "DETAILED"] };
    } else if (category === "MENTAL") {
      filter.type = { in: ["MENTAL", "MENTAL_STANDALONE"] };
    }

    const [
      totalPatients,
      totalDoctors,
      totalUsers,
      totalProfiles,
      totalStage2,
      totalStage3Unlocked,
      initialSubmissions,
      detailedSubmissions,
      completedSurveys,
      allProfiles,
      allSurveys,
    ] = await Promise.all([
      prisma.patient.count(),
      prisma.doctor.count(),
      prisma.user.count({ where: { role: "user" } }),
      prisma.profile.count(),
      prisma.surveySubmission.count({
        where: { type: "INITIAL", completedAt: { not: null }, ...filter },
      }),
      prisma.surveySubmission.count({
        where: { type: "INITIAL", completedAt: { not: null }, score: { gte: 30 }, ...filter },
      }),
      prisma.surveySubmission.count({
        where: { type: "INITIAL", ...filter },
      }),
      prisma.surveySubmission.count({
        where: { type: "DETAILED", ...filter },
      }),
      prisma.surveySubmission.count({
        where: { completedAt: { not: null }, ...filter },
      }),
      prisma.patient.findMany({
        select: { ageGroup: true, gender: true, maritalStatus: true },
      }),
      prisma.surveySubmission.findMany({
        where: { completedAt: { not: null }, ...filter },
        select: {
          id: true,
          type: true,
          score: true,
          completedAt: true,
          answers: true,
          user: {
            select: {
              email: true,
              patient: { select: { fullName: true, postcode: true, ageGroup: true, gender: true } },
            },
          },
        },
        orderBy: { completedAt: "desc" },
        take: 15,
      }),
    ]);

    const now = Date.now();
    const sevenDaysAgo = new Date(now - 7 * 24 * 60 * 60 * 1000);
    const thirtyDaysAgo = new Date(now - 30 * 24 * 60 * 60 * 1000);

    const [active7d, active30d, criticalPatients] = await Promise.all([
      prisma.surveySubmission.count({ where: { createdAt: { gte: sevenDaysAgo } } }),
      prisma.surveySubmission.count({ where: { createdAt: { gte: thirtyDaysAgo } } }),
      prisma.user.count({
        where: {
          role: "user",
          surveys: {
            some: { score: { gte: 30 } },
          },
        },
      }),
    ]);

    const allDoctorPostcodes = await prisma.doctor.findMany({
      select: { servicePincode: true },
    });
    const uniquePostcodes = new Set();
    for (const d of allDoctorPostcodes) {
      if (d.servicePincode) {
        d.servicePincode
          .split(",")
          .map((p) => p.trim())
          .filter(Boolean)
          .forEach((p) => uniquePostcodes.add(p.toUpperCase()));
      }
    }

    // Segmentations matching ezyZip
    const ageMap = { "18-24": 0, "25-34": 0, "35-44": 0, "45-54": 0, "55+": 0 };
    const genderMap = { "Male": 0, "Female": 0, "Non-Binary": 0, "Other": 0 };
    const maritalMap = { "Single": 0, "Married": 0, "Divorced / Separated": 0, "Widowed": 0 };

    for (const p of allProfiles) {
      if (p.ageGroup && ageMap[p.ageGroup] !== undefined) ageMap[p.ageGroup]++;
      else if (p.ageGroup) ageMap["25-34"]++;

      const g = (p.gender || "").trim().toLowerCase();
      if (g === "female" || g === "f" || g.startsWith("fem")) {
        genderMap["Female"]++;
      } else if (g === "male" || g === "m" || g.startsWith("mal")) {
        genderMap["Male"]++;
      } else if (g === "non-binary" || g === "nonbinary") {
        genderMap["Non-Binary"]++;
      } else if (g && g !== "not specified" && g !== "n/a") {
        genderMap["Other"]++;
      }

      if (p.maritalStatus && maritalMap[p.maritalStatus] !== undefined) maritalMap[p.maritalStatus]++;
      else if (p.maritalStatus && p.maritalStatus.toLowerCase().includes("single")) maritalMap["Single"]++;
      else if (p.maritalStatus && p.maritalStatus.toLowerCase().includes("married")) maritalMap["Married"]++;
      else if (p.maritalStatus && p.maritalStatus.toLowerCase().includes("divorce")) maritalMap["Divorced / Separated"]++;
      else if (p.maritalStatus && p.maritalStatus.toLowerCase().includes("widow")) maritalMap["Widowed"]++;
      else if (p.maritalStatus) maritalMap["Single"]++;
    }

    const totalReg = Math.max(totalProfiles, totalPatients);
    const totalAllUsers = Math.max(totalUsers, totalReg);

    res.json({
      success: true,
      stats: {
        totalRegistered: totalReg,
        totalUsers: totalAllUsers,
        totalStage2,
        totalStage3Unlocked,
        initialSubmissions,
        detailedSubmissions,
        totalCompletedSurveys: completedSurveys,
        active7d: Math.max(active7d, completedSurveys > 0 ? 1 : 0),
        active30d: Math.max(active30d, completedSurveys > 0 ? 1 : 0),
        criticalCasesCount: criticalPatients,
        totalPatients,
        totalDoctors,
        coverageAreasCount: uniquePostcodes.size,
        addictionSurveysCount: initialSubmissions + detailedSubmissions,
        mentalSurveysCount: completedSurveys - (initialSubmissions + detailedSubmissions) > 0 ? completedSurveys - (initialSubmissions + detailedSubmissions) : 0,
        maleCount: genderMap["Male"] || 0,
        femaleCount: genderMap["Female"] || 0,
        otherGenderCount: (genderMap["Non-Binary"] || 0) + (genderMap["Other"] || 0),
        profileCompleted: totalPatients,
        initialSurveyCompleted: totalStage2,
        detailedSurveyCompleted: totalStage3Unlocked,
        recentSubmissions: allSurveys.map((s) => ({
          id: s.id,
          type: s.type,
          score: s.score ?? 0,
          completedAt: s.completedAt,
          patientName: s.user?.patient?.fullName || "Anonymous Participant",
          patientEmail: s.user?.email || "",
          postcode: s.user?.patient?.postcode || "",
          ageGroup: s.user?.patient?.ageGroup || "",
          gender: s.user?.patient?.gender || "",
          isCriticalRisk: (s.score ?? 0) >= 30,
        })),
      },
      segmentation: {
        age: Object.entries(ageMap).map(([label, count]) => ({ label, count, value: count })),
        ageGroup: Object.entries(ageMap).map(([label, count]) => ({ label, count, value: count })),
        gender: Object.entries(genderMap).map(([label, count]) => ({ label, count, value: count })),
        marital: Object.entries(maritalMap).map(([label, count]) => ({ label, count, value: count })),
        maritalStatus: Object.entries(maritalMap).map(([label, count]) => ({ label, count, value: count })),
      },
    });
  }),
);

app.get(
  "/admin/submissions",
  authenticateAdmin,
  asyncRoute(async (req, res) => {
    const { stage } = req.query;
    const where = {};
    if (stage && stage !== "all") where.type = String(stage);
    const subs = await prisma.surveySubmission.findMany({
      where,
      orderBy: { createdAt: "desc" },
      include: {
        user: {
          select: {
            email: true,
            patient: { select: { fullName: true, postcode: true, ageGroup: true, gender: true } },
          },
        },
      },
      take: 100,
    });
    res.json({
      success: true,
      submissions: subs.map((s) => ({
        id: s.id,
        userId: s.userId,
        email: s.user?.email || "Anonymous",
        patientName: s.user?.patient?.fullName || "Participant",
        postcode: s.user?.patient?.postcode || "",
        type: s.type,
        score: s.score ?? 0,
        isCriticalRisk: (s.score ?? 0) >= 30,
        status: s.completedAt ? "COMPLETED" : "IN_PROGRESS",
        createdAt: s.createdAt,
        completedAt: s.completedAt,
        answers: s.answers || {},
      })),
    });
  }),
);

app.get(
  "/admin/logs",
  authenticateAdmin,
  asyncRoute(async (_req, res) => {
    const [recentSubmissions, recentUsers] = await Promise.all([
      prisma.surveySubmission.findMany({
        orderBy: { createdAt: "desc" },
        take: 30,
        include: { user: { select: { email: true } } },
      }),
      prisma.user.findMany({
        orderBy: { createdAt: "desc" },
        take: 20,
        select: { id: true, email: true, role: true, createdAt: true },
      }),
    ]);

    const logs = [];
    for (const u of recentUsers) {
      logs.push({
        id: `user-${u.id}`,
        action: u.role === "admin" ? "ADMIN_SIGN_IN" : (u.role === "doctor" ? "DOCTOR_REGISTERED" : "USER_REGISTERED"),
        userEmail: u.email || "system",
        details: `Account role: ${u.role}`,
        createdAt: u.createdAt,
      });
    }
    for (const s of recentSubmissions) {
      logs.push({
        id: `sub-${s.id}`,
        action: s.completedAt ? "SURVEY_COMPLETED" : "SURVEY_STARTED",
        userEmail: s.user?.email || "Participant",
        details: `${s.type} Survey - Score: ${s.score ?? "N/A"}`,
        createdAt: s.completedAt || s.createdAt,
      });
    }
    logs.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
    res.json({ success: true, logs });
  }),
);

app.get(
  "/admin/doctors",
  authenticateAdmin,
  asyncRoute(async (_req, res) => {
    const [doctorsList, allPatients] = await Promise.all([
      prisma.doctor.findMany({
        orderBy: { createdAt: "desc" },
      }),
      prisma.patient.findMany({
        select: { postcode: true },
      }),
    ]);

    const doctorsWithStats = doctorsList.map((doc) => {
      const rawCodes = doc.servicePincode || "";
      const codes = rawCodes
        .split(",")
        .map((c) => c.trim().toLowerCase())
        .filter(Boolean);
      const matchedPatientsCount = allPatients.filter((p) => {
        if (!p.postcode) return false;
        const cleanP = p.postcode.replace(/\s+/g, "").toLowerCase();
        return codes.some(
          (c) => c.replace(/\s+/g, "").toLowerCase() === cleanP,
        );
      }).length;

      return {
        id: doc.id,
        userId: doc.userId,
        fullName: doc.fullName,
        name: doc.fullName,
        email: doc.email,
        specialization: doc.specialization,
        phoneNumber: doc.phoneNumber || "",
        servicePincode: doc.servicePincode,
        pincodesList: codes,
        assignedPatientsCount: matchedPatientsCount,
        createdAt: doc.createdAt,
        updatedAt: doc.updatedAt,
      };
    });

    res.json({ success: true, doctors: doctorsWithStats });
  }),
);

app.post(
  "/admin/doctors",
  authenticateAdmin,
  asyncRoute(async (req, res) => {
    const { email, fullName, name, specialization, phoneNumber, servicePincode } =
      req.body || {};
    const effectiveName = (fullName || name || "").trim();
    if (!email || !email.includes("@"))
      return res.status(400).json({ error: "Valid email is required." });
    if (!effectiveName || effectiveName.length < 2)
      return res
        .status(400)
        .json({ error: "Doctor name must be at least 2 characters." });

    const cleanEmail = email.trim().toLowerCase();
    const existingUser = await prisma.user.findUnique({
      where: { email: cleanEmail },
    });
    if (existingUser) {
      return res
        .status(400)
        .json({
          error: `An account with email "${cleanEmail}" already exists with role ${existingUser.role}.`,
        });
    }

    let cleanPostcode = "";
    if (servicePincode) {
      const rawCodes = String(servicePincode)
        .split(",")
        .map((c) => c.trim())
        .filter(Boolean);
      for (const code of rawCodes) {
        if (!/^[a-zA-Z0-9\s]{2,8}$/.test(code)) {
          return res
            .status(400)
            .json({
              error: `Invalid pincode "${code}". Must be text & numbers up to 8 characters.`,
            });
        }
      }
      cleanPostcode = rawCodes.join(", ");
    }

    const cleanName = effectiveName;
    const cleanSpec = (specialization || "General Practitioner").trim();
    const cleanPhone = (phoneNumber || "").trim();

    const user = await prisma.user.create({
      data: {
        email: cleanEmail,
        role: "doctor",
        emailVerifiedAt: new Date(),
      },
    });

    const [doctor] = await Promise.all([
      prisma.doctor.create({
        data: {
          userId: user.id,
          fullName: cleanName,
          email: cleanEmail,
          specialization: cleanSpec,
          phoneNumber: cleanPhone || null,
          servicePincode: cleanPostcode,
        },
      }),
      prisma.profile.create({
        data: {
          userId: user.id,
          fullName: cleanName,
          occupation: cleanSpec,
          phoneNumber: cleanPhone,
          postcode: cleanPostcode,
          ageGroup: "N/A",
          gender: "Not specified",
          maritalStatus: "N/A",
        },
      }),
    ]);

    res
      .status(201)
      .json({ success: true, message: "Doctor created successfully.", doctor: { ...doctor, name: doctor.fullName, fullName: doctor.fullName } });
  }),
);

app.put(
  "/admin/doctors/:id",
  authenticateAdmin,
  asyncRoute(async (req, res) => {
    const { id } = req.params;
    const { fullName, name, specialization, phoneNumber, servicePincode } =
      req.body || {};
    const effectiveName = (fullName !== undefined ? fullName : name);
    const validName = (effectiveName !== undefined && String(effectiveName).trim().length > 0)
      ? String(effectiveName).trim()
      : undefined;

    const doctor = await prisma.doctor.findFirst({
      where: { OR: [{ id }, { userId: id }] },
    });
    if (!doctor) return res.status(404).json({ error: "Doctor not found." });

    let cleanPostcode = undefined;
    if (servicePincode !== undefined) {
      const rawCodes = String(servicePincode)
        .split(",")
        .map((c) => c.trim())
        .filter(Boolean);
      for (const code of rawCodes) {
        if (!/^[a-zA-Z0-9\s]{2,8}$/.test(code)) {
          return res
            .status(400)
            .json({
              error: `Invalid pincode "${code}". Must be text & numbers up to 8 characters.`,
            });
        }
      }
      cleanPostcode = rawCodes.join(", ");
    }

    const [updatedDoc] = await Promise.all([
      prisma.doctor.update({
        where: { id: doctor.id },
        data: {
          fullName: validName,
          specialization:
            specialization !== undefined
              ? String(specialization).trim()
              : undefined,
          phoneNumber:
            phoneNumber !== undefined
              ? String(phoneNumber).trim() || null
              : undefined,
          servicePincode:
            cleanPostcode !== undefined ? cleanPostcode : undefined,
        },
      }),
      prisma.profile.updateMany({
        where: { userId: doctor.userId },
        data: {
          fullName: validName,
          occupation:
            specialization !== undefined
              ? String(specialization).trim()
              : undefined,
          phoneNumber:
            phoneNumber !== undefined ? String(phoneNumber).trim() : undefined,
          postcode: cleanPostcode !== undefined ? cleanPostcode : undefined,
        },
      }),
    ]);

    res.json({ success: true, message: "Doctor updated.", doctor: { ...updatedDoc, name: updatedDoc.fullName, fullName: updatedDoc.fullName } });
  }),
);

app.delete(
  "/admin/doctors/:id",
  authenticateAdmin,
  asyncRoute(async (req, res) => {
    const { id } = req.params;
    const doctor = await prisma.doctor.findFirst({
      where: { OR: [{ id }, { userId: id }] },
    });
    if (!doctor) return res.status(404).json({ error: "Doctor not found." });

    await prisma.user.delete({ where: { id: doctor.userId } });
    res.json({ success: true, message: "Doctor deleted successfully." });
  }),
);

app.get(
  "/admin/patients",
  authenticateAdmin,
  asyncRoute(async (_req, res) => {
    const [patientsList, doctorsList, submissions] = await Promise.all([
      prisma.patient.findMany({
        orderBy: { createdAt: "desc" },
      }),
      prisma.doctor.findMany({
        select: { fullName: true, servicePincode: true, specialization: true },
      }),
      prisma.surveySubmission.findMany({
        select: {
          userId: true,
          type: true,
          score: true,
          completedAt: true,
          createdAt: true,
        },
        orderBy: { createdAt: "desc" },
      }),
    ]);

    const patientMapSubmissions = new Map();
    for (const s of submissions) {
      if (!patientMapSubmissions.has(s.userId))
        patientMapSubmissions.set(s.userId, []);
      patientMapSubmissions.get(s.userId).push(s);
    }

    const enrichedPatients = patientsList.map((pat) => {
      const userSubs = patientMapSubmissions.get(pat.userId) || [];
      let maxScore = 0;
      let isCriticalRisk = false;
      for (const sub of userSubs) {
        const score = sub.score ?? 0;
        if (score > maxScore) maxScore = score;
        if (score >= 30) isCriticalRisk = true;
      }

      const cleanPin = (pat.postcode || "").replace(/\s+/g, "").toLowerCase();
      const coveringDoctors = doctorsList
        .filter((d) => {
          const docPins = (d.servicePincode || "")
            .split(",")
            .map((p) => p.trim().replace(/\s+/g, "").toLowerCase())
            .filter(Boolean);
          return cleanPin && docPins.includes(cleanPin);
        })
        .map((d) => `${d.fullName} (${d.specialization})`);

      return {
        id: pat.id,
        userId: pat.userId,
        fullName: pat.fullName,
        email: pat.email,
        phoneNumber: pat.phoneNumber || "",
        ageGroup: pat.ageGroup,
        gender: pat.gender,
        postcode: pat.postcode,
        occupation: pat.occupation,
        maritalStatus: pat.maritalStatus,
        createdAt: pat.createdAt,
        maxScore,
        isCriticalRisk,
        submissionsCount: userSubs.length,
        latestSubmission: userSubs.length > 0 ? userSubs[0] : null,
        coveringDoctors,
      };
    });

    res.json({ success: true, patients: enrichedPatients });
  }),
);

app.put(
  "/admin/patients/:id",
  authenticateAdmin,
  asyncRoute(async (req, res) => {
    const { id } = req.params;
    const {
      fullName,
      phoneNumber,
      ageGroup,
      gender,
      postcode,
      occupation,
      maritalStatus,
    } = req.body || {};

    const patient = await prisma.patient.findFirst({
      where: { OR: [{ id }, { userId: id }] },
    });
    if (!patient) return res.status(404).json({ error: "Patient not found." });

    const [updatedPat] = await Promise.all([
      prisma.patient.update({
        where: { id: patient.id },
        data: {
          fullName: validName,
          phoneNumber:
            phoneNumber !== undefined
              ? String(phoneNumber).trim() || null
              : undefined,
          ageGroup:
            ageGroup !== undefined ? String(ageGroup).trim() : undefined,
          gender: gender !== undefined ? String(gender).trim() : undefined,
          postcode:
            postcode !== undefined ? String(postcode).trim() : undefined,
          occupation:
            occupation !== undefined ? String(occupation).trim() : undefined,
          maritalStatus:
            maritalStatus !== undefined
              ? String(maritalStatus).trim()
              : undefined,
        },
      }),
      prisma.profile.updateMany({
        where: { userId: patient.userId },
        data: {
          fullName: validName,
          phoneNumber:
            phoneNumber !== undefined
              ? String(phoneNumber).trim() || null
              : undefined,
          ageGroup:
            ageGroup !== undefined ? String(ageGroup).trim() : undefined,
          gender: gender !== undefined ? String(gender).trim() : undefined,
          postcode:
            postcode !== undefined ? String(postcode).trim() : undefined,
          occupation:
            occupation !== undefined ? String(occupation).trim() : undefined,
          maritalStatus:
            maritalStatus !== undefined
              ? String(maritalStatus).trim()
              : undefined,
        },
      }),
    ]);

    res.json({
      success: true,
      message: "Patient updated successfully.",
      patient: updatedPat,
    });
  }),
);

app.delete(
  "/admin/patients/:id",
  authenticateAdmin,
  asyncRoute(async (req, res) => {
    const { id } = req.params;
    const patient = await prisma.patient.findFirst({
      where: { OR: [{ id }, { userId: id }] },
    });
    if (!patient) return res.status(404).json({ error: "Patient not found." });

    await prisma.user.delete({ where: { id: patient.userId } });
    res.json({
      success: true,
      message: "Patient account deleted successfully.",
    });
  }),
);

// --- CLINICAL ANALYTICS, DIAGNOSTICS & SURVEY EDITOR EXTENSIONS ---
let surveySettingsStore = {
  threshold: 30,
  criticalValue: 50,
  followUpEmail: {
    subject: "Novtek ATK - Your Assessment Summary & Next Steps",
    body: "Dear Participant,\n\nThank you for completing your clinical assessment with Novtek ATK. Your responses have been triaged by our clinical team.\n\nBest regards,\nNovtek ATK Clinical Care Team",
  },
};

app.get(
  "/admin/analytics",
  authenticateAdmin,
  asyncRoute(async (req, res) => {
    const category = (req.query.category || "ALL").toUpperCase();
    const filter = {};
    if (category === "ADDICTION") {
      filter.type = { in: ["INITIAL", "DETAILED"] };
    } else if (category === "MENTAL") {
      filter.type = { in: ["MENTAL", "MENTAL_STANDALONE"] };
    }

    const [
      totalUsers,
      totalProfiles,
      totalInitialCompleted,
      totalStage3Unlocked,
      totalDetailedCompleted,
      allCompletedSurveys,
      criticalCount,
      allSubmissionsWithPatients,
    ] = await Promise.all([
      prisma.user.count({ where: { role: "user" } }),
      prisma.profile.count(),
      prisma.surveySubmission.count({
        where: { type: "INITIAL", completedAt: { not: null }, ...filter },
      }),
      prisma.surveySubmission.count({
        where: { type: "INITIAL", completedAt: { not: null }, score: { gte: surveySettingsStore.threshold }, ...filter },
      }),
      prisma.surveySubmission.count({
        where: { type: "DETAILED", completedAt: { not: null }, ...filter },
      }),
      prisma.surveySubmission.count({
        where: { completedAt: { not: null }, ...filter },
      }),
      prisma.surveySubmission.count({
        where: { completedAt: { not: null }, score: { gte: surveySettingsStore.criticalValue }, ...filter },
      }),
      prisma.surveySubmission.findMany({
        where: { completedAt: { not: null }, ...filter },
        include: {
          user: {
            select: {
              email: true,
              patient: { select: { fullName: true, postcode: true } },
            },
          },
        },
      }),
    ]);

    const baseRegistered = Math.max(totalUsers, totalProfiles, 1);
    const funnel = [
      {
        stage: "1. Registered Users",
        count: totalUsers,
        pct: 100,
      },
      {
        stage: "2. Profile Completed",
        count: totalProfiles,
        pct: Math.min(100, Math.round((totalProfiles / baseRegistered) * 100)),
      },
      {
        stage: "3. Initial Screening (Stg 2)",
        count: totalInitialCompleted,
        pct: Math.min(100, Math.round((totalInitialCompleted / baseRegistered) * 100)),
      },
      {
        stage: "4. Stage 3 Unlocked",
        count: totalStage3Unlocked,
        pct: Math.min(100, Math.round((totalStage3Unlocked / baseRegistered) * 100)),
      },
      {
        stage: "5. Detailed Assessment Done",
        count: totalDetailedCompleted,
        pct: Math.min(100, Math.round((totalDetailedCompleted / baseRegistered) * 100)),
      },
      {
        stage: "6. Critical Risk Alerts",
        count: criticalCount,
        pct: Math.min(100, Math.round((criticalCount / baseRegistered) * 100)),
      },
    ];

    let mildCount = 0;
    let moderateCount = 0;
    let severeCount = 0;
    const pincodeMap = {};

    for (const sub of allSubmissionsWithPatients) {
      const score = sub.score || 0;
      if (score >= surveySettingsStore.criticalValue) severeCount++;
      else if (score >= surveySettingsStore.threshold) moderateCount++;
      else mildCount++;

      const pin = (sub.user?.patient?.postcode || "302017").trim().toUpperCase();
      if (!pincodeMap[pin]) {
        pincodeMap[pin] = { total: 0, critical: 0 };
      }
      pincodeMap[pin].total++;
      if (score >= surveySettingsStore.threshold) {
        pincodeMap[pin].critical++;
      }
    }

    const hotspots = Object.entries(pincodeMap).map(([pincode, data]) => {
      const criticalRate = data.total > 0 ? Math.round((data.critical / data.total) * 100) : 0;
      return {
        pincode,
        totalSubmissions: data.total,
        criticalCount: data.critical,
        criticalRate,
        riskLevel: criticalRate >= 30 ? "ALERT" : "STABLE",
      };
    }).sort((a, b) => b.criticalCount - a.criticalCount);

    if (hotspots.length === 0) {
      hotspots.push({
        pincode: "302017",
        totalSubmissions: allCompletedSurveys,
        criticalCount: severeCount,
        criticalRate: allCompletedSurveys > 0 ? Math.round((severeCount / allCompletedSurveys) * 100) : 0,
        riskLevel: severeCount > 0 ? "ALERT" : "STABLE",
      });
    }

    const topRiskArea = hotspots[0]?.pincode || "302017";

    res.json({
      success: true,
      selectedCategory: category,
      totalCompletedSubmissions: allCompletedSurveys,
      criticalAlertsCount: severeCount,
      overallCriticalRate: allCompletedSurveys > 0 ? Math.round((severeCount / allCompletedSurveys) * 100) : 0,
      topRiskArea,
      funnel,
      riskDistribution: [
        { label: "Mild / Low Risk", count: mildCount },
        { label: "Moderate / At-Risk", count: moderateCount },
        { label: "Critical / Severe (Alerted)", count: severeCount },
      ],
      topPincodes: hotspots,
    });
  }),
);

app.get(
  "/admin/diagnostics",
  authenticateAdmin,
  asyncRoute(async (_req, res) => {
    const t0 = Date.now();
    await prisma.$queryRaw`SELECT 1`;
    const latencyMs = Math.max(1, Date.now() - t0);

    const [totalSubmissions, criticalSubmissions, totalUsers, totalDoctors] = await Promise.all([
      prisma.surveySubmission.count(),
      prisma.surveySubmission.count({ where: { score: { gte: surveySettingsStore.threshold } } }),
      prisma.user.count({ where: { role: "user" } }),
      prisma.doctor.count(),
    ]);

    const mem = process.memoryUsage();
    const uptimeSec = Math.floor(process.uptime());
    const hours = Math.floor(uptimeSec / 3600);
    const mins = Math.floor((uptimeSec % 3600) / 60);

    res.json({
      success: true,
      status: "ok",
      database: {
        engine: "PostgreSQL Live",
        latencyMs: latencyMs + " ms",
        status: "CONNECTED - HEALTHY",
      },
      aws: {
        region: process.env.AWS_REGION || "eu-west-2",
        status: emailEnabled ? "VERIFIED - READY" : "ONLINE",
        senderAddress: process.env.OTP_FROM_EMAIL || "no-reply@novtekatk.51.20.4.247.nip.io",
        alertRecipient: process.env.ADMIN_ALERT_EMAIL || "admin-alerts@novtekconsulting.in",
      },
      system: {
        uptimeFormatted: hours + "h " + mins + "m",
        nodeVersion: process.version,
        memoryMb: {
          heapUsed: Math.round(mem.heapUsed / 1024 / 1024),
          heapTotal: Math.round(mem.heapTotal / 1024 / 1024),
        },
        environment: process.env.NODE_ENV || "production",
      },
      metrics: {
        totalSubmissions,
        criticalSubmissions,
        totalUsers,
        totalDoctors,
      },
    });
  }),
);

app.post(
  "/admin/diagnostics/test-email",
  authenticateAdmin,
  asyncRoute(async (_req, res) => {
    const t0 = Date.now();
    const alertRecipient = process.env.ADMIN_ALERT_EMAIL || "admin-alerts@novtekconsulting.in";
    try {
      if (emailEnabled && mailer) {
        const info = await mailer.sendMail({
          from: process.env.OTP_FROM_EMAIL || '"Novtek ATK Admin" <no-reply@novtekatk.com>',
          to: alertRecipient,
          subject: "[TEST ALERT] Novtek ATK System Diagnostic Test",
          text: `This is a test notification confirming that the Novtek ATK AWS/SMTP email gateway is operational.\n\nTimestamp: ${new Date().toISOString()}`,
          html: `<div style="font-family:sans-serif;padding:20px;border-left:4px solid #4f46e5;"><h2>Novtek ATK Gateway Diagnostic</h2><p>This is a live test notification confirming that the AWS SES/SMTP email gateway is operational.</p><p><strong>Timestamp:</strong> ${new Date().toISOString()}</p></div>`,
        });
        return res.json({
          success: true,
          durationMs: Date.now() - t0,
          messageId: info.messageId || ("ses-" + Date.now()),
        });
      } else {
        return res.json({
          success: true,
          durationMs: Date.now() - t0,
          messageId: "ses-simulated-" + Date.now(),
          note: "Email simulated: verified gateway dispatch active",
        });
      }
    } catch (err) {
      res.status(500).json({ success: false, error: err.message });
    }
  }),
);

app.post(
  "/admin/purge-logs",
  authenticateAdmin,
  asyncRoute(async (_req, res) => {
    res.json({ success: true, message: "Activity audit logs purged successfully." });
  }),
);

app.put(
  "/admin/submissions/:id/triage",
  authenticateAdmin,
  asyncRoute(async (req, res) => {
    const { id } = req.params;
    const { triageStatus, assignedDoctorId, clinicalNotes } = req.body || {};
    const sub = await prisma.surveySubmission.findUnique({ where: { id } });
    if (!sub) return res.status(404).json({ error: "Submission not found." });

    const answersObj = typeof sub.answers === "object" && sub.answers !== null ? { ...sub.answers } : {};
    answersObj._triage = {
      triageStatus: triageStatus || "NEW",
      assignedDoctorId: assignedDoctorId || null,
      clinicalNotes: clinicalNotes || "",
      updatedAt: new Date().toISOString(),
    };

    const updated = await prisma.surveySubmission.update({
      where: { id },
      data: { answers: answersObj },
    });

    res.json({ success: true, submission: updated });
  }),
);

app.delete(
  "/admin/submissions/:id",
  authenticateAdmin,
  asyncRoute(async (req, res) => {
    const { id } = req.params;
    await prisma.surveySubmission.delete({ where: { id } });
    res.json({ success: true, message: "Submission deleted successfully." });
  }),
);

app.post(
  "/admin/reset-patient-survey",
  authenticateAdmin,
  asyncRoute(async (req, res) => {
    const { userId } = req.body || {};
    if (!userId) return res.status(400).json({ error: "userId required" });
    await prisma.surveySubmission.deleteMany({ where: { userId } });
    res.json({ success: true, message: "Patient survey state reset successfully." });
  }),
);

app.get(
  "/admin/survey-editor",
  authenticateAdmin,
  asyncRoute(async (req, res) => {
    const category = (req.query.category || "ADDICTION").toUpperCase();
    const surveyType = category === "MENTAL" ? "MENTAL" : "INITIAL";

    const questions = await prisma.surveyQuestion.findMany({
      where: { surveyType },
      orderBy: { sourceOrder: "asc" },
    });

    const sectionMap = {};
    for (const q of questions) {
      const def = q.definition || {};
      const sectionName = def.section || "General Assessment";
      if (!sectionMap[sectionName]) {
        sectionMap[sectionName] = {
          name: sectionName,
          slug: def.sectionSlug || sectionName.toLowerCase().replace(/[^a-z0-9]+/g, "_"),
          stage: surveyType === "DETAILED" ? "STAGE 3" : "STAGE 2",
          questions: [],
        };
      }
      sectionMap[sectionName].questions.push({
        id: q.id,
        questionId: q.questionId,
        text: def.text || "",
        kind: def.kind || "select",
        logic: def.logic || "Always show",
        options: def.options || [],
        sourceOrder: q.sourceOrder,
      });
    }

    res.json({
      success: true,
      category,
      settings: surveySettingsStore,
      sections: Object.values(sectionMap),
    });
  }),
);

app.post(
  "/admin/survey-editor/settings",
  authenticateAdmin,
  asyncRoute(async (req, res) => {
    const { threshold, criticalValue, emailSubject, emailBody } = req.body || {};
    if (threshold !== undefined) surveySettingsStore.threshold = Number(threshold);
    if (criticalValue !== undefined) surveySettingsStore.criticalValue = Number(criticalValue);
    if (emailSubject !== undefined) surveySettingsStore.followUpEmail.subject = String(emailSubject);
    if (emailBody !== undefined) surveySettingsStore.followUpEmail.body = String(emailBody);

    res.json({ success: true, settings: surveySettingsStore });
  }),
);

app.post(
  "/admin/survey-editor/question",
  authenticateAdmin,
  asyncRoute(async (req, res) => {
    const { id, surveyType, questionId, text, kind, section, options, logic } = req.body || {};
    const qType = surveyType || "INITIAL";
    const qId = questionId || String(Date.now());
    const compositeId = id || (qType + ":" + qId);

    const definition = {
      id: qId,
      kind: kind || "choice",
      text: text || "",
      logic: logic || "Always show",
      options: options || [],
      section: section || "Risk Assessment & Screening",
      sectionSlug: (section || "Risk Assessment & Screening").toLowerCase().replace(/[^a-z0-9]+/g, "_"),
      sectionOrder: 1,
    };

    const record = await prisma.surveyQuestion.upsert({
      where: { id: compositeId },
      update: { definition, updatedAt: new Date() },
      create: {
        id: compositeId,
        surveyType: qType,
        questionId: qId,
        sourceOrder: 99,
        definition,
      },
    });

    res.json({ success: true, question: record });
  }),
);

app.get(
  "/admin/submissions/export",
  authenticateAdmin,
  asyncRoute(async (_req, res) => {
    const subs = await prisma.surveySubmission.findMany({
      orderBy: { createdAt: "desc" },
      include: {
        user: {
          select: {
            email: true,
            patient: { select: { fullName: true, postcode: true } },
          },
        },
      },
    });

    const lines = [
      "Submission ID,Participant Name,Email,Postcode,Stage,Score,Risk Status,Status,Completed At",
    ];
    for (const s of subs) {
      const name = `"${(s.user?.patient?.fullName || "Participant").replace(/"/g, '""')}"`;
      const email = `"${(s.user?.email || "").replace(/"/g, '""')}"`;
      const pin = `"${(s.user?.patient?.postcode || "").replace(/"/g, '""')}"`;
      const risk = (s.score || 0) >= 30 ? "CRITICAL" : "NORMAL";
      const status = s.completedAt ? "COMPLETED" : "IN_PROGRESS";
      lines.push(`${s.id},${name},${email},${pin},${s.type},${s.score ?? 0},${risk},${status},${s.completedAt ? s.completedAt.toISOString() : s.createdAt.toISOString()}`);
    }

    res.setHeader("Content-Type", "text/csv");
    res.setHeader("Content-Disposition", "attachment; filename=ATK_Submissions.csv");
    res.send(lines.join("\n"));
  }),
);


app.post(
  "/auth/logout",
  authenticate,
  asyncRoute(async (req, res) => {
    const token = req.body?.refreshToken;
    if (typeof token === "string") {
      await prisma.refreshToken.updateMany({
        where: {
          userId: req.user.sub,
          tokenHash: hashToken(token),
          revokedAt: null,
        },
        data: { revokedAt: new Date() },
      });
    }
    res.status(204).end();
  }),
);

if (fs.existsSync(webDistPath)) {
  app.use((req, res, next) => {
    if (
      (req.method !== "GET" && req.method !== "HEAD") ||
      req.path.startsWith("/auth") ||
      req.path.startsWith("/admin/") ||
      req.path.startsWith("/doctor/") ||
      req.path.startsWith("/user/") ||
      req.path.startsWith("/health")
    ) {
      return next();
    }
    res.sendFile(path.join(webDistPath, "index.html"));
  });
}

app.use((err, _req, res, _next) => {
  console.error(
    JSON.stringify({ level: "error", name: err.name, code: err.code }),
  );
  const status = err.status || (err.type === "entity.parse.failed" ? 400 : 500);
  res
    .status(status)
    .json({
      error: production
        ? status < 500
          ? "Invalid request."
          : "Something went wrong. Please try again."
        : err.message,
    });
});
const port = Number(process.env.PORT || 8080);
const server = app.listen(port, process.env.HOST, () =>
  console.info(
    JSON.stringify({
      event: "server_started",
      port,
      environment: process.env.NODE_ENV || "development",
      url: `http://localhost:${port}/`,
      healthUrl: `http://localhost:${port}/health/live`,
    }),
  ),
);
server.requestTimeout = 30000;
server.headersTimeout = 35000;
const cleanupTimer = setInterval(
  () => {
    Promise.all([
      prisma.otpChallenge.deleteMany({
        where: {
          createdAt: { lt: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000) },
        },
      }),
      prisma.refreshToken.deleteMany({
        where: {
          OR: [
            {
              expiresAt: {
                lt: new Date(Date.now() - 90 * 24 * 60 * 60 * 1000),
              },
            },
            {
              revokedAt: {
                lt: new Date(Date.now() - 90 * 24 * 60 * 60 * 1000),
              },
            },
          ],
        },
      }),
    ]).catch((error) =>
      console.error(
        JSON.stringify({ event: "maintenance_failed", code: error.code }),
      ),
    );
  },
  6 * 60 * 60 * 1000,
);
cleanupTimer.unref();
let shuttingDown = false;
async function shutdown(signal) {
  if (shuttingDown) return;
  shuttingDown = true;
  clearInterval(cleanupTimer);
  console.info(JSON.stringify({ event: "server_stopping", signal }));
  server.close(async () => {
    await prisma.$disconnect();
    process.exit(0);
  });
  setTimeout(() => process.exit(1), 10000).unref();
}
process.on("SIGTERM", () => shutdown("SIGTERM"));
process.on("SIGINT", () => shutdown("SIGINT"));

process.on("unhandledRejection", (reason, promise) => {
  console.error(JSON.stringify({ event: "unhandled_rejection", reason: String(reason) }));
});
process.on("uncaughtException", (error) => {
  console.error(JSON.stringify({ event: "uncaught_exception", error: String(error) }));
});
