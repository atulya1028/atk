import { prisma } from '$lib/server/prisma';
import { logAdminAction } from '$lib/server/audit';
import { fail } from '@sveltejs/kit';
import type { PageServerLoad, Actions } from './$types';

export const load: PageServerLoad = async () => {
    const [submissions, settings, doctors] = await Promise.all([
        prisma.submission.findMany({
            orderBy: { startedAt: 'desc' },
            include: {
                user: true,
                assignedDoctor: true,
                _count: { select: { answers: true } }
            }
        }),
        prisma.surveySettings.findMany(),
        prisma.doctor.findMany({
            select: { id: true, name: true, email: true, specialization: true }
        })
    ]);

    return {
        submissions: submissions.map((s: any) => ({
            ...s,
            email: s.user?.email || 'Unknown User',
            userName: s.user?.name || '',
            userPhone: s.user?.phoneNumber || '',
            userPinCode: s.user?.pinCode || '',
            answersCount: s._count.answers,
            surveyType: s.surveyType,
            score: s.score,
            triageStatus: s.triageStatus || 'NEW',
            assignedDoctorId: s.assignedDoctorId,
            assignedDoctorName: s.assignedDoctor ? (s.assignedDoctor.name || s.assignedDoctor.email) : null,
            clinicalNotes: s.clinicalNotes || ''
        })),
        settings: JSON.parse(JSON.stringify(settings)),
        doctors: JSON.parse(JSON.stringify(doctors))
    };
};

export const actions: Actions = {
    updateTriage: async ({ request }) => {
        const data = await request.formData();
        const submissionId = Number(data.get('submissionId'));
        const triageStatus = String(data.get('triageStatus') || 'NEW');
        const assignedDoctorIdRaw = data.get('assignedDoctorId');
        const assignedDoctorId = assignedDoctorIdRaw && assignedDoctorIdRaw !== '' ? Number(assignedDoctorIdRaw) : null;
        const clinicalNotes = String(data.get('clinicalNotes') || '').trim();

        if (!submissionId) {
            return fail(400, { error: 'Missing submission ID' });
        }

        const submission = await prisma.submission.findUnique({
            where: { id: submissionId },
            include: { user: true }
        });

        if (!submission) {
            return fail(404, { error: 'Submission not found' });
        }

        let doctorName = 'Unassigned';
        if (assignedDoctorId) {
            const doc = await prisma.doctor.findUnique({ where: { id: assignedDoctorId } });
            if (doc) doctorName = doc.name || doc.email;
        }

        await prisma.submission.update({
            where: { id: submissionId },
            data: {
                triageStatus,
                assignedDoctorId,
                clinicalNotes: clinicalNotes || null
            }
        });

        await logAdminAction(
            'UPDATE_TRIAGE',
            `Updated clinical triage for Submission #${submissionId} (${submission.user?.email || 'User'}): Status='${triageStatus}', Clinician='${doctorName}'`
        );

        return { success: true };
    },

    deleteSubmission: async ({ request }) => {
        const data = await request.formData();
        const id = Number(data.get('id'));

        if (!id || isNaN(id)) {
            return fail(400, { error: 'Invalid submission ID' });
        }

        const submission = await prisma.submission.findUnique({
            where: { id },
            include: { user: true }
        });

        if (!submission) {
            return fail(404, { error: 'Submission not found' });
        }

        await prisma.$transaction([
            prisma.answerChoice.deleteMany({ where: { answer: { submissionId: id } } }),
            prisma.answer.deleteMany({ where: { submissionId: id } }),
            prisma.submission.delete({ where: { id } })
        ]);

        await logAdminAction(
            'DELETE_SUBMISSION',
            `Deleted clinical submission #${id} for participant: ${submission.user?.email || 'N/A'} (${submission.surveyType} - ${submission.surveyCategory})`
        );

        return { success: true };
    }
};
