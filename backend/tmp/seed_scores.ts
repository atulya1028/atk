import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
    console.log('Updating option scores...');

    // We are looking for partial matches or exactly what we saw
    const scoreMap = [
        { pattern: 'Almost never', score: 0 },
        { pattern: 'Sometimes', score: 1 },
        { pattern: 'Often', score: 2 },
        { pattern: 'Nearly always', score: 3 },
        { pattern: 'Not at all', score: 0 },
        { pattern: 'Slightly', score: 1 },
        { pattern: 'Moderately', score: 2 },
        { pattern: 'Quite a lot', score: 3 }
    ];

    const options = await prisma.option.findMany();
    let count = 0;

    for (const option of options) {
        const match = scoreMap.find(sm => option.label?.includes(sm.pattern));
        if (match) {
            await prisma.option.update({
                where: { id: option.id },
                data: { scoreValue: match.score }
            });
            count++;
        }
    }

    console.log(`Updated ${count} options.`);
    await prisma.$disconnect();
}

main().catch(async (e) => {
    console.error(e);
    await prisma.$disconnect();
    process.exit(1);
});
