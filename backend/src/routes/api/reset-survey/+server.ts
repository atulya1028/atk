import { json } from '@sveltejs/kit';
import { prisma } from '$lib/server/prisma';
import { getUserFromRequest } from '$lib/server/auth';
import type { RequestHandler } from './$types';

export const POST: RequestHandler = async ({ request }) => {

    const user = getUserFromRequest(request);

    if (!user) {
        return json({ error: 'Unauthorized' }, { status: 401 });
    }

    try {
        const userId = user.userId;

        await prisma.$transaction(async (tx: any) => {

            const submissions = await tx.submission.findMany({
                where: { userId },
                select: { id: true }
            });
            const submissionIds = submissions.map((s: any) => s.id);

            if (submissionIds.length > 0) {

                await tx.answerChoice.deleteMany({
                    where: {
                        answer: {
                            submissionId: { in: submissionIds }
                        }
                    }
                });

                await tx.answer.deleteMany({
                    where: { submissionId: { in: submissionIds } }
                });

                await tx.submission.deleteMany({
                    where: { id: { in: submissionIds } }
                });
            }

            // Reset user progress flags
            await tx.user.update({
                where: { id: userId },
                data: {
                    hasCompletedInitialSurvey: false,
                    hasUnlockedDetailedSurvey: false
                }
            });
        });

        return json({
            success: true,
            message: 'All survey data reset successfully for user.'
        });

    } catch (e) {
        console.error('Reset Survey Error:', e);
        return json({ error: 'Internal Server Error' }, { status: 500 });
    }
};
