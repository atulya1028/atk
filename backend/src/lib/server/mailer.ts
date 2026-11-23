import nodemailer from 'nodemailer';
import { env } from '$env/dynamic/private';

const localhost = ['localhost', '127.0.0.1', '::1'].includes(env.SMTP_HOST);
const secure = env.SMTP_SECURE === 'true';

export const transporter = nodemailer.createTransport({
    host: env.SMTP_HOST,
    port: Number(env.SMTP_PORT),
    secure,
    requireTLS: !localhost && !secure,
    auth: env.SMTP_USER || env.SMTP_PASS
        ? { user: env.SMTP_USER, pass: env.SMTP_PASS }
        : undefined,
    connectionTimeout: 10000,
    greetingTimeout: 10000,
    socketTimeout: 15000
});

// Add error listener to the transporter to prevent process-crashing unhandled events
transporter.on('error', (err) => {
    console.error('SMTP_TRANSPORTER_ERROR:', err);
});

/**
 * Resolves the compliant sender email address.
 * For AWS SES, SMTP_FROM is required (e.g. '"Novtek ATK Support" <support@yourdomain.com>').
 * Falls back to SMTP_USER or default.
 */
export const getSenderAddress = () => {
    return env.SMTP_FROM || env.SMTP_USER || 'no-reply@novtek-atk.com';
};

/**
 * Verify transporter connection on startup.
 */
export const smtpReady = transporter.verify().then(
    () => {
        console.log('SMTP_CONNECTION_READY');
        return true;
    },
    (error) => {
        console.error('SMTP_CONNECTION_ERROR:', error);
        return false;
    }
);
