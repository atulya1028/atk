
import { PrismaClient } from '@prisma/client';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const prisma = new PrismaClient();

// Manual mapping for dependencies (Logic Builder)
const TRIGGER_MAPPING: Record<string, number> = {
    "Gender": 2,
    "Past substance use?": 36,
    "Recently reduced or stopped drinking": 52,
    "Withdrawal symptoms": 62,
    "Ever needed medical help": 58,
    "Past treatment for substance use?": 82
};

// Section Definitions (Question IDs)
const SECTIONS = [
    {
        title: "Demographics & Personal Details",
        slug: "demographics",
        ids: [1, 2, 3, 4, 5, 6, 25, 26, 39, 40]
    },
    {
        title: "Social History & Lifestyle",
        slug: "social-history",
        ids: [7, 8, 9, 12, 13, 14, 15, 16, 23, 24, 27, 28, 29, 41, 42, 43, 44]
    },
    {
        title: "Medical & Psychiatric History",
        slug: "medical-psych-history",
        ids: [10, 11, 17, 18, 19, 20, 21, 22, 30, 31, 32, 33, 34, 35, 38, 94]
    },
    {
        title: "Mental State Examination (MSE)",
        slug: "mse",
        ids: [45, 46, 47, 48, 49, 50, 51]
    },
    {
        title: "Substance Use & Withdrawal",
        slug: "substance-use",
        ids: [
            36, 37,
            52, 53, 54, 55, 56, 57, 58,
            59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82,
            83, 84, 85, 86, 87, 88,
            91, 92, 93, 95, 98, 99
        ]
    },
    {
        title: "Risk Assessment",
        slug: "risk-assessment",
        ids: [89, 90, 96, 97]
    }
];

// Helper to generate slug
function generateSlug(text: string): string {
    return text
        .toLowerCase()
        .replace(/[^\w\s-]/g, '')
        .replace(/\s+/g, '-')
        .replace(/--+/g, '-')
        .trim()
        .slice(0, 50);
}

function parseOptions(optionsStr: string): { label: string; value: string; }[] {
    if (!optionsStr) return [];
    const cleanStr = optionsStr.replace(/\\n/g, '\n');
    if (cleanStr.toLowerCase().includes('numeric') || cleanStr.toLowerCase().includes('1-10 scale') || cleanStr.toLowerCase().includes('units/')) {
        return [];
    }
    const lines = cleanStr.split('\n').map(l => l.trim()).filter(l => l.startsWith('-'));
    return lines.map(line => {
        const text = line.replace(/^-\s*/, '').trim();
        return { label: text, value: text };
    });
}

function inferInputType(optionsStr: string): string {
    const lower = optionsStr.toLowerCase();
    if (lower.includes('numeric') || lower.includes('units/')) return 'number';
    if (lower.includes('1-10 scale')) return 'number';
    return 'select';
}

async function main() {
    console.log('Starting DB flush and import, removing empty General Assessment...');

    // 1. Flush Database
    console.log('Flushing existing data...');
    await prisma.answerChoice.deleteMany({});
    await prisma.answer.deleteMany({});
    await prisma.submission.deleteMany({});
    await prisma.questionDependency.deleteMany({});
    await prisma.option.deleteMany({});
    await prisma.question.deleteMany({});
    await prisma.section.deleteMany({});

    console.log('Data flushed.');

    // 2. Create Sections Logic
    const masterRoot = await prisma.section.create({
        data: {
            title: 'Clinical Interview',
            slug: 'clinical-interview',
            sortOrder: 0,
            sectionType: 'general'
        }
    });

    const sectionMap = new Map<string, number>(); // slug -> ID

    // Helper index for sorting
    let sectionIndex = 1;

    for (const sect of SECTIONS) {
        const s = await prisma.section.create({
            data: {
                title: sect.title,
                slug: sect.slug,
                sortOrder: sectionIndex * 10,
                sectionType: 'general',
                parentId: masterRoot.id
            }
        });
        sectionMap.set(sect.slug, s.id);
        sectionIndex++;
    }

    // 3. Load JSON
    const jsonPath = path.join(__dirname, '../data_source/questions.json');
    const rawData = fs.readFileSync(jsonPath, 'utf-8');
    const questionsData = JSON.parse(rawData);

    // 4. Import Questions
    const questionIdMap = new Map<number, number>();

    console.log(`Importing ${questionsData.length} questions...`);

    for (const item of questionsData) {
        const originalId = item['#'];
        const text = item['Question'];
        const optionsStr = item['Answer options'];

        // Find Section
        let targetSectionId: number | undefined;
        for (const sect of SECTIONS) {
            if (sect.ids.includes(originalId)) {
                targetSectionId = sectionMap.get(sect.slug);
                break;
            }
        }

        if (!targetSectionId) {
            console.warn(`Warning: Question #${originalId} has no assigned section. Defaulting to 'Demographics'.`);
            targetSectionId = sectionMap.get('demographics');

            // Safety check if demographics is somehow missing (unlikely)
            if (!targetSectionId) {
                throw new Error("Critical: 'Demographics' section not found.");
            }
        }

        const inputType = inferInputType(optionsStr);
        const options = parseOptions(optionsStr);

        let slug = generateSlug(text);
        const existingSlug = await prisma.question.findUnique({ where: { slug } });
        if (existingSlug) {
            slug = `${slug}-${originalId}`;
        }

        const question = await prisma.question.create({
            data: {
                text: text,
                slug: slug,
                inputType: inputType,
                sortOrder: originalId,
                sectionId: targetSectionId,
                options: {
                    create: options.map((opt, idx) => ({
                        label: opt.label,
                        value: opt.value,
                        sortOrder: idx
                    }))
                }
            }
        });

        questionIdMap.set(originalId, question.id);
    }

    // 5. Build Dependencies
    console.log('Building dependencies...');

    for (const item of questionsData) {
        const originalId = item['#'];
        const logicStr = item['Logic Builder'];
        const dbId = questionIdMap.get(originalId);

        if (!dbId || !logicStr || logicStr === 'Always show') continue;

        const lines = logicStr.split('\n');
        let triggerKey = '';
        let triggerValue = '';

        for (const line of lines) {
            if (line.trim().startsWith('-')) {
                const parts = line.replace(/^-\s*/, '').split('=');
                if (parts.length >= 2) {
                    triggerKey = parts[0].trim();
                    triggerValue = parts[1].trim();
                    break;
                }
            }
        }

        if (triggerKey && triggerValue) {
            let triggerQId: number | undefined;
            const mappedOriginalId = TRIGGER_MAPPING[triggerKey];
            if (mappedOriginalId) {
                triggerQId = questionIdMap.get(mappedOriginalId);
            }

            if (triggerQId) {
                await prisma.questionDependency.create({
                    data: {
                        dependentQuestionId: dbId,
                        triggerQuestionId: triggerQId,
                        operator: 'eq',
                        triggerValue: triggerValue
                    }
                });
            }
        }
    }

    console.log('Import completed successfully.');
}

main()
    .catch((e) => {
        console.error(e);
        process.exit(1);
    })
    .finally(async () => {
        await prisma.$disconnect();
    });
