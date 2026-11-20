import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
    const email = 'akshaygarg.dcrust+u12@gmail.com';
    const user = await prisma.user.findUnique({ where: { email } });
    if (!user) {
        console.log('User not found');
        return;
    }
    const submissions = await prisma.submission.findMany({
        where: { userId: user.id },
        orderBy: { id: 'desc' }
    });
    console.log(`--- Submissions for ${email} ---`);
    submissions.forEach(s => {
        console.log(`ID: ${s.id}, Type: ${s.surveyType}, Status: ${s.status}, Score: ${s.score}, Began: ${s.startedAt}`);
    });
    console.log('--------------------------------');
    await prisma.$disconnect();
}

main();
