import 'dotenv/config'
import { PrismaClient } from '@prisma/client'
import fs from 'fs'
import path from 'path'
import { fileURLToPath } from 'url'

const __filename = fileURLToPath(import.meta.url)
const __dirname = path.dirname(__filename)

const prisma = new PrismaClient()

interface RawQuestion {
    '#': number
    Section: string
    SectionSlug: string
    SectionOrder: number
    Question: string
    'Answer options': string
    'Logic Builder': string
}

function parseOptions(raw: string): { label: string; value: string }[] {
    if (!raw) return []
    return raw
        .split('\n')
        .map(line => line.replace(/^-\s*/, '').trim())
        .filter(line => line.length > 0)
        .filter(line => {
            const lower = line.toLowerCase()
            // These are freeform numeric inputs, not discrete options
            return !lower.includes('numeric') && !lower.includes('scale') && !lower.includes('units/')
        })
        .map((label, idx) => ({
            label,
            value: label.toLowerCase().replace(/[^a-z0-9]+/g, '_').replace(/(^_|_$)/g, ''),
            sortOrder: idx
        }))
}

function detectInputType(raw: string, options: { label: string }[]): string {
    const lower = raw.toLowerCase()
    if (lower.includes('numeric') || lower.includes('scale') || lower.includes('units/')) {
        return 'number'
    }
    if (options.length > 0) return 'select'
    return 'text'
}

async function main() {
    console.log('Start seeding ...')

    const jsonPath = path.join(__dirname, '..', 'data_source', 'questions.json')
    if (!fs.existsSync(jsonPath)) {
        console.error(`questions.json not found at: ${jsonPath}`)
        process.exit(1)
    }

    const rawQuestions: RawQuestion[] = JSON.parse(fs.readFileSync(jsonPath, 'utf8'))
    console.log(`Loaded ${rawQuestions.length} questions from questions.json`)

    // Clear existing data
    await prisma.answerChoice.deleteMany()
    await prisma.answer.deleteMany()
    await prisma.submission.deleteMany()
    await prisma.questionDependency.deleteMany()
    await prisma.option.deleteMany()
    await prisma.question.deleteMany()
    await prisma.section.deleteMany()

    // ---- 1. Create unique sections ----
    const sectionMap = new Map<string, number>() // slug -> id

    // Collect unique sections preserving order
    const seenSlugs = new Set<string>()
    const sectionsToCreate: { slug: string; title: string; sortOrder: number }[] = []
    for (const q of rawQuestions) {
        if (!seenSlugs.has(q.SectionSlug)) {
            seenSlugs.add(q.SectionSlug)
            sectionsToCreate.push({
                slug: q.SectionSlug,
                title: q.Section,
                sortOrder: q.SectionOrder
            })
        }
    }

    // Sort by SectionOrder so they appear in logical order
    sectionsToCreate.sort((a, b) => a.sortOrder - b.sortOrder)

    const initialSections = [
        'identifying_data',
        'risk_assessment_screening',
        'psychosocial_stressors',
        'personal_psychiatric_history',
        'sleep_daily_functioning'
    ]

    for (const s of sectionsToCreate) {
        const surveyType = initialSections.includes(s.slug) ? 'INITIAL' : 'DETAILED';
        const created = await prisma.section.create({
            data: {
                ...s,
                surveyType
            }
        })
        sectionMap.set(s.slug, created.id)
        console.log(`  section: [${s.sortOrder}] ${s.title} (${surveyType})`)
    }
    console.log(`Created ${sectionMap.size} sections`)

    // ---- 2. Create questions ----
    const questionByNum = new Map<number, { id: number; slug: string; text: string }>()

    for (const raw of rawQuestions) {
        const num = raw['#']
        const text = raw['Question']
        const optionsRaw = raw['Answer options'] || ''

        const options = parseOptions(optionsRaw)
        const inputType = detectInputType(optionsRaw, options)

        const sectionId = sectionMap.get(raw.SectionSlug)
        const slug = `q${num}`

        const createdQ = await prisma.question.create({
            data: {
                slug,
                text,
                inputType,
                isRequired: true,
                sortOrder: num,
                sectionId: sectionId ?? null,
                options: options.length > 0 ? {
                    create: options
                } : undefined
            }
        })

        questionByNum.set(num, { id: createdQ.id, slug: createdQ.slug, text: createdQ.text })
    }
    console.log(`Created ${questionByNum.size} questions`)

    // ---- 3. Create dependencies ----
    // Map trigger descriptions to question numbers for known logic rules:
    // "Past substance use? = Yes"         -> Q36 (substance use history gating question)
    // "Recently reduced or stopped..."    -> Q52
    // "Withdrawal symptoms = Yes"         -> Q62
    // "Ever needed medical help = Yes"    -> Q58
    // "Gender = Female"                   -> Q2
    // "Past treatment for substance use"  -> Q37
    const triggerMapping: Record<string, { questionNum: number; value: string }> = {
        'Past substance use? = Yes': { questionNum: 36, value: 'yes' },
        'Recently reduced or stopped drinking = Yes': { questionNum: 52, value: 'yes' },
        'Withdrawal symptoms = Yes': { questionNum: 62, value: 'yes' },
        'Ever needed medical help = Yes': { questionNum: 58, value: 'yes' },
        'Gender = Female': { questionNum: 2, value: 'female' },
        'Past treatment for substance use? = Yes': { questionNum: 37, value: 'yes' },
    }

    let depsCreated = 0
    for (const raw of rawQuestions) {
        const logic = raw['Logic Builder'] || ''
        if (logic.toLowerCase().includes('always show')) continue

        // Extract the condition line: "Show if:\n- <condition>"
        const conditionMatch = logic.match(/[-]\s*(.+)/i)
        if (!conditionMatch) continue
        const condition = conditionMatch[1].trim()

        // Find the matching trigger
        const trigger = Object.entries(triggerMapping).find(([key]) =>
            condition.toLowerCase().includes(key.toLowerCase().split('=')[0].trim())
        )
        if (!trigger) continue

        const [, { questionNum: triggerNum, value: triggerValue }] = trigger
        const triggerQ = questionByNum.get(triggerNum)
        const dependentQ = questionByNum.get(raw['#'])

        if (triggerQ && dependentQ) {
            await prisma.questionDependency.create({
                data: {
                    dependentQuestionId: dependentQ.id,
                    triggerQuestionId: triggerQ.id,
                    operator: 'eq',
                    triggerValue
                }
            })
            depsCreated++
        }
    }
    console.log(`Created ${depsCreated} question dependencies`)
    console.log('Seeding finished.')
}

main()
    .then(async () => {
        await prisma.$disconnect()
    })
    .catch(async (e) => {
        console.error(e)
        await prisma.$disconnect()
        process.exit(1)
    })
