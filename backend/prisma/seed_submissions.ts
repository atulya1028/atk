import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();

async function main() {
    console.log('Seeding sample submissions...');

    // 1. Create Sample Users
    const usersData = [
        { email: 'alice@example.com', name: 'Alice Anderson' },
        { email: 'bob@example.com', name: 'Bob Builder' },
        { email: 'charlie@example.com', name: 'Charlie Chaplin' },
        { email: 'diana@example.com', name: 'Diana Prince' },
        { email: 'eve@example.com', name: 'Eve Polastri' },
    ];

    const users = [];
    for (const u of usersData) {
        const user = await prisma.user.upsert({
            where: { email: u.email },
            update: { name: u.name }, // Ensure name is set
            create: { ...u, otp: '123456' }
        });
        users.push(user);
    }

    // 2. Fetch Questions to Answer
    const questions = await prisma.question.findMany({
        include: { options: true }
    });

    // 3. Generate Submissions
    for (const user of users) {
        const numSubmissions = Math.floor(Math.random() * 3) + 1; // 1 to 3 submissions

        for (let i = 0; i < numSubmissions; i++) {
            const isCompleted = Math.random() > 0.3;
            const status = isCompleted ? 'completed' : 'draft';
            const date = new Date();
            date.setDate(date.getDate() - Math.floor(Math.random() * 30));

            const submission = await prisma.submission.create({
                data: {
                    userId: user.id,
                    status: status,
                    startedAt: date,
                    completedAt: isCompleted ? new Date(date.getTime() + 3600000) : null,
                }
            });

            // Answer Questions
            // If completed, answer almost all. If draft, answer some.
            const questionsToAnswer = questions.filter(() => Math.random() > (isCompleted ? 0.1 : 0.6));

            for (const q of questionsToAnswer) {
                let valueText: string | null = null;
                let valueNumber: number | null = null;
                let selectedOptions: any[] = [];

                if (['select', 'radio', 'yesno'].includes(q.inputType)) {
                    if (q.options.length > 0) {
                        const opt = q.options[Math.floor(Math.random() * q.options.length)];
                        valueText = opt.value;
                        selectedOptions.push(opt);
                    } else if (q.inputType === 'yesno') {
                        // Fallback if no options seeded for yesno
                        valueText = Math.random() > 0.5 ? 'yes' : 'no';
                        // Note: If 'yes'/'no' options exist in DB, we should use them, but if not, logic implies just text.
                        // The seeder earlier did seed options for yes/no questions usually.
                        // Try to find matching option if manual override
                        const match = q.options.find(o => o.value === valueText);
                        if (match) selectedOptions.push(match);
                    }
                } else if (q.inputType === 'multi_select') {
                    if (q.options.length > 0) {
                        // Pick 1 to N options
                        const count = Math.floor(Math.random() * q.options.length) + 1;
                        // Shuffle and pick
                        const shuffled = [...q.options].sort(() => 0.5 - Math.random());
                        const picked = shuffled.slice(0, count);
                        valueText = picked.map(o => o.value).join(',');
                        selectedOptions = picked;
                    }
                } else if (q.inputType === 'number') {
                    valueNumber = Math.floor(Math.random() * 100);
                    valueText = String(valueNumber);
                } else {
                    // Text
                    valueText = `Sample answer for ${q.slug}`;
                }

                if (valueText || valueNumber !== null) {
                    const answer = await prisma.answer.create({
                        data: {
                            submissionId: submission.id,
                            questionId: q.id,
                            valueString: valueText,
                            // Map number to Int or Dec if present
                            valueInt: valueNumber !== null ? Math.floor(valueNumber) : null,
                            valueDec: valueNumber !== null ? valueNumber : null,
                            legacyValueText: valueText // Populate for convenience
                        }
                    });

                    if (selectedOptions.length > 0) {
                        await prisma.answerChoice.createMany({
                            data: selectedOptions.map(o => ({
                                answerId: answer.id,
                                questionOptionId: o.id
                            }))
                        });
                    }
                }
            }
            console.log(`Created ${status} submission for ${user.name} with ${questionsToAnswer.length} answers.`);
        }
    }
}

main()
    .catch(e => {
        console.error(e);
        process.exit(1);
    })
    .finally(async () => {
        await prisma.$disconnect();
    });
