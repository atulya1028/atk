import { prisma } from '$lib/server/prisma';
import { logAdminAction } from '$lib/server/audit';
import { fail } from '@sveltejs/kit';
import type { PageServerLoad, Actions } from './$types';

export const load: PageServerLoad = async () => {
    const [doctors, allUsers, settings] = await Promise.all([
        prisma.doctor.findMany({
            orderBy: { createdAt: 'desc' },
            include: {
                _count: {
                    select: { assignedSubmissions: true }
                }
            }
        }),
        prisma.user.findMany({
            select: {
                id: true,
                pinCode: true,
                submissions: {
                    select: {
                        id: true,
                        surveyType: true,
                        score: true,
                        surveyCategory: true
                    }
                }
            }
        }),
        prisma.surveySettings.findMany()
    ]);

    const criticalMap: Record<string, number> = {};
    for (const s of settings) {
        criticalMap[s.surveyCategory.toUpperCase()] = s.criticalValue;
    }

    const enrichedDoctors = doctors.map((doc: any) => {
        const rawPincodes = doc.servicePincode || '';
        const pincodes = rawPincodes
            .split(',')
            .map((p: string) => p.trim().toLowerCase())
            .filter((p: string) => p.length > 0);

        let matchingPatientsCount = 0;
        let criticalPatientsCount = 0;

        if (pincodes.length > 0) {
            allUsers.forEach((u: any) => {
                if (u.pinCode && pincodes.includes(u.pinCode.trim().toLowerCase())) {
                    matchingPatientsCount++;
                    const hasCritical = u.submissions?.some((sub: any) => {
                        const threshold = criticalMap[sub.surveyCategory?.toUpperCase() || 'ADDICTION'] ?? 50;
                        return sub.surveyType === 'DETAILED' && sub.score >= threshold;
                    });
                    if (hasCritical) {
                        criticalPatientsCount++;
                    }
                }
            });
        }

        return {
            id: doc.id,
            email: doc.email,
            name: doc.name || 'Unnamed Doctor',
            phoneNumber: doc.phoneNumber || '-',
            specialization: doc.specialization || 'General / Addiction Medicine',
            servicePincode: doc.servicePincode || '',
            pincodesList: doc.servicePincode
                ? doc.servicePincode.split(',').map((p: string) => p.trim()).filter(Boolean)
                : [],
            isProfileComplete: doc.isProfileComplete,
            createdAt: doc.createdAt.toISOString(),
            matchingPatientsCount,
            criticalPatientsCount,
            activeAssignedCount: doc._count?.assignedSubmissions || 0
        };
    });

    return {
        doctors: enrichedDoctors
    };
};

export const actions: Actions = {
    createDoctor: async ({ request }) => {
        const data = await request.formData();
        const email = String(data.get('email') || '').trim().toLowerCase();
        const name = String(data.get('name') || '').trim();
        const phoneNumber = String(data.get('phoneNumber') || '').trim();
        const specialization = String(data.get('specialization') || '').trim();
        const servicePincode = String(data.get('servicePincode') || '').trim();

        if (!email) {
            return fail(400, { error: 'Doctor email is required' });
        }

        const existing = await prisma.doctor.findUnique({ where: { email } });
        if (existing) {
            return fail(400, { error: 'A doctor with this email already exists' });
        }

        const newDoc = await prisma.doctor.create({
            data: {
                email,
                name: name || null,
                phoneNumber: phoneNumber || null,
                specialization: specialization || null,
                servicePincode: servicePincode || null,
                isProfileComplete: true
            }
        });

        await logAdminAction('CREATE_DOCTOR', `Added new clinician: Dr. ${newDoc.name || email} (${newDoc.specialization || 'Clinical'}) - Pincodes: [${servicePincode || 'None'}]`);

        return { success: true };
    },

    updateDoctor: async ({ request }) => {
        const data = await request.formData();
        const id = Number(data.get('id'));
        const name = String(data.get('name') || '').trim();
        const phoneNumber = String(data.get('phoneNumber') || '').trim();
        const specialization = String(data.get('specialization') || '').trim();
        const servicePincode = String(data.get('servicePincode') || '').trim();
        const isProfileComplete = data.get('isProfileComplete') === 'on' || data.get('isProfileComplete') === 'true';

        const existing = await prisma.doctor.findUnique({ where: { id } });
        if (!existing) {
            return fail(404, { error: 'Doctor not found' });
        }

        await prisma.doctor.update({
            where: { id },
            data: {
                name: name || null,
                phoneNumber: phoneNumber || null,
                specialization: specialization || null,
                servicePincode: servicePincode || null,
                isProfileComplete
            }
        });

        await logAdminAction('UPDATE_DOCTOR', `Updated clinician profile: Dr. ${name || existing.email} - Pincodes: [${servicePincode || 'None'}]`);

        return { success: true };
    },

    deleteDoctor: async ({ request }) => {
        const data = await request.formData();
        const id = Number(data.get('id'));

        const existing = await prisma.doctor.findUnique({ where: { id } });
        if (!existing) {
            return fail(404, { error: 'Doctor not found' });
        }

        // Unlink assigned submissions first
        await prisma.submission.updateMany({
            where: { assignedDoctorId: id },
            data: { assignedDoctorId: null }
        });

        await prisma.doctor.delete({ where: { id } });

        await logAdminAction('DELETE_DOCTOR', `Removed clinician: ${existing.name || existing.email} (ID: ${id})`);

        return { success: true };
    }
};
