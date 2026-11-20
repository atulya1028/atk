import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
    console.log('Cleaning up empty draft submissions...');
    const result = await prisma.submission.deleteMany({
        where: {
            status: 'DRAFT',
            answers: {
                none: {}
            }
        }
    });
    console.log(`Deleted ${result.count} empty draft submissions.`);
    await prisma.$disconnect();
}

main();
