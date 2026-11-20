import { prisma } from '$lib/server/prisma';
import { logAdminAction } from '$lib/server/audit';
import { fail } from '@sveltejs/kit';
import type { PageServerLoad, Actions } from './$types';

export const load: PageServerLoad = async () => {
    const [participants, settings] = await Promise.all([
        prisma.user.findMany({
            orderBy: { createdAt: 'desc' },
            include: {
                submissions: {
                    orderBy: { startedAt: 'desc' },
                    select: {
                        id: true,
                        status: true,
                        startedAt: true,
                        completedAt: true,
                        surveyCategory: true,
                        surveyType: true,
                        score: true
                    }
                }
            }
        }),
        prisma.surveySettings.findMany()
    ]);

    return {
        participants: JSON.parse(JSON.stringify(participants)),
        settings: JSON.parse(JSON.stringify(settings))
    };
};

export const actions: Actions = {
    createParticipant: async ({ request }) => {
        const data = await request.formData();
        const email = String(data.get('email') || '').trim().toLowerCase();
        const name = String(data.get('name') || '').trim();
        const phoneNumber = String(data.get('phoneNumber') || '').trim();
        const pinCode = String(data.get('pinCode') || '').trim();
        const age = String(data.get('age') || '').trim();
        const gender = String(data.get('gender') || '').trim();
        const occupation = String(data.get('occupation') || '').trim();
        const maritalStatus = String(data.get('maritalStatus') || '').trim();
        const surveyCategory = String(data.get('surveyCategory') || 'ADDICTION').trim().toUpperCase();

        if (!email) {
            return fail(400, { error: 'Participant email is required' });
        }

        const existing = await prisma.user.findUnique({ where: { email } });
        if (existing) {
            return fail(400, { error: 'A participant with this email already exists' });
        }

        const newUser = await prisma.user.create({
            data: {
                email,
                name: name || null,
                phoneNumber: phoneNumber || null,
                pinCode: pinCode || null,
                age: age || null,
                gender: gender || null,
                occupation: occupation || null,
                maritalStatus: maritalStatus || null,
                surveyCategory: surveyCategory === 'MENTAL' ? 'MENTAL' : 'ADDICTION',
                isProfileComplete: Boolean(name && phoneNumber && pinCode)
            }
        });

        await logAdminAction(
            'CREATE_PARTICIPANT',
            `Enrolled new participant: ${newUser.email} (Name: ${name || 'N/A'}, Category: ${newUser.surveyCategory})`
        );

        return { success: true };
    },

    deleteParticipant: async ({ request }) => {
        const data = await request.formData();
        const id = Number(data.get('id'));

        const targetUser = await prisma.user.findUnique({
            where: { id },
            select: { email: true }
        });

        await prisma.$transaction([
            prisma.answerChoice.deleteMany({ where: { answer: { submission: { userId: id } } } }),
            prisma.answer.deleteMany({ where: { submission: { userId: id } } }),
            prisma.submission.deleteMany({ where: { userId: id } }),
            prisma.user.delete({ where: { id } })
        ]);

        if (targetUser) {
            await logAdminAction('DELETE_PARTICIPANT', `Deleted participant: ${targetUser.email} (ID: ${id})`);
        }

        return { success: true };
    },

    resetParticipantSurvey: async ({ request }) => {
        const data = await request.formData();
        const id = Number(data.get('id'));

        const targetUser = await prisma.user.findUnique({
            where: { id },
            select: { email: true }
        });

        if (!targetUser) {
            return fail(404, { error: 'Participant not found' });
        }

        await prisma.$transaction([
            prisma.answerChoice.deleteMany({ where: { answer: { submission: { userId: id } } } }),
            prisma.answer.deleteMany({ where: { submission: { userId: id } } }),
            prisma.submission.deleteMany({ where: { userId: id } }),
            prisma.user.update({
                where: { id },
                data: {
                    hasCompletedInitialSurvey: false,
                    hasUnlockedDetailedSurvey: false
                }
            })
        ]);

        await logAdminAction('RESET_PARTICIPANT_SURVEY', `Reset all assessment progress and clinical submissions for participant: ${targetUser.email} (ID: ${id})`);

        return { success: true };
    },

    updateParticipant: async ({ request }) => {
        const data = await request.formData();
        const id = Number(data.get('id'));
        const name = String(data.get('name') || '').trim();
        const phoneNumber = String(data.get('phoneNumber') || '').trim();
        const pinCode = String(data.get('pinCode') || '').trim();
        const age = String(data.get('age') || '').trim();
        const gender = String(data.get('gender') || '').trim();
        const occupation = String(data.get('occupation') || '').trim();
        const maritalStatus = String(data.get('maritalStatus') || '').trim();

        const targetUser = await prisma.user.findUnique({
            where: { id },
            select: { email: true }
        });

        if (!targetUser) {
            return fail(404, { error: 'Participant not found' });
        }

        await prisma.user.update({
            where: { id },
            data: {
                name: name || null,
                phoneNumber: phoneNumber || null,
                pinCode: pinCode || null,
                age: age || null,
                gender: gender || null,
                occupation: occupation || null,
                maritalStatus: maritalStatus || null,
                isProfileComplete: Boolean(name && phoneNumber && pinCode)
            }
        });

        await logAdminAction(
            'UPDATE_PARTICIPANT_PROFILE',
            `Updated profile details for participant: ${targetUser.email} (Name: ${name || 'N/A'}, Phone: ${phoneNumber || 'N/A'}, Pincode: ${pinCode || 'N/A'})`
        );

        return { success: true };
    }
};
