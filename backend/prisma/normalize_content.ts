import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();

async function main() {
    console.log('Restructuring survey & generating missing content...');

    // 1. RE-SEQUENCING: Identifiers first
    const sectionUpdates = [
        { slug: 'gen_identifying_data_name', type: 'gen_identifying_data', sectionTitle: 'Identifying Data', order: 1 },
        { slug: 'gen_past_history', title: 'Personal & Psychiatric History', order: 2 },
        { slug: 'gen_family_history', title: 'Family History', order: 3 },
        { slug: 'gen_risk_assessment_screening', title: 'Risk Assessment', order: 4 },
    ];

    // Logic: Ideally we fetch all sections and re-sort them.
    // The original seed had "Identifying Data" at ID 2 (child of ID 2?).
    // Let's reset sortOrder for Top-Level sections.

    // Find "Identifying Data" Section
    // Note: The slug logic in original seed was implicit. We have Section titles.
    // Let's find by Title.
    const allSections = await prisma.section.findMany();

    const orderMap: Record<string, number> = {
        'Identifying Data': 1,
        'Personal & Psychiatric History': 2,
        'Family History': 3,
        'Past History': 4,
        'Psychosocial Stressors': 5,
        'Risk Behaviors & Coping Skills': 6,
        'Protective Factors': 7,
        'Substance Screening': 8 // This is usually "Past History -> Substance Use". We might need to make it prominent.
    };

    for (const s of allSections) {
        if (orderMap[s.title]) {
            await prisma.section.update({
                where: { id: s.id },
                data: { sortOrder: orderMap[s.title] }
            });
            console.log(`Updated order for ${s.title} to ${orderMap[s.title]}`);
        }
    }

    // 2. INJECT SAFETY SCREENING (Prevent Suicide Risk Gaps)
    // Create a new section "Safety Screening"
    let safetySection = await prisma.section.findUnique({ where: { slug: 'safety_screening' } });
    if (!safetySection) {
        safetySection = await prisma.section.create({
            data: {
                title: 'Safety Screening',
                slug: 'safety_screening',
                sectionType: 'safety',
                sortOrder: 11, // High priority visually
            }
        });
        console.log('Created Safety Screening Section');
    }

    // Add PHQ-9 Item 9 / Risk Questions
    const safetyQuestions = [
        {
            slug: 'safety_self_harm_thoughts',
            text: 'In the past 2 weeks, have you had thoughts that you would be better off dead or of hurting yourself?',
            inputType: 'yesno',
            isRequired: true
        },
        {
            slug: 'safety_suicidality_intent',
            text: 'Do you currently have any intent or plan to harm yourself?',
            inputType: 'yesno',
            isRequired: true,
            triggerSlug: 'safety_self_harm_thoughts',
            triggerVal: 'yes'
        }
    ];

    for (const sq of safetyQuestions) {
        const q = await prisma.question.upsert({
            where: { slug: sq.slug },
            update: {},
            create: {
                slug: sq.slug,
                text: sq.text,
                inputType: sq.inputType,
                isRequired: sq.isRequired,
                sectionId: safetySection.id,
                metadata: { flag_red: true }
            }
        });

        // Logic linking
        if (sq.triggerSlug) {
            const trigger = await prisma.question.findUnique({ where: { slug: sq.triggerSlug } });
            if (trigger) {
                await prisma.questionDependency.create({
                    data: {
                        dependentQuestionId: q.id,
                        triggerQuestionId: trigger.id,
                        operator: 'eq',
                        triggerValue: sq.triggerVal!
                    }
                });
            }
        }
    }

    // 3. GENERATE MISSING SUBSTANCE SECTIONS (Alcohol/Opioid)
    // We clone 'Benzodiazepine' structure.

    const benzoSection = await prisma.section.findFirst({
        where: { sectionType: 'benzodiazepine' },
        include: { questions: { include: { options: true } } }
    });

    if (benzoSection) {
        const substancesToClone = ['alcohol', 'opioid']; // Slugs for new sections

        for (const subst of substancesToClone) {
            const title = subst.charAt(0).toUpperCase() + subst.slice(1);
            const slugBase = `sub_${subst}`;

            // Create Parent Section
            let newSection = await prisma.section.findFirst({ where: { slug: `${slugBase}_main` } });
            if (!newSection) {
                newSection = await prisma.section.create({
                    data: {
                        title: `${title} History & Withdrawal`,
                        slug: `${slugBase}_main`,
                        sectionType: subst,
                        sortOrder: 50 // Later in list
                    }
                });
                console.log(`Created Section: ${title}`);
            }

            // Clone Questions
            for (const bQ of benzoSection.questions) {
                const newSlug = bQ.slug.replace('benzodiazepine', subst);

                // Avoid duplicate
                const exists = await prisma.question.findUnique({ where: { slug: newSlug } });
                if (exists) continue;

                const newText = bQ.text.replace(/benzodiazepine/gi, title)
                    .replace(/Xanax|Valium|Ativan/gi, (subst === 'alcohol' ? 'Beer/Wine/Spirits' : 'Heroin/Oxy/Fentanyl'));

                const newQ = await prisma.question.create({
                    data: {
                        slug: newSlug,
                        text: newText,
                        inputType: bQ.inputType,
                        isRequired: bQ.isRequired,
                        sectionId: newSection.id,
                        sortOrder: bQ.sortOrder,
                        metadata: bQ.metadata
                    }
                });

                // Clone Options
                if (bQ.options.length > 0) {
                    const newOptions = bQ.options.map(o => ({
                        questionId: newQ.id,
                        label: o.label.replace(/benzodiazepine/gi, title),
                        value: o.value, // Keep value codes same generally, or prefix? Standard codes often shared (yes/no/high/low)
                        scoreValue: o.scoreValue,
                        sortOrder: o.sortOrder
                    }));
                    await prisma.option.createMany({ data: newOptions });
                }

                // DEPENDENCY LINKING (The "Magic Link")
                // Link to the master screening question (QID 242 / or equivalent slug)
                // We need to find the master screening question.
                // Slug: 'substance_screening_which_substances' (from Survey Export)
                // The value for this substance is presumably the 'subst' string (alcohol, opioid).

                const masterScreening = await prisma.question.findUnique({ where: { slug: 'substance_screening_which_substances' } });
                if (masterScreening) {
                    await prisma.questionDependency.create({
                        data: {
                            dependentQuestionId: newQ.id,
                            triggerQuestionId: masterScreening.id,
                            operator: 'contains', // Multi-select contains
                            triggerValue: subst
                        }
                    });
                }
            }
            console.log(`Cloned ${benzoSection.questions.length} questions for ${title}`);
        }
    }

    console.log("Structure update complete.");
}

main()
    .catch(e => {
        console.error(e);
        process.exit(1);
    })
    .finally(async () => {
        await prisma.$disconnect();
    });
