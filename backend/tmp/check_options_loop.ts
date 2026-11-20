import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
    const searchLabels = ['Almost never', 'Sometimes', 'Often', 'Nearly always'];
    const options = await prisma.option.findMany();
    const matches = options.filter(o => searchLabels.some(l => l.toLowerCase() === o.label?.toLowerCase().trim()));
    console.log(`Found ${matches.length} matches.`);
    matches.forEach(o => {
        console.log(`ID: ${o.id}, Label: "${o.label}", Value: "${o.value}"`);
    });
    await prisma.$disconnect();
}

main();
