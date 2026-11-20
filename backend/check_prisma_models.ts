import { PrismaClient } from '@prisma/client'
const prisma = new PrismaClient()

async function main() {
    console.log('Prisma Models:')
    console.log(Object.keys(prisma).filter(k => !k.startsWith('_') && !k.startsWith('$')))
}

main().finally(() => prisma.$disconnect())
