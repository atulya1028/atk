import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
    const options = await prisma.option.findMany({
        take: 20
    });
    console.log('--- Sample Options ---');
    options.forEach(o => {
        console.log(`ID: ${o.id}, Label: "${o.label}", Value: "${o.value}"`);
    });
    console.log('----------------------');
    await prisma.$disconnect();
}

main();
