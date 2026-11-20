import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
    const questions = await prisma.question.findMany({
        where: {
            section: {
                surveyType: 'INITIAL'
            }
        },
        include: {
            options: true
        }
    });

    console.log(`Found ${questions.length} questions in initial survey.`);
    questions.forEach(q => {
        console.log(`Q: "${q.text}"`);
        q.options.forEach(o => {
            console.log(`  Opt: "${o.label}" (Value: ${o.value})`);
        });
    });
    await prisma.$disconnect();
}

main();
