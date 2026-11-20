import { prisma } from '$lib/server/prisma';
import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';

export const GET: RequestHandler = async ({ params }) => {
    const id = Number(params.id);
    if (!id || isNaN(id)) return json({ error: 'Invalid ID' }, { status: 400 });

    const submission = await prisma.submission.findUnique({
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
    });

    if (!submission) return json({ error: 'Not found' }, { status: 404 });

    const serializedSubmission = {
        ...submission,
        startedAt: submission.startedAt.toISOString(),
        completedAt: submission.completedAt?.toISOString() || null,
        user: submission.user ? {
            ...submission.user,
            createdAt: submission.user.createdAt.toISOString()
        } : null,
        answers: submission.answers.map((answer: any) => ({
            ...answer,
            valueDec: answer.valueDec ? String(answer.valueDec) : null,
            createdAt: answer.createdAt.toISOString(),
            valueDate: answer.valueDate?.toISOString() || null
        }))
    };

    return json(serializedSubmission);
};
