import { json } from '@sveltejs/kit';
import { prisma } from '$lib/server/prisma';
import { getUserFromRequest } from '$lib/server/auth';
import type { RequestEvent } from '@sveltejs/kit';

export async function GET({ request }: RequestEvent) {
    const user = getUserFromRequest(request);
    if (!user) return json({ error: 'Unauthorized' }, { status: 401 });

    try {
        const url = new URL(request.url);
        const surveyCategoryOpen = url.searchParams.get('surveyCategory') || url.searchParams.get('category');
        const surveyCategory = surveyCategoryOpen?.toUpperCase();

        const allSubmissions = await prisma.submission.findMany({
            where: {
                userId: user.userId,
                ...(surveyCategory ? { surveyCategory } : {})
            },
            orderBy: { startedAt: 'desc' },
            include: {
                _count: {
                    select: { answers: true }
                },
                answers: {
                    include: { question: true }
                }
            }
        });

        // Filter out drafts with no answers
        const submissions = allSubmissions.filter((sub: any) =>
            sub.status === 'COMPLETED' || sub._count.answers > 0
        );

        const formatted = await Promise.all(submissions.map(async (sub: any, i: number) => {
            const formattedAnswers = await Promise.all(sub.answers.map(async (a: any) => {
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
            }));

            return {
                id: submissions.length - i,
                status: sub.status,
                surveyType: sub.surveyType,
                startedAt: sub.startedAt,
                completedAt: sub.completedAt,
                answers: formattedAnswers
            };
        }));

        return json({ data: formatted });
    } catch (e) {
        console.error(e);
        return json({ error: 'Internal Error' }, { status: 500 });
    }
}
