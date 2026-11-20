import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
    const searchLabels = ['Almost never', 'Sometimes', 'Often', 'Nearly always'];
    const options = await prisma.option.findMany({
        where: {
            label: {
                in: searchLabels,
                mode: 'insensitive'
            }
        }
    });
    console.log(`Found ${options.length} matches.`);
    options.forEach(o => {
        console.log(`ID: ${o.id}, Label: "${o.label}", Value: "${o.value}"`);
    });
    await prisma.$disconnect();
}

main();
