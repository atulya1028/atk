import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
    const sections = await prisma.section.findMany({
        orderBy: { sortOrder: 'asc' },
        include: { parent: true }
    });

    console.log('ID\tOrder\tParent\tSlug\t\t\t\tTitle');
    console.log('--------------------------------------------------------------------------------');
    sections.forEach(s => {
        console.log(`${s.id}\t${s.sortOrder}\t${s.parentId || 'NULL'}\t${s.slug.padEnd(20)}\t${s.title}`);
    });
}

main()
    .catch(e => console.error(e))
    .finally(async () => await prisma.$disconnect());
