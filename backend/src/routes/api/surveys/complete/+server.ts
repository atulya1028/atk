import { json } from '@sveltejs/kit';
import { prisma } from '$lib/server/prisma';
import { getUserFromRequest } from '$lib/server/auth';
import { handleCriticalSubmission } from '$lib/server/alerts';
import type { RequestEvent } from '@sveltejs/kit';

export async function POST({ request, url }: RequestEvent) {
    const user = getUserFromRequest(request);
    if (!user) return json({ error: 'Unauthorized' }, { status: 401 });

    try {
        const { submission_id } = await request.json();

        if (!submission_id) {
            return json({ error: 'Missing submission_id' }, { status: 400 });
        }

        const submission = await prisma.submission.findUnique({ where: { id: Number(submission_id) } });
        if (!submission || submission.userId !== user.userId) {
            return json({ error: 'Submission invalid' }, { status: 403 });
        }

        // Calculate score
        const answers = await prisma.answer.findMany({
            where: { submissionId: Number(submission_id) },
            include: {
                choices: {
                    include: {
                        option: true
                    }
                }
            }
        });

        if (answers.length === 0) {
            return json({ error: 'At least one answer is required to complete the assessment' }, { status: 422 });
        }

        let totalScore = 0;
        for (const answer of answers) {
            for (const choice of answer.choices) {
                totalScore += (choice.option?.scoreValue || 0);
            }
        }

        console.log(`Completing submission ${submission_id} for user ${user.userId}. Total Score: ${totalScore}`);

        const updated = await prisma.submission.update({
            where: { id: Number(submission_id) },
            data: {
                status: 'COMPLETED',
                completedAt: new Date(),
                score: totalScore
            }
        });

        if (submission.surveyType === 'INITIAL') {
            const surveyCategory = submission.surveyCategory.toUpperCase();
            
            // Fetch dynamic threshold from settings
            const settings = await prisma.surveySettings.findUnique({
                where: { surveyCategory }
            });
            const threshold = settings?.threshold ?? 30;

            console.log(`Setting hasCompletedInitialSurvey=true for user ${user.userId}`);

            const updateData: any = { hasCompletedInitialSurvey: true };

            if (totalScore >= threshold) {
                console.log(`Score >= ${threshold} in ${surveyCategory}. Unlocking Detailed Survey for user ${user.userId}`);
                updateData.hasUnlockedDetailedSurvey = true;
            }

            await prisma.user.update({
                where: { id: user.userId },
                data: updateData
            });
        } else if (submission.surveyType === 'DETAILED') {
            // Trigger alerts asynchronously in the background
            handleCriticalSubmission(Number(submission_id), totalScore, url.origin).catch(err => {
                console.error('[ALERTS_TRIGGER_ERROR] Failed during handleCriticalSubmission:', err);
            });
        }

        return json({ success: true });
    } catch (e) {
        console.error(e);
        return json({ error: 'Internal Error' }, { status: 500 });
    }
}
