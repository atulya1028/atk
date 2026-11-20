import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function resetSubmissions() {
    try {
        console.log('Deleting all answers...');
        await prisma.answerChoice.deleteMany({});
        await prisma.answer.deleteMany({});

        console.log('Deleting all submissions...');
        const { count } = await prisma.submission.deleteMany({});

        console.log(`Deleted ${count} submissions.`);
    } catch (e) {
        console.error('Error resetting submissions:', e);
    } finally {
        await prisma.$disconnect();
    }
}

resetSubmissions();
