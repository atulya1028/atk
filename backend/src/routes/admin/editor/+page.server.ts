import { prisma } from '$lib/server/prisma';
import { logAdminAction } from '$lib/server/audit';
import type { PageServerLoad, RequestEvent } from './$types';
import { getDefaultEmailTemplate } from '$lib/server/defaultTemplates';

export const load: PageServerLoad = async ({ url }) => {
    const surveyCategory = (url.searchParams.get('surveyCategory') || 'ADDICTION').toUpperCase();

    const sections = await prisma.section.findMany({
        where: { surveyCategory },
        orderBy: { sortOrder: 'asc' },
        include: {
            parent: true,
            displayRules: true,
            questions: {
                orderBy: { sortOrder: 'asc' },
                include: {
                    options: { orderBy: { sortOrder: 'asc' } },
                    prerequisites: true
                }
            }
        }
    });

    const settings = await prisma.surveySettings.findUnique({
        where: { surveyCategory },
        include: { emailTemplate: true }
    });

    const defaultTemplate = getDefaultEmailTemplate(surveyCategory);
    let emailTemplateVal = null;
    if (settings && settings.emailTemplate) {
        emailTemplateVal = settings.emailTemplate;
    } else {
        emailTemplateVal = {
            subject: defaultTemplate.subject,
            bodyHtml: defaultTemplate.bodyHtml,
            bodyText: defaultTemplate.bodyText
        };
    }

    const settingsPayload = settings ? JSON.parse(JSON.stringify(settings)) : { threshold: 30, criticalValue: 50 };
    settingsPayload.emailTemplate = emailTemplateVal;

    return {
        sections: JSON.parse(JSON.stringify(sections)),
        surveyCategory,
        settings: settingsPayload
    };
};

export const actions = {
    updateQuestion: async ({ request }: RequestEvent) => {
        const data = await request.formData();
        const id = Number(data.get('id'));
        const text = String(data.get('text'));
        let slug = String(data.get('slug') || '').trim();
        const inputType = String(data.get('inputType') || 'select');


        const isRequired = data.get('isRequired') === 'on';
        const metadata = String(data.get('metadata') || '{}');
        const optionsRaw = JSON.parse(String(data.get('options') || '[]'));
        const rules = JSON.parse(String(data.get('rules') || '[]'));

        if (!slug) {
            slug = text.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)/g, '') || `q-${Date.now()}`;
        }

        const options = optionsRaw.map((opt: any, i: number) => {
            const safeLabel = opt.label || `Option ${i + 1}`;
            return {
                label: safeLabel,
                value: opt.value || safeLabel.toLowerCase().replace(/[^a-z0-9]+/g, '_').replace(/(^_|_$)/g, ''),
                scoreValue: Number(opt.scoreValue || 0),
                sortOrder: opt.sortOrder !== undefined ? opt.sortOrder : i * 10
            };
        });


        const oldQuestion = await prisma.question.findUnique({
            where: { id },
            include: {
                options: { orderBy: { sortOrder: 'asc' } },
                prerequisites: { orderBy: { id: 'asc' } }
            }
        });

        const changes: string[] = [];
        if (oldQuestion) {
            if (oldQuestion.text !== text) {
                changes.push(`text from "${oldQuestion.text}" to "${text}"`);
            }
            if (oldQuestion.isRequired !== isRequired) {
                changes.push(`required status from ${oldQuestion.isRequired} to ${isRequired}`);
            }
            const oldOptsStr = oldQuestion.options.map((o: any) => `${o.label} (${o.scoreValue} pts)`).join(', ');
            const newOptsStr = options.map((o: any) => `${o.label} (${o.scoreValue} pts)`).join(', ');
            if (oldOptsStr !== newOptsStr) {
                changes.push(`options from [${oldOptsStr}] to [${newOptsStr}]`);
            }
            const oldRulesStr = oldQuestion.prerequisites.map((r: any) => `Show if question ID ${r.triggerQuestionId} ${r.operator} "${r.triggerValue}"`).join(', ');
            const newRulesStr = rules.filter((r: any) => r.triggerQuestionId).map((r: any) => `Show if question ID ${r.triggerQuestionId} ${r.operator || 'eq'} "${r.triggerValue}"`).join(', ');
            if (oldRulesStr !== newRulesStr) {
                changes.push(`display logic rules from [${oldRulesStr || 'None'}] to [${newRulesStr || 'None'}]`);
            }
        }

        await prisma.$transaction(async (tx: any) => {

            await tx.question.update({
                where: { id },
                data: { text, slug, inputType, isRequired, metadata }
            });

            await tx.option.deleteMany({ where: { questionId: id } });
            if (options.length > 0) {
                await tx.option.createMany({
                    data: options.map((opt: any, i: number) => ({
                        questionId: id,
                        label: opt.label,
                        value: opt.value,
                        scoreValue: opt.scoreValue,
                        sortOrder: i * 10
                    }))
                });
            }

            await tx.displayRule.deleteMany({ where: { dependentQuestionId: id } });
            for (const r of rules) {
                if (r.triggerQuestionId) {
                    await tx.displayRule.create({
                        data: {
                            dependentQuestionId: id,
                            triggerQuestionId: Number(r.triggerQuestionId),
                            operator: r.operator || 'eq',
                            triggerValue: String(r.triggerValue)
                        }
                    });
                }
            }
        });

        const changesStr = changes.length > 0 ? changes.join('; ') : 'No text/options changes';
        await logAdminAction('UPDATE_QUESTION', `Updated question "${slug}" (ID: ${id}) details: ${changesStr}`);

        return { success: true };
    },

    createQuestion: async ({ request }: RequestEvent) => {
        const data = await request.formData();
        const sectionId = Number(data.get('sectionId'));
        const text = String(data.get('text'));
        let slug = String(data.get('slug') || '').trim();
        const inputType = String(data.get('inputType') || 'select');


        const isRequired = data.get('isRequired') === 'on';
        const metadata = String(data.get('metadata') || '{}');
        const optionsRaw = JSON.parse(String(data.get('options') || '[]'));
        const rules = JSON.parse(String(data.get('rules') || '[]'));

        if (!slug) {
            slug = text.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)/g, '');
            if (!slug) slug = `q-${Date.now()}`;

            let uniqueSlug = slug;
            let counter = 1;
            while (await prisma.question.findUnique({ where: { slug: uniqueSlug } })) {
                uniqueSlug = `${slug}-${counter}`;
                counter++;
            }
            slug = uniqueSlug;
        }

        const options = optionsRaw.map((opt: any) => ({
            label: opt.label,
            value: opt.value || opt.label.toLowerCase().replace(/[^a-z0-9]+/g, '_').replace(/(^_|_$)/g, ''),
            scoreValue: Number(opt.scoreValue || 0),
            sortOrder: opt.sortOrder
        }));


        const lastQ = await prisma.question.findFirst({
            where: { sectionId },
            orderBy: { sortOrder: 'desc' }
        });
        const sortOrder = (lastQ?.sortOrder || 0) + 10;

        const newQ = await prisma.question.create({
            data: { sectionId, text, slug, inputType, sortOrder, isRequired, metadata }
        });

        if (options.length > 0 || rules.length > 0) {
            await prisma.$transaction(async (tx: any) => {
                if (options.length > 0) {
                    await tx.option.createMany({
                        data: options.map((opt: any, i: number) => ({
                            questionId: newQ.id,
                            label: opt.label,
                            value: opt.value,
                            scoreValue: opt.scoreValue,
                            sortOrder: i * 10
                        }))
                    });
                }

                for (const r of rules) {
                    if (r.triggerQuestionId) {
                        await tx.displayRule.create({
                            data: {
                                dependentQuestionId: newQ.id,
                                triggerQuestionId: Number(r.triggerQuestionId),
                                operator: r.operator || 'eq',
                                triggerValue: String(r.triggerValue)
                            }
                        });
                    }
                }
            });
        }

        await logAdminAction('CREATE_QUESTION', `Created new question "${text}" in section ID: ${sectionId} (slug: ${slug})`);

        return { success: true };
    },

    deleteQuestion: async ({ request }: RequestEvent) => {
        const data = await request.formData();
        const id = Number(data.get('id'));
        const q = await prisma.question.findUnique({ where: { id }, select: { text: true } });
        await prisma.question.delete({ where: { id } });
        await logAdminAction('DELETE_QUESTION', `Deleted question ID: ${id} ("${q?.text || 'Unknown'}")`);
        return { success: true };
    },

    reorderQuestions: async ({ request }: RequestEvent) => {
        const data = await request.formData();
        const updates = JSON.parse(String(data.get('updates')));

        await prisma.$transaction(
            updates.map((u: { id: number, sortOrder: number }) =>
                prisma.question.update({
                    where: { id: u.id },
                    data: { sortOrder: u.sortOrder }
                })
            )
        );

        return { success: true };
    },

    addDependency: async ({ request }: RequestEvent) => {
        const data = await request.formData();
        const dependentQuestionId = Number(data.get('dependentQuestionId'));
        const triggerQuestionId = Number(data.get('triggerQuestionId'));
        const operator = String(data.get('operator'));
        const triggerValue = String(data.get('triggerValue'));

        await prisma.questionDependency.create({
            data: { dependentQuestionId, triggerQuestionId, operator, triggerValue }
        });

        return { success: true };
    },

    deleteDependency: async ({ request }: RequestEvent) => {
        const data = await request.formData();
        const id = Number(data.get('id'));
        await prisma.questionDependency.delete({ where: { id } });
        return { success: true };
    },

    updateLogic: async ({ request }: RequestEvent) => {
        const data = await request.formData();
        const questionId = Number(data.get('questionId'));
        const rulesJson = String(data.get('rules'));
        const rules = JSON.parse(rulesJson);

        await prisma.$transaction([
            prisma.displayRule.deleteMany({
                where: { dependentQuestionId: questionId }
            }),
            ...rules.map((r: any) => prisma.displayRule.create({
                data: {
                    dependentQuestionId: questionId,
                    triggerQuestionId: Number(r.triggerQuestionId),
                    operator: r.operator,
                    triggerValue: String(r.triggerValue)
                }
            }))
        ]);

        await logAdminAction('UPDATE_LOGIC', `Updated show/hide prerequisite rules for question ID: ${questionId}`);

        return { success: true };
    },

    updateOptions: async ({ request }: RequestEvent) => {
        const data = await request.formData();
        const questionId = Number(data.get('questionId'));
        const optionsJson = String(data.get('options'));
        const options = JSON.parse(optionsJson);

        await prisma.$transaction([
            prisma.option.deleteMany({
                where: { questionId }
            }),
            ...options.map((opt: any, i: number) => prisma.option.create({
                data: {
                    questionId,
                    label: opt.label,
                    value: opt.value,
                    sortOrder: i * 10
                }
            }))
        ]);

        return { success: true };
    },

    createSection: async ({ request }: RequestEvent) => {
        const data = await request.formData();
        const title = String(data.get('title'));
        const sectionType = String(data.get('sectionType') || 'general');
        const surveyType = String(data.get('surveyType') || 'INITIAL');
        const parentId = data.get('parentId') ? Number(data.get('parentId')) : null;

        let slug = title.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)/g, '');
        if (!slug) slug = `section-${Date.now()}`;

        let uniqueSlug = slug;
        let counter = 1;
        while (await prisma.section.findUnique({ where: { slug: uniqueSlug } })) {
            uniqueSlug = `${slug}-${counter}`;
            counter++;
        }
        slug = uniqueSlug;

        const lastSection = await prisma.section.findFirst({
            where: { parentId },
            orderBy: { sortOrder: 'desc' }
        });
        const sortOrder = (lastSection?.sortOrder || 0) + 10;

        const surveyCategory = String(data.get('surveyCategory') || 'ADDICTION').toUpperCase();

        await prisma.section.create({
            data: { title, slug, sectionType, surveyType, parentId, sortOrder, surveyCategory }
        });

        await logAdminAction('CREATE_SECTION', `Created section "${title}" for category: ${surveyCategory} (${surveyType})`);

        return { success: true };
    },

    deleteSection: async ({ request }: RequestEvent) => {
        const data = await request.formData();
        const id = Number(data.get('id'));

        const sec = await prisma.section.findUnique({ where: { id }, select: { title: true } });
        await prisma.section.delete({
            where: { id }
        });

        await logAdminAction('DELETE_SECTION', `Deleted section "${sec?.title || 'Unknown'}" (ID: ${id})`);

        return { success: true };
    },

    updateSection: async ({ request }: RequestEvent) => {
        const data = await request.formData();
        const id = Number(data.get('id'));
        const title = String(data.get('title'));
        const surveyType = String(data.get('surveyType'));
        const sectionType = String(data.get('sectionType') || 'general');
        const surveyCategory = String(data.get('surveyCategory') || 'ADDICTION').toUpperCase();

        const rulesJson = data.get('sectionRules');
        let rules: any[] = [];
        if (rulesJson !== null) {
            try {
                rules = JSON.parse(String(rulesJson));
            } catch (_) {}
        }

        const oldSection = await prisma.section.findUnique({
            where: { id },
            include: { displayRules: { orderBy: { id: 'asc' } } }
        });

        const changes: string[] = [];
        if (oldSection) {
            if (oldSection.title !== title) {
                changes.push(`title from "${oldSection.title}" to "${title}"`);
            }
            if (oldSection.surveyType !== surveyType) {
                changes.push(`survey stage from ${oldSection.surveyType} to ${surveyType}`);
            }
            if (oldSection.sectionType !== sectionType) {
                changes.push(`section type from ${oldSection.sectionType} to ${sectionType}`);
            }
            if (oldSection.surveyCategory !== surveyCategory) {
                changes.push(`category from ${oldSection.surveyCategory} to ${surveyCategory}`);
            }

            const oldRulesStr = oldSection.displayRules.map((r: any) => `Show if question ID ${r.triggerQuestionId} ${r.operator} "${r.triggerValue}"`).join(', ');
            const newRulesStr = rules.filter((r: any) => r.triggerQuestionId).map((r: any) => `Show if question ID ${r.triggerQuestionId} ${r.operator || 'eq'} "${r.triggerValue}"`).join(', ');
            if (oldRulesStr !== newRulesStr) {
                changes.push(`display logic rules from [${oldRulesStr || 'None'}] to [${newRulesStr || 'None'}]`);
            }
        }

        await prisma.$transaction(async (tx: any) => {
            await tx.section.update({
                where: { id },
                data: { title, surveyType, sectionType, surveyCategory }
            });

            // Re-create display rules for the section
            await tx.displayRule.deleteMany({
                where: { dependentSectionId: id }
            });

            for (const r of rules) {
                if (r.triggerQuestionId) {
                    await tx.displayRule.create({
                        data: {
                            dependentSectionId: id,
                            triggerQuestionId: Number(r.triggerQuestionId),
                            operator: r.operator || 'eq',
                            triggerValue: String(r.triggerValue)
                        }
                    });
                }
            }
        });

        const changesStr = changes.length > 0 ? changes.join('; ') : 'No settings/logic changes';
        await logAdminAction('UPDATE_SECTION', `Updated section "${title}" (ID: ${id}) details: ${changesStr}`);

        return { success: true };
    },

    updateSettings: async ({ request }: RequestEvent) => {
        const data = await request.formData();
        const surveyCategory = String(data.get('surveyCategory')).toUpperCase();
        const threshold = Number(data.get('threshold'));
        const criticalValue = Number(data.get('criticalValue'));

        const oldSettings = await prisma.surveySettings.findUnique({ where: { surveyCategory } });

        await prisma.surveySettings.upsert({
            where: { surveyCategory },
            update: { threshold, criticalValue },
            create: { surveyCategory, threshold, criticalValue }
        });

        if (!oldSettings || oldSettings.threshold !== threshold) {
            await logAdminAction('UPDATE_SETTINGS_THRESHOLD', `Updated threshold for ${surveyCategory} from ${oldSettings?.threshold ?? 30} to ${threshold}`);
        }
        if (!oldSettings || oldSettings.criticalValue !== criticalValue) {
            await logAdminAction('UPDATE_SETTINGS_CRITICAL', `Updated Critical Value for ${surveyCategory} from ${oldSettings?.criticalValue ?? 50} to ${criticalValue}`);
        }

        return { success: true };
    },

    updateEmailTemplate: async ({ request }: RequestEvent) => {
        const data = await request.formData();
        const surveyCategory = String(data.get('surveyCategory')).toUpperCase();
        const subject = String(data.get('subject') || '').trim();
        const bodyHtml = String(data.get('bodyHtml') || '').trim();
        const bodyText = String(data.get('bodyText') || '').trim();

        let settings = await prisma.surveySettings.findUnique({
            where: { surveyCategory }
        });

        if (!settings) {
            settings = await prisma.surveySettings.create({
                data: {
                    surveyCategory,
                    threshold: 30,
                    criticalValue: 50
                }
            });
        }

        // Detect if subject or body content is empty / blank
        // (contenteditable editor leaves minor wraps like <p><br></p>)
        const strippedHtml = bodyHtml.replace(/<[^>]*>/g, '').trim();
        const isEmptyHtml = !bodyHtml || bodyHtml === '<p><br></p>' || bodyHtml === '<br>' || bodyHtml === '<p></p>' || strippedHtml === '';
        const isEmptySubject = !subject;

        if (isEmptyHtml || isEmptySubject) {
            // Delete custom template so system automatically falls back to default template
            await prisma.emailTemplate.deleteMany({
                where: { surveySettingsId: settings.id }
            });
            await logAdminAction('UPDATE_SETTINGS_EMAIL_TEMPLATE', `Reverted follow-up email template for ${surveyCategory} to default settings.`);
            
            // Get default values to return
            const defaultTemplate = getDefaultEmailTemplate(surveyCategory);
            return {
                success: true,
                reverted: true,
                defaultTemplate: {
                    subject: defaultTemplate.subject,
                    bodyHtml: defaultTemplate.bodyHtml,
                    bodyText: defaultTemplate.bodyText
                }
            };
        }

        const oldTemplate = await prisma.emailTemplate.findUnique({
            where: { surveySettingsId: settings.id }
        });

        await prisma.emailTemplate.upsert({
            where: { surveySettingsId: settings.id },
            update: { subject, bodyHtml, bodyText },
            create: { surveySettingsId: settings.id, subject, bodyHtml, bodyText }
        });

        const changes: string[] = [];
        if (!oldTemplate) {
            changes.push(`Created template with subject: "${subject}"`);
        } else {
            if (oldTemplate.subject !== subject) {
                changes.push(`subject from "${oldTemplate.subject}" to "${subject}"`);
            }
            if (oldTemplate.bodyHtml !== bodyHtml) {
                changes.push('updated email body text & visual layout');
            }
        }

        const changesStr = changes.length > 0 ? changes.join('; ') : 'No template changes';
        await logAdminAction('UPDATE_SETTINGS_EMAIL_TEMPLATE', `Updated follow-up email template for ${surveyCategory}: ${changesStr}`);

        return { success: true };
    }

};
