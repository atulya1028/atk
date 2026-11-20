import { createHash, randomInt } from 'node:crypto';
import fs from 'node:fs';
import path from 'node:path';
import { env } from '$env/dynamic/private';
import { json } from '@sveltejs/kit';
import jwt from 'jsonwebtoken';
import { transporter } from '$lib/server/mailer';
import { prisma } from '$lib/server/prisma';
import type { RequestHandler } from './$types';

const SECRET = process.env.JWT_SECRET || 'super-secret-key-change-me';
const otpLifetime = 5 * 60 * 1000;

function hashOtp(otp: string): string {
    return createHash('sha256').update(otp).digest('hex');
}

function logMail(message: string) {
    try {
        const logDir = path.resolve('logs');
        if (!fs.existsSync(logDir)) fs.mkdirSync(logDir, { recursive: true });
        const logFile = path.join(logDir, 'email.log');
        const timestamp = new Date().toISOString();
        fs.appendFileSync(logFile, `[${timestamp}] ${message}\n`);
    } catch (e) {
        console.error('Failed to write to email.log:', e);
    }
}

export const POST: RequestHandler = async ({ request }) => {
    try {
        const body = await request.json().catch(() => null);
        const email = typeof body?.email === 'string' ? body.email.trim().toLowerCase() : '';
        if (!email) {
            return json({ error: 'Enter your registered doctor email' }, { status: 400 });
        }

        const action = body.action || (body.otp ? 'verify' : 'send');

        if (action === 'send') {
            const now = new Date();
            const otp = String(randomInt(100000, 1000000));
            const hashed = hashOtp(otp);

            let doctor = await prisma.doctor.findUnique({ where: { email } });
            if (!doctor) {
                doctor = await prisma.doctor.create({
                    data: {
                        email,
                        name: email.split('@')[0],
                        otp: hashed,
                        otpCreatedAt: now
                    }
                });
            } else {
                await prisma.doctor.update({
                    where: { id: doctor.id },
                    data: { otp: hashed, otpCreatedAt: now }
                });
            }

            try {
                const senderAddress = env.SMTP_FROM || env.SMTP_USER || 'no-reply@novtek-atk.com';
                const info = await transporter.sendMail({
                    from: senderAddress,
                    to: doctor.email,
                    subject: 'Novtek ATK Doctor Login Code',
                    text: `Your doctor login code is: ${otp}. It expires in 5 minutes.`,
                    html: `<div style="font-family: sans-serif; padding: 20px; border: 1px solid #eee; border-radius: 10px; max-width: 400px; margin: 0 auto;">
                            <h2 style="color: #197278; text-align: center;">Novtek ATK Doctor Portal</h2>
                            <p>Hello Dr. ${doctor.name || doctor.email},</p>
                            <p>Use the following single-use verification code to access your doctor portal:</p>
                            <div style="font-size: 32px; font-weight: bold; text-align: center; padding: 20px; background: #f0fdfa; border-radius: 8px; margin: 20px 0; letter-spacing: 5px; color: #197278;">
                                ${otp}
                            </div>
                            <p style="text-align: center; font-weight: bold; color: #e11d48; margin: 15px 0;">This code expires in 5 minutes.</p>
                            <p style="font-size: 12px; color: #64748b; text-align: center;">If you did not request this login, please ignore this email.</p>
                          </div>`
                });

                logMail(`SUCCESS: Sent DOCTOR OTP ${otp} to ${email}. MessageId: ${info?.messageId || 'unknown'}`);
                console.log(`[DOCTOR MAILER] OTP for ${email}: ${otp}`);

                return json({
                    success: true,
                    message: 'OTP sent successfully to your doctor email',
                    debug_otp: otp
                });
            } catch (mailErr: any) {
                const errDetails = {
                    host: process.env.SMTP_HOST,
                    port: process.env.SMTP_PORT,
                    user: process.env.SMTP_USER,
                    error: mailErr?.message
                };
                logMail(`ERROR: Failed to send DOCTOR OTP to ${email}. Details: ${JSON.stringify(errDetails)}`);
                console.error('DOCTOR_SMTP_ERROR_DETAILS:', errDetails);
                console.log(`[DOCTOR FALLBACK MAILER] OTP for ${email}: ${otp}`);

                return json({
                    success: true,
                    message: 'OTP generated (development/fallback mode)',
                    debug_otp: otp
                });
            }
        }

        if (action !== 'verify') {
            return json({ error: 'Invalid OTP action' }, { status: 400 });
        }

        const otpInput = typeof body.otp === 'string' ? body.otp.trim() : '';
        if (!/^\d{6}$/.test(otpInput)) {
            return json({ error: 'Please enter a valid 6-digit code' }, { status: 400 });
        }

        const doctor = await prisma.doctor.findUnique({ where: { email } });
        const invalid = () => json({ error: 'Invalid or expired verification code. Please request a new code.' }, { status: 401 });

        if (!doctor || !doctor.otp || !doctor.otpCreatedAt) {
            return invalid();
        }

        if (Date.now() - new Date(doctor.otpCreatedAt).getTime() >= otpLifetime) {
            return invalid();
        }

        const matchesHashed = doctor.otp === hashOtp(otpInput);
        const matchesPlain = doctor.otp === otpInput;
        if (!matchesHashed && !matchesPlain) {
            return invalid();
        }

        // Clear OTP once consumed
        await prisma.doctor.update({
            where: { id: doctor.id },
            data: { otp: null }
        });

        const token = jwt.sign(
            { doctorId: doctor.id, email: doctor.email, role: 'doctor' },
            SECRET,
            { expiresIn: '7d' }
        );

        return json({
            token,
            role: 'doctor',
            doctor: {
                id: doctor.id,
                email: doctor.email,
                name: doctor.name,
                specialization: doctor.specialization,
                servicePincode: doctor.servicePincode,
                phoneNumber: doctor.phoneNumber,
                isProfileComplete: doctor.isProfileComplete || false
            }
        });
    } catch (error) {
        console.error('Doctor login failed:', error);
        return json({ error: 'Unable to sign in as a doctor' }, { status: 500 });
    }
};
