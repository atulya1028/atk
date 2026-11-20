import { json } from '@sveltejs/kit';
import { prisma } from '$lib/server/prisma';
import jwt from 'jsonwebtoken';
import type { RequestHandler } from './$types';

const SECRET = process.env.JWT_SECRET || 'super-secret-key-change-me';

function getEmailFromRequest(request: Request, url: URL): string | null {
    const emailParam = url.searchParams.get('email');
    if (emailParam) return emailParam.trim().toLowerCase();

    const authHeader = request.headers.get('Authorization');
    if (authHeader && authHeader.startsWith('Bearer ')) {
        const token = authHeader.split(' ')[1];
        try {
            const decoded = jwt.verify(token, SECRET) as any;
            if (decoded?.email) return decoded.email.trim().toLowerCase();
        } catch {
            // ignore token error here and fall back
        }
    }
    return null;
}

export const GET: RequestHandler = async ({ request, url }) => {
    try {
        const email = getEmailFromRequest(request, url);
        if (!email) {
            return json({ error: 'Doctor email parameter is required' }, { status: 400 });
        }

        const doctor = await prisma.doctor.findUnique({
            where: { email }
        });

        if (!doctor) {
            return json({ error: 'Doctor not found' }, { status: 404 });
        }

        return json({
            success: true,
            doctor: {
                id: doctor.id,
                email: doctor.email,
                name: doctor.name,
                phoneNumber: doctor.phoneNumber,
                specialization: doctor.specialization,
                servicePincode: doctor.servicePincode,
                isProfileComplete: doctor.isProfileComplete || false
            }
        });
    } catch (e: any) {
        console.error('GET_DOCTOR_PROFILE_ERROR:', e);
        return json({ error: 'Internal Server Error', details: e?.message }, { status: 500 });
    }
};

export const POST: RequestHandler = async ({ request, url }) => {
    try {
        const body = await request.json().catch(() => ({}));
        let email = typeof body.email === 'string' ? body.email.trim().toLowerCase() : '';
        if (!email) {
            email = getEmailFromRequest(request, url) || '';
        }
        if (!email) {
            return json({ error: 'Doctor email is required' }, { status: 400 });
        }

        const { name, phoneNumber, specialization, servicePincode } = body;

        const doctor = await prisma.doctor.upsert({
            where: { email },
            update: {
                name: name !== undefined ? name : undefined,
                phoneNumber: phoneNumber !== undefined ? phoneNumber : undefined,
                specialization: specialization !== undefined ? specialization : undefined,
                servicePincode: servicePincode !== undefined ? servicePincode : undefined,
                isProfileComplete: true
            },
            create: {
                email,
                name: name || email.split('@')[0],
                phoneNumber,
                specialization,
                servicePincode,
                isProfileComplete: true
            }
        });

        return json({
            success: true,
            message: 'Doctor profile updated successfully',
            doctor: {
                id: doctor.id,
                email: doctor.email,
                name: doctor.name,
                phoneNumber: doctor.phoneNumber,
                specialization: doctor.specialization,
                servicePincode: doctor.servicePincode,
                isProfileComplete: true
            }
        });
    } catch (e: any) {
        console.error('POST_DOCTOR_PROFILE_ERROR:', e);
        return json({ error: 'Internal Server Error', details: e?.message }, { status: 500 });
    }
};
