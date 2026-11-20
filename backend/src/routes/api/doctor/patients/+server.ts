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
            // ignore
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

        const doctor = await prisma.doctor.findUnique({ where: { email } });
        if (!doctor) {
            return json({ error: 'Doctor not found' }, { status: 404 });
        }

        const rawPincodes = doctor.servicePincode || '';
        const pincodes = rawPincodes
            .split(',')
            .map((p) => p.trim())
            .filter((p) => p.length > 0);

        const settings = await prisma.surveySettings.findMany();
        const criticalThresholdMap: Record<string, number> = {};
        for (const s of settings) {
            criticalThresholdMap[s.surveyCategory.toUpperCase()] = s.criticalValue;
        }

        const rawPatients = await prisma.user.findMany({
            select: {
                id: true,
                email: true,
                name: true,
                age: true,
                gender: true,
                phoneNumber: true,
                pinCode: true,
                occupation: true,
                maritalStatus: true,
                isProfileComplete: true,
                hasCompletedInitialSurvey: true,
                hasUnlockedDetailedSurvey: true,
                surveyCategory: true,
                createdAt: true,
                submissions: {
                    select: {
                        id: true,
                        surveyType: true,
                        status: true,
                        surveyCategory: true,
                        score: true,
                        completedAt: true
                    },
                    orderBy: {
                        startedAt: 'desc'
                    }
                }
            },
            orderBy: {
                createdAt: 'desc'
            }
        });

        const enrichedPatients = rawPatients.map((u) => {
            const subs = u.submissions || [];
            let isCriticalRisk = false;
            let maxScore = 0;
            let criticalCategory = '';

            for (const sub of subs) {
                const cat = (sub.surveyCategory || u.surveyCategory || 'ADDICTION').toUpperCase();
                const threshold = criticalThresholdMap[cat] ?? 50;
                if (sub.score > maxScore) {
                    maxScore = sub.score;
                }
                if (sub.surveyType === 'DETAILED' && sub.score >= threshold) {
                    isCriticalRisk = true;
                    criticalCategory = cat;
                }
            }

            return {
                ...u,
                isCriticalRisk,
                maxScore,
                criticalCategory
            };
        });

        let matchingPatients = enrichedPatients;
        if (pincodes.length > 0) {
            matchingPatients = enrichedPatients.filter((u) => {
                if (!u.pinCode) return false;
                const userPin = u.pinCode.trim().toLowerCase();
                return pincodes.some((pin) => pin.toLowerCase() === userPin);
            });
        }

        return json({
            success: true,
            doctor: {
                id: doctor.id,
                email: doctor.email,
                name: doctor.name,
                specialization: doctor.specialization,
                servicePincode: doctor.servicePincode,
                phoneNumber: doctor.phoneNumber,
                isProfileComplete: doctor.isProfileComplete || false
            },
            doctorPincodes: pincodes,
            patients: matchingPatients,
            allPatients: enrichedPatients,
            matchingCount: matchingPatients.length,
            totalPatientsCount: enrichedPatients.length
        });
    } catch (e: any) {
        console.error('GET_DOCTOR_PATIENTS_ERROR:', e);
        return json({ error: 'Internal Server Error', details: e?.message }, { status: 500 });
    }
};
