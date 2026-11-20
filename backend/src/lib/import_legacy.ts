import { prisma } from './server/prisma';
import fs from 'fs';
import path from 'path';

const seederPath = path.resolve('../server/database/seeders/GeneratedQuestionSeeder.php');

async function main() {
    console.log(`Reading legacy seeder from: ${seederPath}`);

    if (!fs.existsSync(seederPath)) {
        console.error("Seeder file not found!");
        process.exit(1);
    }

    const content = fs.readFileSync(seederPath, 'utf8');

    function extractArray(name: string): string {
        const startMarker = `$${name} = [`;
        const startIndex = content.indexOf(startMarker);
        if (startIndex === -1) return '[]';

        let openBrackets = 1;
        let currentIndex = startIndex + startMarker.length;
        let extracted = '[';

        while (openBrackets > 0 && currentIndex < content.length) {
            const char = content[currentIndex];
            extracted += char;
            if (char === '[') openBrackets++;
            if (char === ']') openBrackets--;
            currentIndex++;
        }

        return extracted;
    }

    function phpArrayToJson(phpStr: string) {
        let jsonStr = phpStr;

        jsonStr = jsonStr.replace(/'([\w_]+)'\s*=>/g, '"$1":');

        jsonStr = jsonStr.replace(/:\s*'([^']*)'/g, ': "$1"');

        // 3. Handle NULL
        jsonStr = jsonStr.replace(/=>\s*NULL/g, ': null');
        jsonStr = jsonStr.replace(/:\s*NULL/g, ': null');

        // 4. Handle true/false
        jsonStr = jsonStr.replace(/=>\s*true/g, ': true');
        jsonStr = jsonStr.replace(/:\s*true/g, ': true');
        jsonStr = jsonStr.replace(/=>\s*false/g, ': false');
        jsonStr = jsonStr.replace(/:\s*false/g, ': false');

        // 5. Convert PHP array brackets [] to JSON objects {}
        // In this file, all inner [ ... ] are objects. 
        // The outer one is a list.
        // Any [ that is preceded by : or => or , or start is likely an object start if it contains keys.
        // The file format is predictable:
        // [
        //    [ 'id' => 1 ... ],
        // ]

        // Strategy:
        // Replace current outer [ ] with [ ] (keep).
        // Replace inner [ ] with { }.

        // Actually, simple regex replacement of [ to { isn't context aware.

        jsonStr = jsonStr.replace(/\[\s*"/g, '{ "');

        // And `]` followed by comma is `}`.
        jsonStr = jsonStr.replace(/\s*\]\s*,/g, ' },');

        // The last one `]`, usually ends the array.
        // jsonStr = jsonStr.replace(/\s*\]\s*$/, ' }'); // No, outer is array.

        // Fix trailing commas
        jsonStr = jsonStr.replace(/,\s*}/g, '}');
        jsonStr = jsonStr.replace(/,\s*]/g, ']');

        // Fix the very end (outer array close)
        // The loop above might have turned the outer `[` into `{` if it matched `["`.
        // The outer array starts with `[`. The first element starts with `[`.
        // in PHP: $x = [ [ ... ] ];
        // My extraction included the first `[`.

        // Let's rely on `eval` of a JS object if we convert properly? Dangerous but effective for local script.

        return jsonStr;
    }

    const createJson = (text: string) => {

        text = text.replace(/\/\*[\s\S]*?\*\/|([^\\:]|^)\/\/.*$/gm, '$1');

        let result = text
            .replace(/'/g, '"') // Replace all single quotes with double
            .replace(/=>/g, ':') // Replace arrows
            .replace(/NULL/g, 'null')
            // Convert [ ... ] to { ... } ONLY if it looks like an object (has keys)
            // But here inner arrays are ALWAYS objects.
            // convert `[` to `{` everywhere, except the FIRST one and LAST one?
            // Wait, options might be simple arrays? No, structured.

            // Let's try simple text replacement suitable for this specific file.
            // Items are: [ "id": 1, ... ]
            .replace(/\[/g, '{')
            .replace(/\]/g, '}')
            // Fix outer array which should be []
            .replace(/^\s*{/, '[')
            .replace(/}\s*$/, ']')
            // Fix trailing comma before closing brace
            .replace(/,(\s*[\}\]])/g, '$1');

        return JSON.parse(result);
    };

    try {
        console.log("Parsing Sections...");
        const sectionsStr = extractArray('sections');
        const sections = createJson(sectionsStr);
        console.log(`Found ${sections.length} sections.`);

        console.log("Parsing Questions...");
        const questionsStr = extractArray('questions');
        const questions = createJson(questionsStr);
        console.log(`Found ${questions.length} questions.`);

        console.log("Parsing Options...");
        const optionsStr = extractArray('options');
        const options = createJson(optionsStr);
        console.log(`Found ${options.length} options.`);

        console.log("Parsing Dependencies...");
        const dependenciesStr = extractArray('dependencies');
        const dependencies = createJson(dependenciesStr);
        console.log(`Found ${dependencies.length} dependencies.`);

        // Database Injection
        console.log("Starting Database Seed...");

        // 1. Sections - RESET Strategy
        console.log("Clearing Sections/Questions for strict sync...");
        await prisma.answerChoice.deleteMany();
        await prisma.answer.deleteMany();
        await prisma.submission.deleteMany(); // Cascade usually handles it but safe to be explicit
        await prisma.questionDependency.deleteMany();
        await prisma.option.deleteMany();
        await prisma.question.deleteMany();
        await prisma.section.deleteMany();

        await prisma.section.createMany({
            data: sections.map((s: any) => ({
                id: s.id,
                slug: s.slug,
                title: s.title,
                sectionType: s.section_type,
                sortOrder: s.sort_order,
                parentId: s.parent_id
            }))
        });
        console.log("Done: Sections synced.");

        // 2. Questions
        await prisma.question.createMany({
            data: questions.map((q: any) => ({
                id: q.id,
                slug: q.slug,
                text: q.text,
                description: q.description,
                inputType: q.input_type,
                isRequired: Boolean(q.is_required),
                sortOrder: q.sort_order,
                sectionId: q.section_id,
                parentQuestionId: q.parent_question_id
            }))
        });
        console.log("Done: Questions synced.");

        // 3. Options
        // Strategy: Delete existing options for these questions and recreate to ensure order/sync?
        // Or upsert by ID if provided (options don't have explicit IDs in some seeders, but here they might generated or implied).
        // The extracted array generally doesn't have 'id' for options in the seed file (usually).
        // Let's check the view... 'question_id', 'label', 'value'... no ID in the php array shown.
        // So we should delete info and re-insert or carefully sync.
        // Upserting options is hard without unique ID.
        // Bulk delete all options? Risky if new data exists.
        // Better: Delete options where question_id is in our list.

        console.log("Syncing Options (CLEARING & RE-INSERTING for safety)...");
        await prisma.option.deleteMany({}); // FULL RESET of options (safe for seed)
        /*
        To be safer: 
        const questionIds = options.map(o => o.question_id);
        await prisma.option.deleteMany({ where: { questionId: { in: questionIds } } });
        */

        await prisma.option.createMany({
            data: options.map((o: any) => ({
                questionId: o.question_id,
                label: o.label,
                value: o.value,
                category: o.category,
                sortOrder: o.sort_order
            }))
        });
        console.log("Done: Options synced.");

        // 4. Dependencies
        console.log("Syncing Dependencies...");
        await prisma.questionDependency.deleteMany({});
        await prisma.questionDependency.createMany({
            data: dependencies.map((d: any) => ({
                dependentQuestionId: d.dependent_question_id,
                triggerQuestionId: d.trigger_question_id,
                operator: d.operator,
                triggerValue: d.trigger_value
            }))
        });
        console.log("Done: Dependencies synced.");

    } catch (e) {
        console.error("Error during migration:", e);
        process.exit(1);
    }
}

main()
    .then(async () => {
        await prisma.$disconnect()
    })
    .catch(async (e) => {
        console.error(e)
        await prisma.$disconnect()
        process.exit(1)
    })
