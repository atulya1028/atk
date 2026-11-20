const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
    try {
        const qIds = [219, 220];
        const questions = await prisma.question.findMany({
            where: { id: { in: qIds } },
            include: {
                section: true,
                prerequisites: {
                    include: { triggerQuestion: true }
                }
            }
        });
        console.log('--- Questions 219 & 220 with Prerequisites ---');
        console.log(JSON.stringify(questions, null, 2));
    } catch (err) {
        console.error(err);
    } finally {
        await prisma.$disconnect();
    }
}

main();
