import { prisma } from '$lib/server/prisma';
import type { LayoutServerLoad } from './$types';

export const load: LayoutServerLoad = async () => {
    try {
        const [criticalCount, pendingTriageCount, doctorsCount, participantsCount] = await Promise.all([
            prisma.submission.count({
                where: { surveyType: 'DETAILED', score: { gte: 50 }, status: 'COMPLETED' }
            }),
            prisma.submission.count({
                where: { triageStatus: 'NEW' }
            }),
            prisma.doctor.count(),
            prisma.user.count()
        ]);

        const dbUrl = process.env.DATABASE_URL || '';
        const isMysql = dbUrl.startsWith('mysql://') || dbUrl.startsWith('mysql2://');
        const isAws = isMysql && dbUrl.includes('.rds.amazonaws.com');

        return {
            systemCounts: {
                critical: criticalCount,
                pendingTriage: pendingTriageCount,
                doctors: doctorsCount,
                participants: participantsCount
            },
            systemEnv: {
                isAws,
                provider: isMysql ? (isAws ? 'AWS RDS (MySQL 8.0)' : 'MySQL') : 'SQLite (Local Dev)',
                nodeEnv: process.env.NODE_ENV || 'development'
            }
        };
    } catch (e: any) {
        console.error('LAYOUT_SERVER_LOAD_ERROR:', e);
        return {
            systemCounts: { critical: 0, pendingTriage: 0, doctors: 0, participants: 0 },
            systemEnv: { isAws: false, provider: 'SQLite (Local Dev)', nodeEnv: 'development' }
        };
    }
};
