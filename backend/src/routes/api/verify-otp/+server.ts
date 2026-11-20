import { createHash } from 'node:crypto';
import { json } from '@sveltejs/kit';
import { prisma } from '$lib/server/prisma';
import jwt from 'jsonwebtoken';

const SECRET = process.env.JWT_SECRET || 'super-secret-key-change-me';

function hashOtp(otp: string): string {
    return createHash('sha256').update(otp).digest('hex');
}

export async function POST({ request }: { request: Request }) {
    try {
        const body = await request.json().catch(() => ({}));
        const email = typeof body.email === 'string' ? body.email.trim().toLowerCase() : '';
        const otp = typeof body.otp === 'string' ? body.otp.trim() : '';
        const role = body.role || 'user';

        if (!email || !otp) return json({ error: 'Missing credentials' }, { status: 400 });

        if (role === 'doctor') {
            const doctor = await prisma.doctor.findUnique({ where: { email } });
            if (!doctor || !doctor.otp) {
                return json({ error: 'Invalid OTP' }, { status: 401 });
            }

            const matchesHashed = doctor.otp === hashOtp(otp);
            const matchesPlain = doctor.otp === otp;
            if (!matchesHashed && !matchesPlain) {
                return json({ error: 'Invalid OTP' }, { status: 401 });
            }

            if (doctor.otpCreatedAt) {
                const timeDiff = Date.now() - new Date(doctor.otpCreatedAt).getTime();
                if (timeDiff > 5 * 60 * 1000) {
                    return json({ error: 'OTP has expired' }, { status: 401 });
                }
            }

            // Clear used OTP
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
        }

        const user = await prisma.user.findUnique({ where: { email } });

        if (!user || user.otp !== otp) {
            return json({ error: 'Invalid OTP' }, { status: 401 });
        }

        // Validate OTP Expiration (5 minutes = 300,000 milliseconds)
        if (user.otpCreatedAt) {
            const timeDifference = Date.now() - new Date(user.otpCreatedAt).getTime();
            if (timeDifference > 5 * 60 * 1000) {
                return json({ error: 'OTP has expired' }, { status: 401 });
            }
        }

        const token = jwt.sign({ userId: user.id, email: user.email, role: 'user' }, SECRET, { expiresIn: '7d' });

        return json({
            token,
            role: 'user',
            user: {
                email: user.email,
                id: user.id,
                name: user.name,
                isProfileComplete: user.isProfileComplete,
                hasCompletedInitialSurvey: user.hasCompletedInitialSurvey
            }
        });
    } catch (e) {
        console.error(e);
        return json({ error: 'Internal Server Error' }, { status: 500 });
    }
}
