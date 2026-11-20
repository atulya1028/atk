import { json } from '@sveltejs/kit';
import { prisma } from '$lib/server/prisma';
import { getUserFromRequest } from '$lib/server/auth';
import type { RequestHandler } from './$types';

export const GET: RequestHandler = async ({ request }) => {
    const user = getUserFromRequest(request);
    if (!user) return json({ error: 'Unauthorized' }, { status: 401 });

    try {
        const url = new URL(request.url);
        const surveyType = (url.searchParams.get('type') || 'INITIAL').toUpperCase();
        const surveyCategory = (url.searchParams.get('category') || url.searchParams.get('surveyCategory') || 'ADDICTION').toUpperCase();

        const questions = await prisma.question.findMany({
            where: {
                section: {
                    surveyType: surveyType,
                    surveyCategory: surveyCategory
                }
            },
            orderBy: [
                { section: { sortOrder: 'asc' } },
                { sortOrder: 'asc' }
            ],
            include: {
                section: {
                    include: {
                        displayRules: {
                            include: {
                                triggerQuestion: true
                            }
                        }
                    }
                },
                options: true,
                prerequisites: {
                    include: {
                        triggerQuestion: true
                    }
                }
            }
        });

        return json({
            success: true,
            questions: questions.map((q: any) => {
                // Read section-level display rules from relational field
                const sectionRules = (q.section?.displayRules || []).map((r: any) => ({
                    trigger_slug: r.triggerQuestion.slug,
                    operator: r.operator,
                    value: r.triggerValue
                }));

                return {
                    id: q.slug,
                    text: q.text,
                    description: q.description,
                    type: q.inputType,
                    section_slug: q.section?.slug ?? null,
                    options: q.options.map((o: any) => ({ label: o.label, value: o.value })),
                    rules: q.prerequisites.map((p: any) => ({
                        trigger_slug: p.triggerQuestion.slug,
                        operator: p.operator,
                        value: p.triggerValue
                    })),
                    section_rules: sectionRules
                };
            })
        });
    } catch (e) {
        console.error(e);
        return json({ error: 'Internal Error' }, { status: 500 });
    }
}
