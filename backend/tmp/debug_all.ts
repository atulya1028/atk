import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
    const submissions = await prisma.submission.findMany({
        orderBy: { id: 'desc' },
        take: 10
    });
    submissions.forEach(s => {
        console.log(`ID: ${s.id}, UserId: ${s.userId}, Type: ${s.surveyType}, Status: ${s.status}, Score: ${s.score}`);
    });
    await prisma.$disconnect();
}

main();
