import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

const GROUPS = [
    { prefix: 'sub_alcohol_', masterSlug: 'sub_alcohol_main', title: 'Alcohol Use Disorder', order: 20 },
    { prefix: 'sub_opioid_', masterSlug: 'sub_opioid_main', title: 'Opioid Use Disorder', order: 30 },
    { prefix: 'sub_cannabis_', masterSlug: 'sub_cannabis_main', title: 'Cannabis Use Disorder', order: 40 },
    { prefix: 'sub_benzo_', masterSlug: 'sub_benzo_main', title: 'Sedative/Hypnotic Use Disorder', order: 50 },
    { prefix: 'sub_stimulant_', masterSlug: 'sub_stimulant_main', title: 'Stimulant Use Disorder', order: 60 },
];

async function main() {
    console.log('Starting Hierarchy Fix...');

    // 1. Ensure Safety Screening is top
    await prisma.section.updateMany({
        where: { slug: 'safety_screening' },
        data: { sortOrder: 0, parentId: null }
    });
    console.log('Updated Safety Screening priority.');

    // 2. Process each substance group
    for (const group of GROUPS) {
        // Find or Create Master Section
        let master = await prisma.section.findUnique({ where: { slug: group.masterSlug } });

        if (!master) {
            console.log(`Creating Master: ${group.title}`);
            master = await prisma.section.create({
                data: {
                    slug: group.masterSlug,
                    title: group.title,
                    sortOrder: group.order,
                    sectionType: 'folder' // Custom type for UI if needed
                }
            });
        } else {
            // Ensure sort order
            await prisma.section.update({
                where: { id: master.id },
                data: { sortOrder: group.order, title: group.title }
            });
        }

        // Find Children (starting with prefix, NOT equal to master itself)
        const children = await prisma.section.findMany({
            where: {
                slug: { startsWith: group.prefix },
                id: { not: master.id }
            }
        });

        console.log(`Found ${children.length} children for ${group.title}`);

        // Update Children
        for (let i = 0; i < children.length; i++) {
            const child = children[i];
            await prisma.section.update({
                where: { id: child.id },
                data: {
                    parentId: master.id,
                    sortOrder: i + 1 // 1-indexed relative order
                }
            });
            console.log(`  -> Linked ${child.title} to ${group.title}`);
        }
    }

    // 3. Cleanup: Ensure general sections are visible
    // Identifying Data -> 1
    const idData = await prisma.section.findFirst({ where: { slug: 'gen_identifying_data' } });
    if (idData) {
        await prisma.section.update({
            where: { id: idData.id },
            data: { sortOrder: 1, parentId: null }
        });
    }

    console.log('Hierarchy Fix Complete.');
}

main()
    .catch(e => console.error(e))
    .finally(async () => await prisma.$disconnect());
