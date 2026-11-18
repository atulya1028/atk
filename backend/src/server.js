import 'dotenv/config';
import crypto from 'node:crypto';
import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';
import jwt from 'jsonwebtoken';
import nodemailer from 'nodemailer';
import { z } from 'zod';
import { prisma } from './db.js';
import { isInitialQuestion, restoreInitialAnswers } from './survey_question_bank.js';

const required = ['DATABASE_URL', 'JWT_SECRET'];
for (const key of required) if (!process.env[key]) throw new Error(`${key} is required`);
if (process.env.JWT_SECRET.length < 32) throw new Error('JWT_SECRET must be at least 32 characters');
const mailConfig = ['SMTP_HOST', 'SMTP_USER', 'SMTP_PASSWORD', 'OTP_FROM_EMAIL'];
const configuredMailKeys = mailConfig.filter(key => process.env[key]);
if (configuredMailKeys.length > 0 && configuredMailKeys.length !== mailConfig.length) throw new Error('Configure all SMTP email credentials or leave them all blank');
const emailEnabled = configuredMailKeys.length === mailConfig.length;
if (process.env.NODE_ENV === 'production') {
  if (!emailEnabled) throw new Error('SMTP email credentials are required in production');
  if (!(process.env.APP_ORIGINS || '').split(',').map(value => value.trim()).filter(Boolean).length) throw new Error('Set APP_ORIGINS explicitly in production');
}

const app = express();
const production = process.env.NODE_ENV === 'production';
const origins = (process.env.APP_ORIGINS || '').split(',').map(x => x.trim()).filter(Boolean);
const isLocalDevelopmentOrigin = origin => {
  if (production) return false;
  try {
    const url = new URL(origin);
    return url.protocol === 'http:' && ['localhost', '127.0.0.1'].includes(url.hostname);
  } catch {
    return false;
  }
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

app.disable('x-powered-by');
if (process.env.TRUST_PROXY === '1') app.set('trust proxy', 1);
app.use(helmet());
app.use(cors({ origin(origin, cb) { if (!origin || !origins.length || origins.includes(origin) || isLocalDevelopmentOrigin(origin)) return cb(null, true); cb(new Error('Origin not allowed')); } }));
app.use(express.json({ limit: '16kb' }));
app.use('/auth', rateLimit({ windowMs: 15 * 60 * 1000, limit: 20, standardHeaders: 'draft-8', legacyHeaders: false }));

app.get('/', (_req, res) => res.type('text/plain').send('ATK API is running.'));
app.get('/health/live', (_req, res) => res.json({ status: 'ok' }));

const emailSchema = z.string().trim().toLowerCase().pipe(z.string().email().max(254));
const sendSchema = z.object({ email: emailSchema, role: z.enum(['user', 'doctor']).default('user') });
const verifySchema = sendSchema.extend({ otp: z.string().trim().regex(/^\d{4,10}$/) });
const profileSchema = z.object({
  fullName: z.string().trim().min(2).max(100), ageGroup: z.string().trim().min(1).max(30),
  phoneNumber: z.string().trim().max(20).optional().nullable(), postcode: z.string().regex(/^\d{6}$/),
  gender: z.string().trim().min(1).max(40), occupation: z.string().trim().min(1).max(100),
  maritalStatus: z.string().trim().min(1).max(40),
});
const hashToken = token => crypto.createHash('sha256').update(token).digest('hex');
const asyncRoute = fn => (req, res, next) => Promise.resolve(fn(req, res, next)).catch(next);

app.get('/health/ready', asyncRoute(async (_req, res) => {
  await prisma.$queryRaw`SELECT 1`;
  res.json({ status: 'ready' });
}));

app.post('/auth/send-otp', asyncRoute(async (req, res) => {
  const parsed = sendSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: 'Enter a valid email address.' });
  if (!mailer) return res.status(503).json({ error: 'Email sign-in is not configured yet. Add the SMTP settings to backend/.env.' });
  const { email, role } = parsed.data;
  const code = String(crypto.randomInt(0, 1000000)).padStart(6, '0');
  const codeHash = crypto.createHmac('sha256', process.env.JWT_SECRET).update(`${email}:${role}:${code}`).digest('hex');
  const outcome = await prisma.$transaction(async tx => {
    await tx.$queryRaw`WITH lock AS MATERIALIZED (SELECT pg_advisory_xact_lock(hashtext(${email}))) SELECT 1::int AS locked FROM lock`;
    const sinceHour = new Date(Date.now() - 60 * 60 * 1000);
    const sinceMinute = new Date(Date.now() - 60 * 1000);
    const [hourly, recent] = await Promise.all([
      tx.otpChallenge.count({ where: { email, role, createdAt: { gt: sinceHour } } }),
      tx.otpChallenge.count({ where: { email, role, createdAt: { gt: sinceMinute } } }),
    ]);
    if (hourly >= 5 || recent > 0) return { limited: hourly >= 5 ? 'hour' : 'minute' };
    await tx.otpChallenge.updateMany({ where: { email, role, consumedAt: null }, data: { consumedAt: new Date() } });
    await tx.otpChallenge.create({ data: { email, role, codeHash, expiresAt: new Date(Date.now() + 10 * 60 * 1000) } });
    return { sent: true };
  });
  if (outcome.limited) {
    const message = outcome.limited === 'hour' ? 'Too many code requests. Please try again later.' : 'Please wait a minute before requesting another code.';
    return res.status(429).json({ error: message });
  }
  try {
    await mailer.sendMail({ from: process.env.OTP_FROM_EMAIL, to: email, subject: 'Your ATK sign-in code', text: `Your ATK verification code is ${code}. It expires in 10 minutes. If you did not request this code, you can ignore this email.`, html: `<div style="font-family:Arial,sans-serif;max-width:480px;margin:auto;padding:24px;color:#12302f"><h1>Sign in to ATK</h1><p>Your verification code is:</p><p style="font-size:32px;font-weight:bold;letter-spacing:8px">${code}</p><p>This code expires in 10 minutes. If you did not request it, ignore this email.</p></div>` });
  } catch (error) {
    const smtpResponse = String(error.response || '')
      .replace(/[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}/gi, '[email]')
      .replace(/[\r\n]+/g, ' ')
      .slice(0, 240);
    console.error(JSON.stringify({ event: 'email_send_failed', code: error.code, responseCode: error.responseCode, command: error.command, response: smtpResponse || undefined }));
    await prisma.otpChallenge.updateMany({ where: { email, role, codeHash, consumedAt: null }, data: { consumedAt: new Date() } });
    return res.status(502).json({ error: 'Could not send an email code right now. Check the address and try again later.' });
  }
  console.info(JSON.stringify({ event: 'email_send_succeeded' }));
  res.status(200).json({ message: 'A sign-in code was sent by email.' });
}));

app.post('/auth/verify-otp', asyncRoute(async (req, res) => {
  const parsed = verifySchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: 'Enter a valid email address and verification code.' });
  if (!mailer) return res.status(503).json({ error: 'Email sign-in is not configured yet. Add the SMTP settings to backend/.env.' });
  const { email, role, otp } = parsed.data;
  const refreshToken = crypto.randomBytes(48).toString('base64url');
  const outcome = await prisma.$transaction(async tx => {
    await tx.$queryRaw`WITH lock AS MATERIALIZED (SELECT pg_advisory_xact_lock(hashtext(${email}))) SELECT 1::int AS locked FROM lock`;
    const challenge = await tx.otpChallenge.findFirst({
      where: { email, role, consumedAt: null, expiresAt: { gt: new Date() } },
      orderBy: { createdAt: 'desc' },
    });
    if (!challenge || challenge.attempts >= 5) return { error: 'invalid_code' };
    const expected = crypto.createHmac('sha256', process.env.JWT_SECRET).update(`${email}:${role}:${otp}`).digest('hex');
    const actual = Buffer.from(challenge.codeHash, 'hex');
    const supplied = Buffer.from(expected, 'hex');
    if (actual.length !== supplied.length || !crypto.timingSafeEqual(actual, supplied)) {
      await tx.otpChallenge.update({ where: { id: challenge.id }, data: { attempts: { increment: 1 } } });
      return { error: 'invalid_code' };
    }
    const existing = await tx.user.findUnique({ where: { email } });
    if (existing && existing.role !== role) return { error: 'wrong_role' };
    await tx.otpChallenge.update({ where: { id: challenge.id }, data: { consumedAt: new Date() } });
    const user = existing
      ? await tx.user.update({ where: { id: existing.id }, data: { emailVerifiedAt: existing.emailVerifiedAt ?? new Date() } })
      : await tx.user.create({ data: { email, role, emailVerifiedAt: new Date() } });
    const accessToken = jwt.sign({ sub: user.id, role: user.role }, process.env.JWT_SECRET, { expiresIn: '1h', issuer: 'atk-api', audience: 'atk-app' });
    await tx.refreshToken.create({ data: { userId: user.id, tokenHash: hashToken(refreshToken), expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000) } });
    const profile = await tx.profile.findUnique({ where: { userId: user.id }, select: { userId: true } });
    return { accessToken, user: { id: user.id, email: user.email, role: user.role }, isProfileComplete: Boolean(profile) };
  });
  if (outcome.error === 'wrong_role') return res.status(403).json({ error: 'This email is registered with a different account type.' });
  if (outcome.error) return res.status(400).json({ error: 'That code is invalid or expired. Request a new email code and try again.' });
  res.json({ ...outcome, refreshToken });
}));

app.post('/auth/refresh', asyncRoute(async (req, res) => {
  const oldToken = req.body?.refreshToken;
  if (typeof oldToken !== 'string' || oldToken.length < 32) return res.status(400).json({ error: 'Please sign in again.' });
  const oldTokenHash = hashToken(oldToken);
  const refreshToken = crypto.randomBytes(48).toString('base64url');
  const outcome = await prisma.$transaction(async tx => {
    await tx.$queryRaw`WITH lock AS MATERIALIZED (SELECT pg_advisory_xact_lock(hashtext(${oldTokenHash}))) SELECT 1::int AS locked FROM lock`;
    const session = await tx.refreshToken.findUnique({ where: { tokenHash: oldTokenHash }, include: { user: { select: { role: true } } } });
    if (!session || session.revokedAt || session.expiresAt <= new Date()) return { error: true };
    await tx.refreshToken.update({ where: { id: session.id }, data: { revokedAt: new Date() } });
    await tx.refreshToken.create({ data: { userId: session.userId, tokenHash: hashToken(refreshToken), expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000) } });
    const accessToken = jwt.sign({ sub: session.userId, role: session.user.role }, process.env.JWT_SECRET, { expiresIn: '1h', issuer: 'atk-api', audience: 'atk-app' });
    return { accessToken };
  });
  if (outcome.error) return res.status(401).json({ error: 'Your session has expired. Please sign in again.' });
  res.json({ ...outcome, refreshToken });
}));

async function authenticate(req, res, next) {
  const token = req.headers.authorization?.match(/^Bearer (.+)$/)?.[1];
  if (!token) return res.status(401).json({ error: 'Sign in to continue.' });
  try { req.user = jwt.verify(token, process.env.JWT_SECRET, { issuer: 'atk-api', audience: 'atk-app' }); next(); }
  catch { res.status(401).json({ error: 'Your session has expired. Please sign in again.' }); }
}

app.get('/user/profile', authenticate, asyncRoute(async (req, res) => {
  const account = await prisma.user.findUnique({
    where: { id: req.user.sub },
    select: {
      email: true,
      profile: { select: { fullName: true, ageGroup: true, phoneNumber: true, postcode: true, gender: true, occupation: true, maritalStatus: true } },
    },
  });
  res.json({ email: account?.email ?? null, profile: account?.profile ?? null });
}));

app.put('/user/profile', authenticate, asyncRoute(async (req, res) => {
  const parsed = profileSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: 'Please check the profile details and try again.' });
  const p = parsed.data;
  await prisma.profile.upsert({
    where: { userId: req.user.sub },
    create: { userId: req.user.sub, fullName: p.fullName, ageGroup: p.ageGroup, phoneNumber: p.phoneNumber || null, postcode: p.postcode, gender: p.gender, occupation: p.occupation, maritalStatus: p.maritalStatus },
    update: { fullName: p.fullName, ageGroup: p.ageGroup, phoneNumber: p.phoneNumber || null, postcode: p.postcode, gender: p.gender, occupation: p.occupation, maritalStatus: p.maritalStatus },
  });
  res.json({ message: 'Profile saved.' });
}));

const surveyTypes = ['INITIAL', 'DETAILED', 'MENTAL', 'MENTAL_STANDALONE'];
const mentalSurveyTypes = ['MENTAL', 'MENTAL_STANDALONE'];
const detailedSurveyQuestions = [
  'How often do you use more than you planned to?',
  'How often have you tried to cut down without success?',
  'How often does it affect your work or studies?',
  'How often does it cause problems with family or friends?',
  'How often do you feel unable to stop even when you want to?',
].map((text, id) => ({ id, text, options: ['Never', 'Sometimes', 'Often', 'Almost always'].map((label, index) => ({ label, score: index * 5 })) }));
const questionsForType = async type => {
  if (type === 'DETAILED') return detailedSurveyQuestions;
  const rows = await prisma.surveyQuestion.findMany({
    where: { surveyType: type === 'MENTAL_STANDALONE' ? 'MENTAL' : type },
    orderBy: [{ sourceOrder: 'asc' }, { questionId: 'asc' }],
  });
  const questionIds = new Set();
  const prompts = new Set();
  return rows.map(row => row.definition).filter(question => {
    if (type === 'INITIAL' && !isInitialQuestion(question.id, question.sectionSlug)) return false;
    const id = String(question.id);
    const prompt = question.text.normalize('NFKC').toLowerCase()
      .replace(/[^\p{L}\p{N}]+/gu, ' ').trim();
    if (questionIds.has(id) || prompts.has(prompt)) return false;
    questionIds.add(id);
    prompts.add(prompt);
    return true;
  });
};
const publicSurveyQuestions = questions => questions.map(question => ({
  id: question.id,
  text: question.text,
  kind: question.kind ?? 'choice',
  options: question.options.map(({ label }) => ({ label })),
  ...(question.min == null ? {} : { min: question.min }),
  ...(question.max == null ? {} : { max: question.max }),
  ...(question.section == null ? {} : { section: question.section }),
  ...(question.sectionSlug == null ? {} : { sectionSlug: question.sectionSlug }),
  ...(question.sectionOrder == null ? {} : { sectionOrder: question.sectionOrder }),
  ...(question.logic == null ? {} : { logic: question.logic }),
}));
const isAnswerValid = (question, value) => {
  if (!Number.isInteger(value)) return false;
  if (question.kind === 'number') return value >= question.min && value <= question.max;
  return value >= 0 && value < question.options.length;
};
const surveyTypeSchema = z.object({ type: z.enum(surveyTypes) });
const surveyAnswersSchema = z.object({ answers: z.record(z.string(), z.number().int()) });
const surveyScore = (type, answers, questions) => {
  if (type === 'MENTAL' || type === 'MENTAL_STANDALONE') return null;
  if (type === 'INITIAL') {
    return questions.reduce((score, question) => {
      const selected = question.options[answers[question.id]];
      return score + (question.concern && selected?.label === question.concern ? 5 : 0);
    }, 0);
  }
  return questions.reduce((score, question) => score + question.options[answers[question.id]].score, 0);
};

app.get('/v1/surveys/status', authenticate, asyncRoute(async (req, res) => {
  const rows = await prisma.surveySubmission.findMany({ where: { userId: req.user.sub }, orderBy: [{ updatedAt: 'desc' }, { id: 'desc' }] });
  const latest = type => rows.find(row => row.type === type);
  const initial = latest('INITIAL');
  const detailed = latest('DETAILED');
  const mental = rows.find(row => mentalSurveyTypes.includes(row.type));
  const completedInitial = rows.filter(row => row.type === 'INITIAL' && row.completedAt)
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
    if (row.answers && typeof row.answers === 'object' && !Array.isArray(row.answers)) {
      totalAnswers += Object.keys(row.answers).length;
    }
  }
  const unlockScore = 30;
  res.json({
    unlockScore,
    stats: { completedSurveys, totalAnswers, surveyDays: surveyDays.size },
    initial: initial ? { id: initial.id, status: initial.completedAt ? 'COMPLETED' : 'IN_PROGRESS', hasCompleted: Boolean(completedInitial), score: initial.score, answers: initial.answers } : null,
    mental: mental ? { id: mental.id, status: mental.completedAt ? 'COMPLETED' : 'IN_PROGRESS', answers: mental.answers } : null,
    standaloneMentalStatus: mental ? (mental.completedAt ? 'COMPLETED' : 'IN_PROGRESS') : null,
    detailed: { unlocked: Boolean(completedInitial && (completedInitial.score ?? 0) >= unlockScore), latest: detailed ? { id: detailed.id, status: detailed.completedAt ? 'COMPLETED' : 'IN_PROGRESS', score: detailed.score, answers: detailed.answers } : null },
  });
}));

app.post('/v1/surveys/start', authenticate, asyncRoute(async (req, res) => {
  const parsed = surveyTypeSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: 'Choose a valid survey.' });
  if (parsed.data.type === 'DETAILED') {
    const initial = await prisma.surveySubmission.findFirst({ where: { userId: req.user.sub, type: 'INITIAL', completedAt: { not: null } }, orderBy: { completedAt: 'desc' } });
    if (!initial || (initial.score ?? 0) < 30) return res.status(403).json({ error: 'Complete the initial assessment with a score of 30 or more to unlock this survey.' });
  }
  if (parsed.data.type === 'MENTAL') {
    const initial = await prisma.surveySubmission.findFirst({ where: { userId: req.user.sub, type: 'INITIAL', completedAt: { not: null } }, orderBy: { completedAt: 'desc' } });
    if (!initial) return res.status(403).json({ error: 'Complete the initial assessment before starting the mental health assessment.' });
  }
  const questions = await questionsForType(parsed.data.type);
  if (!questions.length) return res.status(503).json({ error: 'Survey questions have not been synced to the database.' });
  const type = parsed.data.type;
  const relatedTypes = mentalSurveyTypes.includes(type) ? mentalSurveyTypes : [type];
  const submission = await prisma.$transaction(async tx => {
    const lockKey = `survey:${req.user.sub}:${relatedTypes[0]}`;
    await tx.$queryRaw`WITH lock AS MATERIALIZED (SELECT pg_advisory_xact_lock(hashtext(${lockKey}))) SELECT 1::int AS locked FROM lock`;
    const latest = await tx.surveySubmission.findFirst({
      where: { userId: req.user.sub, type: { in: relatedTypes } },
      orderBy: [{ updatedAt: 'desc' }, { id: 'desc' }],
    });
    if (latest && !latest.completedAt) return latest;
    return tx.surveySubmission.create({ data: { userId: req.user.sub, type } });
  });
  const saved = type === 'INITIAL' ? restoreInitialAnswers(submission.answers) : submission.answers;
  const answers = Object.fromEntries(questions
    .filter(question => isAnswerValid(question, saved[question.id]))
    .map(question => [question.id, saved[question.id]]));
  res.json({ id: submission.id, type: submission.type, answers, questions: publicSurveyQuestions(questions) });
}));

app.put('/v1/surveys/:id/answers', authenticate, asyncRoute(async (req, res) => {
  const parsed = surveyAnswersSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: 'Check your survey answers and try again.' });
  const submission = await prisma.surveySubmission.findFirst({
    where: { id: req.params.id, userId: req.user.sub, completedAt: null },
    select: { type: true },
  });
  if (!submission) return res.status(404).json({ error: 'This survey draft was not found.' });
  const questions = await questionsForType(submission.type);
  if (Object.entries(parsed.data.answers).some(([id, value]) => {
    const question = questions.find(item => String(item.id) === id);
    return !question || !isAnswerValid(question, value);
  })) return res.status(400).json({ error: 'Check your survey answers and try again.' });
  const result = await prisma.surveySubmission.updateMany({ where: { id: req.params.id, userId: req.user.sub, completedAt: null }, data: { answers: parsed.data.answers } });
  if (!result.count) return res.status(404).json({ error: 'This survey draft was not found.' });
  res.json({ message: 'Answers saved.' });
}));

app.post('/v1/surveys/:id/complete', authenticate, asyncRoute(async (req, res) => {
  const submission = await prisma.surveySubmission.findFirst({ where: { id: req.params.id, userId: req.user.sub } });
  if (!submission) return res.status(404).json({ error: 'This survey draft was not found.' });
  if (submission.completedAt) return res.json({ score: submission.score, unlockScore: 30 });
  const answers = submission.type === 'INITIAL' ? restoreInitialAnswers(submission.answers) : submission.answers;
  const questions = await questionsForType(submission.type);
  if (!questions.length || questions.some(question => !isAnswerValid(question, answers[question.id]))) return res.status(400).json({ error: 'Answer every question before finishing.' });
  const score = surveyScore(submission.type, answers, questions);
  await prisma.surveySubmission.update({ where: { id: submission.id }, data: { score, completedAt: new Date() } });
  res.json({ score, unlockScore: 30 });
}));

const wellbeingResponses = {
  emotional_wellbeing: z.strictObject({
    feeling: z.enum(['Happy', 'Calm', 'Sad', 'Worried', 'Confused', 'Overwhelmed']),
    duration: z.enum(['Just today', 'A few days', 'A few weeks', 'Several months', 'A long time']),
  }),
  anxiety_worry: z.strictObject({
    feeling: z.enum(['Calm', 'A little worried', 'Anxious', 'Very anxious', 'Restless', 'Overwhelmed']),
    frequency: z.enum(['Rarely', 'Sometimes', 'Often', 'Almost every day', 'Throughout the day']),
  }),
  stress_management: z.strictObject({
    stressLevel: z.enum(['Not stressed', 'A little stressed', 'Moderately stressed', 'Very stressed', 'Extremely stressed']),
    copingMethod: z.enum(['Talking to someone', 'Taking a break', 'Exercise or walking', 'Listening to music', 'Meditation or breathing', 'I am not sure']),
  }),
  sleep_relaxation: z.strictObject({
    sleepQuality: z.enum(['Very good', 'Good', 'Average', 'Poor', 'Very poor']),
    morningFeeling: z.enum(['I wake up feeling refreshed', 'I sometimes feel rested', 'I often feel tired', 'I feel tired most of the day', 'I rarely feel refreshed']),
  }),
};

app.put('/v1/wellbeing/:topic', authenticate, asyncRoute(async (req, res) => {
  const { topic } = req.params;
  if (!Object.hasOwn(wellbeingResponses, topic)) {
    return res.status(404).json({ error: 'Check-in topic not found.' });
  }
  const parsed = wellbeingResponses[topic].safeParse(req.body?.responses);
  if (!parsed.success) {
    return res.status(400).json({ error: 'Choose a response for each question.' });
  }
  const userId = req.user.sub;
  const responses = parsed.data;
  await prisma.wellbeingCheckIn.upsert({
    where: { userId_topic: { userId, topic } },
    create: { userId, topic, responses },
    update: { responses },
  });
  res.status(204).end();
}));

app.post('/auth/logout', authenticate, asyncRoute(async (req, res) => {
  const token = req.body?.refreshToken;
  if (typeof token === 'string') {
    await prisma.refreshToken.updateMany({
      where: { userId: req.user.sub, tokenHash: hashToken(token), revokedAt: null },
      data: { revokedAt: new Date() },
    });
  }
  res.status(204).end();
}));

app.use((err, _req, res, _next) => {
  console.error(JSON.stringify({ level: 'error', name: err.name, code: err.code }));
  const status = err.status || (err.type === 'entity.parse.failed' ? 400 : 500);
  res.status(status).json({ error: production ? (status < 500 ? 'Invalid request.' : 'Something went wrong. Please try again.') : err.message });
});
const port = Number(process.env.PORT || 8080);
const server = app.listen(port, () => console.info(JSON.stringify({
  event: 'server_started',
  port,
  environment: process.env.NODE_ENV || 'development',
  url: `http://localhost:${port}/`,
  healthUrl: `http://localhost:${port}/health/live`,
})));
server.requestTimeout = 30000;
server.headersTimeout = 35000;
const cleanupTimer = setInterval(() => {
  Promise.all([
    prisma.otpChallenge.deleteMany({ where: { createdAt: { lt: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000) } } }),
    prisma.refreshToken.deleteMany({ where: { OR: [
      { expiresAt: { lt: new Date(Date.now() - 90 * 24 * 60 * 60 * 1000) } },
      { revokedAt: { lt: new Date(Date.now() - 90 * 24 * 60 * 60 * 1000) } },
    ] } }),
  ]).catch(error => console.error(JSON.stringify({ event: 'maintenance_failed', code: error.code })));
}, 6 * 60 * 60 * 1000);
cleanupTimer.unref();
let shuttingDown = false;
async function shutdown(signal) {
  if (shuttingDown) return;
  shuttingDown = true;
  clearInterval(cleanupTimer);
  console.info(JSON.stringify({ event: 'server_stopping', signal }));
  server.close(async () => { await prisma.$disconnect(); process.exit(0); });
  setTimeout(() => process.exit(1), 10000).unref();
}
process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));
