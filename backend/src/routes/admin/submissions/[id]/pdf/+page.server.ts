import { prisma } from '$lib/server/prisma';
import { error } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ params }) => {
    const id = Number(params.id);
    if (!id || isNaN(id)) throw error(404, 'Submission not found');

    const [submission, settings] = await Promise.all([
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
        prisma.surveySettings.findMany()
    ]);

    if (!submission) throw error(404, 'Submission not found');

    const categorySettings = settings.find((s: any) => s.surveyCategory === submission.surveyCategory);
    const criticalValue = categorySettings?.criticalValue ?? 50;
    const threshold = categorySettings?.threshold ?? 30;

    const isCritical = submission.surveyType === 'DETAILED' && submission.score >= criticalValue;
    const isModerate = submission.score >= threshold && !isCritical;

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
        criticalValue,
        threshold,
        isCritical,
        isModerate
    };
};
