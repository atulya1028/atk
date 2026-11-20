const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
    try {
        const question = await prisma.question.findFirst({
            where: { id: 223 },
            include: { options: true }
        });
        console.log('--- Question 223 ---');
        console.log(JSON.stringify(question, null, 2));

        const answers = await prisma.answer.findMany({
            where: { questionId: 223 },
            include: {
                submission: true,
                choices: { include: { option: true } }
            }
        });
        console.log('\n--- Answers for Question 223 ---');
        console.log(JSON.stringify(answers, null, 2));

    } catch (err) {
        console.error(err);
    } finally {
        await prisma.$disconnect();
    }
}

main();
