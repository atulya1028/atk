import { prisma } from '$lib/server/prisma';
import { logAdminAction } from '$lib/server/audit';
import { error, fail, redirect } from '@sveltejs/kit';
import type { PageServerLoad, Actions } from './$types';

export const load: PageServerLoad = async ({ params }) => {
    const id = Number(params.id);
    if (!id || isNaN(id)) throw error(404, 'Submission not found');

    const [submission, doctors] = await Promise.all([
        prisma.submission.findUnique({
            where: { id },
            include: {
                user: true,
                assignedDoctor: true,
                answers: {
                    orderBy: { createdAt: 'asc' },
                    include: {
                        question: {
                            include: {
                                section: {
                                    include: { parent: true }
                                }
                            }
                        },
                        choices: {
                            include: { option: true }
                        }
                    }
                }
            }
        }),
        prisma.doctor.findMany({
            select: { id: true, name: true, email: true, specialization: true }
        })
    ]);

    if (!submission) throw error(404, 'Submission not found');

    const serializedSubmission = {
        ...submission,
        startedAt: submission.startedAt.toISOString(),
        completedAt: submission.completedAt?.toISOString() || null,
        answers: submission.answers.map((answer: any) => ({
            ...answer,
            valueDec: answer.valueDec ? String(answer.valueDec) : null
        }))
    };

    return {
        submission: serializedSubmission,
        doctors: JSON.parse(JSON.stringify(doctors))
    };
};

export const actions: Actions = {
    updateTriage: async ({ request, params }) => {
        const id = Number(params.id);
        const data = await request.formData();
        const triageStatus = String(data.get('triageStatus') || 'NEW');
        const assignedDoctorIdRaw = data.get('assignedDoctorId');
        const assignedDoctorId = assignedDoctorIdRaw && assignedDoctorIdRaw !== '' ? Number(assignedDoctorIdRaw) : null;
        const clinicalNotes = String(data.get('clinicalNotes') || '').trim();

        const submission = await prisma.submission.findUnique({
            where: { id },
            include: { user: true }
        });

        if (!submission) return fail(404, { error: 'Submission not found' });

        let doctorName = 'Unassigned';
        if (assignedDoctorId) {
            const doc = await prisma.doctor.findUnique({ where: { id: assignedDoctorId } });
            if (doc) doctorName = doc.name || doc.email;
        }

        await prisma.submission.update({
            where: { id },
            data: {
                triageStatus,
                assignedDoctorId,
                clinicalNotes: clinicalNotes || null
            }
        });

        await logAdminAction(
            'UPDATE_TRIAGE',
            `Updated triage for submission #${id} (${submission.user?.email || 'User'}): Status='${triageStatus}', Clinician='${doctorName}'`
        );

        return { success: true };
    },

    deleteSubmission: async ({ params }) => {
        const id = Number(params.id);
        if (!id || isNaN(id)) return fail(400, { error: 'Invalid ID' });

        const submission = await prisma.submission.findUnique({
            where: { id },
            include: { user: true }
        });

        if (!submission) return fail(404, { error: 'Submission not found' });

        await prisma.$transaction([
            prisma.answerChoice.deleteMany({ where: { answer: { submissionId: id } } }),
            prisma.answer.deleteMany({ where: { submissionId: id } }),
            prisma.submission.delete({ where: { id } })
        ]);

        await logAdminAction(
            'DELETE_SUBMISSION',
            `Deleted submission #${id} for participant ${submission.user?.email || 'N/A'}`
        );

        throw redirect(303, '/admin/submissions');
    }
};
