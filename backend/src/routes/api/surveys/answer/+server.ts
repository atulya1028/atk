import { json } from '@sveltejs/kit';
import { prisma } from '$lib/server/prisma';
import { getUserFromRequest } from '$lib/server/auth';
import type { RequestHandler } from './$types';

export const POST: RequestHandler = async ({ request }) => {
    const user = getUserFromRequest(request);
    if (!user) return json({ error: 'Unauthorized' }, { status: 401 });

    try {
        const { submission_id, question_slug, value } = await request.json();

        if (!submission_id || !question_slug) {
            return json({ error: 'Missing fields' }, { status: 400 });
        }

        const question = await prisma.question.findUnique({ where: { slug: question_slug } });
        if (!question) return json({ error: 'Question not found' }, { status: 404 });

        const submission = await prisma.submission.findUnique({ where: { id: Number(submission_id) } });
        if (!submission || submission.userId !== user.userId) {
            return json({ error: 'Submission invalid' }, { status: 403 });
        }

        const existing = await prisma.answer.findFirst({
            where: {
                submissionId: Number(submission_id),
                questionId: question.id
            }
        });

        await prisma.$transaction(async (tx: any) => {

            let valueString: string | null = null;
            let valueInt: number | null = null;
            let valueBool: boolean | null = null;
            let valueDec: number | null = null;
            let valueDate: Date | null = null;
            let legacyValueText: string | null = String(value);

            const snapshot = JSON.stringify({
                questionText: question.text,
                questionSlug: question.slug,
                inputType: question.inputType,
                answeredAt: new Date().toISOString()
            });

            switch (question.inputType) {
                case 'number':
                    const num = Number(value);
                    if (!isNaN(num)) {
                        if (Number.isInteger(num)) valueInt = num;
                        else valueDec = num;
                        legacyValueText = String(num);
                    }
                    break;
                case 'yesno':
                    valueBool = value === 'yes' || value === true;

                    legacyValueText = valueBool ? 'yes' : 'no';
                    break;
                case 'date':
                    const d = new Date(value);
                    if (!isNaN(d.getTime())) {
                        valueDate = d;
                        legacyValueText = d.toISOString().split('T')[0];
                    }
                    break;
                case 'select':
                case 'radio':
                    valueString = String(value);
                    break;
                case 'multi_select':

                    if (Array.isArray(value)) valueString = value.join(',');
                    else valueString = String(value);
                    break;
                default:

                    valueString = String(value);
            }

            const answerData = {
                submissionId: Number(submission_id),
                questionId: question.id,
                valueString,
                valueInt,
                valueBool,
                valueDec,
                valueDate,
                legacyValueText,
                snapshot
            };

            let answer;
            if (existing) {
                answer = await tx.answer.update({
                    where: { id: existing.id },
                    data: answerData
                });
            } else {
                answer = await tx.answer.create({
                    data: answerData
                });
            }

            if (['select', 'multi_select', 'yesno', 'radio'].includes(question.inputType)) {
                await tx.answerChoice.deleteMany({ where: { answerId: answer.id } });

                let values: string[] = [];
                if (Array.isArray(value)) values = value.map(String);
                else values = [String(value)];

                const options = await tx.option.findMany({
                    where: {
                        questionId: question.id,
                        value: { in: values }
                    }
                });

                if (options.length > 0) {
                    await tx.answerChoice.createMany({
                        data: options.map((o: any) => ({
                            answerId: answer.id,
                            questionOptionId: o.id
                        }))
                    });
                }
            }

            if (question.slug === 'gen_identifying_data_name' && valueString) {
                await tx.user.update({
                    where: { id: user.userId },
                    data: { name: valueString }
                });
            }
        });

        return json({ success: true });
    } catch (e) {
        console.error(e);
        return json({ error: 'Internal Error' }, { status: 500 });
    }
}
