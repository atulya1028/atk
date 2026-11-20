import { PrismaClient } from '@prisma/client';
import fs from 'fs/promises';

const prisma = new PrismaClient();

async function main() {
    console.log("Fetching survey structure...");

    const sections = await prisma.section.findMany({
        orderBy: { sortOrder: 'asc' },
        include: {
            questions: {
                orderBy: { sortOrder: 'asc' },
                include: {
                    options: { orderBy: { sortOrder: 'asc' } },
                    dependentRules: true, // Rules where THIS question triggers others
                    prerequisites: true,   // Rules that trigger THIS question
                }
            }
        }
    });

    let output = "# Clinical Survey Analysis Report\n\n";

    for (const section of sections) {
        output += `## Section: ${section.title} (Type: ${section.sectionType})\n`;
        if (section.parentId) output += `   (Child of Section ID: ${section.parentId})\n`;

        for (const q of section.questions) {
            output += `\n### [${q.slug}] ${q.text}\n`;
            output += `   - Type: **${q.inputType}** | Required: ${q.isRequired}\n`;

            if (q.description) output += `   - Note: _${q.description}_\n`;

            // Options
            if (q.options.length > 0) {
                output += `   - **Options**:\n`;
                q.options.forEach(o => {
                    output += `     - [${o.value}] ${o.label}\n`;
                });
            }

            // Logic (Prerequisites - When is this shown?)
            if (q.prerequisites.length > 0) {
                output += `   - **Logic (Shown If)**:\n`;
                for (const rule of q.prerequisites) {
                    output += `     - Trigger QID ${rule.triggerQuestionId} ${rule.operator} '${rule.triggerValue}'\n`;
                }
            }
        }
        output += "\n---\n";
    }

    await fs.writeFile('survey_export.md', output);
    console.log("Analysis exported to survey_export.md");
}

main()
    .catch(console.error)
    .finally(async () => await prisma.$disconnect());
