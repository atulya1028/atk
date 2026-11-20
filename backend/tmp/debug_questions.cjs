const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
    try {
        const qIds = [219, 220];
        const questions = await prisma.question.findMany({
            where: { id: { in: qIds } },
            include: { section: true }
        });
        console.log('--- Questions 219 & 220 ---');
        console.log(JSON.stringify(questions, null, 2));

        const sections = await prisma.section.findMany({
            orderBy: { sortOrder: 'asc' },
            select: { id: true, title: true, sortOrder: true, surveyType: true }
        });
        console.log('\n--- Sections ---');
        console.log(JSON.stringify(sections, null, 2));

        const initialQuestions = await prisma.question.findMany({
            where: { section: { surveyType: 'INITIAL' } },
            orderBy: [
                { section: { sortOrder: 'asc' } },
                { sortOrder: 'asc' }
            ],
            select: {
                id: true,
                slug: true,
                text: true,
                sortOrder: true,
                section: { select: { id: true, title: true, sortOrder: true } }
            }
        });
        console.log('\n--- INITIAL Survey Questions (Ordered by Section then Question) ---');
        console.log(JSON.stringify(initialQuestions, null, 2));
    } catch (err) {
        console.error(err);
    } finally {
        await prisma.$disconnect();
    }
}

main();
