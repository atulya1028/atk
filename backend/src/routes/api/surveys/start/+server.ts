import { json } from '@sveltejs/kit';
import { prisma } from '$lib/server/prisma';
import { getUserFromRequest } from '$lib/server/auth';
import type { RequestEvent } from '@sveltejs/kit';

export async function POST({ request }: RequestEvent) {
    const user = getUserFromRequest(request);
    if (!user) return json({ error: 'Unauthorized' }, { status: 401 });

    try {
        const body = await request.json().catch(() => ({}));
        const surveyType = (body.surveyType || 'INITIAL').toUpperCase();

        const fullUser = await prisma.user.findUnique({ where: { id: user.userId } });
        const surveyCategory = (body.surveyCategory || fullUser?.surveyCategory || 'ADDICTION').toUpperCase();

        // Fetch dynamic threshold
        const settings = await prisma.surveySettings.findUnique({
            where: { surveyCategory }
        });
        const threshold = settings?.threshold ?? 30;

        const unlockedDetailed = await prisma.submission.findFirst({
            where: { userId: user.userId, surveyType: 'INITIAL', status: 'COMPLETED', surveyCategory: surveyCategory, score: { gte: threshold } }
        });

        if (surveyType === 'DETAILED' && !unlockedDetailed) {
            return json({ error: `Score of ${threshold}+ required in Initial ${surveyCategory === 'MENTAL' ? 'Mental' : 'Addiction'} Assessment to unlock the Detailed Survey.` }, { status: 403 });
        }

        const noCreate = body.noCreate === true;

        let submission = await prisma.submission.findFirst({
            where: {
                userId: user.userId,
                status: 'DRAFT',
                surveyType: surveyType,
                surveyCategory: surveyCategory
            },
            include: {
                answers: {
                    include: { question: true }
                }
            }
        });

        if (!submission && !noCreate) {
            submission = await prisma.submission.create({
                data: {
                    userId: user.userId,
                    status: 'DRAFT',
                    surveyType: surveyType,
                    surveyCategory: surveyCategory
                },
                include: {
                    answers: {
                        include: { question: true }
                    }
                }
            });
        }

        const formattedAnswers = submission ? await Promise.all(submission.answers.map(async (a: any) => {

            let choices: any[] = [];
            if (['select', 'multi_select', 'radio', 'yesno'].includes(a.question.inputType)) {
                const acs = await prisma.answerChoice.findMany({
                    where: { answerId: a.id },
                    include: { option: true }
                });
                choices = acs.map((ac: any) => ({
                    option: {
                        label: ac.option.label,
                        value: ac.option.value
                    }
                }));
            }

            return {
                question: {
                    slug: a.question.slug,
                    text: a.question.text
                },
                value: a.valueString || a.valueText || a.valueInt || a.valueBool || a.legacyValueText,
                value_text: a.valueString || a.valueText || a.legacyValueText,
                value_int: a.valueInt,
                choices: choices
            };
        })) : [];

        const totalCompleted = await prisma.submission.count({
            where: { userId: user.userId, status: 'COMPLETED', surveyCategory: surveyCategory }
        });

        const totalAnswers = await prisma.answer.count({
            where: { submission: { userId: user.userId, surveyCategory: surveyCategory } }
        });

        const firstSubmission = await prisma.submission.findFirst({
            where: { userId: user.userId, surveyCategory: surveyCategory },
            orderBy: { startedAt: 'asc' }
        });

        let daysActive = 0;
        if (firstSubmission) {
            const ms = new Date().getTime() - firstSubmission.startedAt.getTime();
            daysActive = Math.max(1, Math.ceil(ms / (1000 * 60 * 60 * 24)));
        }

        const user_stats = {
            completed_surveys: totalCompleted,
            total_answers: totalAnswers,
            days_active: daysActive
        };

        const detailedCompleted = await prisma.submission.findFirst({
            where: { userId: user.userId, surveyType: 'DETAILED', status: 'COMPLETED', surveyCategory: surveyCategory }
        });

        const initialCompleted = await prisma.submission.findFirst({
            where: {
                userId: user.userId,
                surveyType: 'INITIAL',
                status: 'COMPLETED',
                surveyCategory,
                answers: { some: {} }
            }
        });

        return json({
            data: submission ? {
                id: submission.id,
                answers: formattedAnswers
            } : null,
            user_name: fullUser?.name || user.email,
            user_stats: user_stats,
            hasCompletedInitialSurvey: !!initialCompleted,
            hasCompletedDetailedSurvey: !!detailedCompleted,
            hasUnlockedDetailedSurvey: !!unlockedDetailed,
            isProfileComplete: fullUser?.isProfileComplete || false,
            surveyCategory: surveyCategory
        });
    } catch (e) {
        console.error(e);
        return json({ error: 'Internal Error' }, { status: 500 });
    }
}
