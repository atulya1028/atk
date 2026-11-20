import { json } from '@sveltejs/kit';
import { prisma } from '$lib/server/prisma';
import { transporter } from '$lib/server/mailer';
import { env } from '$env/dynamic/private';
import type { RequestHandler } from './$types';
import fs from 'fs';
import path from 'path';

function logMail(message: string) {
    const logDir = path.resolve('logs');
    if (!fs.existsSync(logDir)) fs.mkdirSync(logDir);
    const logFile = path.join(logDir, 'email.log');
    const timestamp = new Date().toISOString();
    fs.appendFileSync(logFile, `[${timestamp}] ${message}\n`);
}

export const POST: RequestHandler = async ({ request }) => {
    try {
        const body = await request.json();
        const email = typeof body.email === 'string' ? body.email.trim().toLowerCase() : '';
        const role = body.role || 'user';
        if (!email) return json({ error: 'Email required' }, { status: 400 });

        const otp = Math.floor(100000 + Math.random() * 900000).toString();

        const now = new Date();
        try {
            if (role === 'doctor') {
                await prisma.doctor.upsert({
                    where: { email },
                    update: {
                        otp,
                        otpCreatedAt: now
                    },
                    create: {
                        email,
                        otp,
                        name: email.split('@')[0],
                        otpCreatedAt: now
                    }
                });
            } else {
                await prisma.user.upsert({
                    where: { email },
                    update: {
                        otp,
                        otpCreatedAt: now
                    },
                    create: {
                        email,
                        otp,
                        name: email.split('@')[0],
                        otpCreatedAt: now
                    }
                });
            }
        } catch (dbError: any) {
            logMail(`DATABASE_ERROR: Failed to upsert ${role} ${email}. Error: ${dbError.message}`);
            console.error("DATABASE_ERROR_DETAILS:", dbError);
            return json({ error: 'Database synchronization issue. Please run migrations.' }, { status: 500 });
        }

        try {
            const senderAddress = env.SMTP_FROM || env.SMTP_USER || 'no-reply@novtek-atk.com';
            const info = await transporter.sendMail({
                from: senderAddress,
                to: email,
                subject: 'Your Login OTP',
                text: `Your OTP is: ${otp}. This OTP is valid for 5 minutes.`,
                html: `<div style="font-family: sans-serif; padding: 20px; border: 1px solid #eee; border-radius: 10px; max-width: 400px; margin: 0 auto;">
                        <h2 style="color: #4f46e5; text-align: center;">Novtek ATK</h2>
                        <p>Hello! Use the following code to sign in to your account:</p>
                        <div style="font-size: 32px; font-weight: bold; text-align: center; padding: 20px; background: #f8fafc; border-radius: 8px; margin: 20px 0; letter-spacing: 5px; color: #1e293b;">
                            ${otp}
                        </div>
                        <p style="text-align: center; font-weight: bold; color: #e11d48; margin: 15px 0;">This OTP is valid for 5 minutes.</p>
                        <p style="font-size: 12px; color: #64748b; text-align: center;">If you didn't request this, you can safely ignore this email.</p>
                      </div>`
            });

            // Log for debugging
            logMail(`SUCCESS: Sent OTP ${otp} to ${email}. MessageId: ${info.messageId}`);
            console.log(`[MAILER] OTP for ${email}: ${otp}`);
            console.log(`Email successfully sent to ${email}: ${info.messageId}`);

            return json({
                success: true,
                message: 'OTP sent successfully',
                debug_otp: otp
            });
        } catch (e: any) {
            const errDetails = {
                host: process.env.SMTP_HOST,
                port: process.env.SMTP_PORT,
                user: process.env.SMTP_USER,
                error: e.message,
                code: e.code,
                command: e.command
            };
            logMail(`ERROR: Failed to send to ${email}. Details: ${JSON.stringify(errDetails)}`);
            console.error("SMTP_ERROR_DETAILS:", errDetails);

            // Fallback for development/testing when SMTP is offline or misconfigured
            console.log(`[FALLBACK MAILER] OTP for ${email}: ${otp}`);
            return json({
                success: true,
                message: 'OTP sent (SMTP offline fallback)',
                debug_otp: otp,
                otp: otp
            });
        }

        return json({ success: true, message: 'OTP sent successfully' });
    } catch (e) {
        console.error(e);
        return json({ error: 'Internal Server Error' }, { status: 500 });
    }
}
