import "dotenv/config";
import nodemailer from "nodemailer";

const required = ["DATABASE_URL", "JWT_SECRET"];
for (const key of required) {
  if (!process.env[key]) throw new Error(`${key} is required`);
}
if (process.env.JWT_SECRET.length < 32) {
  throw new Error("JWT_SECRET must be at least 32 characters");
}

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
) {
  throw new Error(
    "Configure all SMTP email credentials or leave them all blank",
  );
}

export const emailEnabled = configuredMailKeys.length === mailConfig.length;
export const production = process.env.NODE_ENV === "production";

if (production) {
  if (!emailEnabled) {
    throw new Error("SMTP email credentials are required in production");
  }
  if (
    !(process.env.APP_ORIGINS || "")
      .split(",")
      .map((value) => value.trim())
      .filter(Boolean).length
  ) {
    throw new Error("Set APP_ORIGINS explicitly in production");
  }
}

const origins = (process.env.APP_ORIGINS || "")
  .split(",")
  .map((x) => x.trim())
  .filter(Boolean);

export const isAllowedOrigin = (origin) => {
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
    ) {
      return true;
    }
  } catch {}
  return false;
};

export const mailer = emailEnabled
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
