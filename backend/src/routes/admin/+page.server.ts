import { prisma } from '$lib/server/prisma';
import type { PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ url }) => {
    try {
        const categoryOpen = url.searchParams.get('surveyCategory') || url.searchParams.get('category');
        const category = categoryOpen?.toUpperCase();
        const filter = category ? { surveyCategory: category } : {};

        const now = new Date();
        const sevenDaysAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
        const thirtyDaysAgo = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);

        const [
            allUsersCount,
            registeredUsers,
            stage2CompletedUsers,
            unlockedStage3Users,
            initialSubmissions,
            detailedSubmissions,
            activeUsers7d,
            activeUsers30d,
            totalDoctors,
            criticalAlerts
        ] = await Promise.all([
            prisma.user.count({ where: filter }),
            prisma.user.count({ where: { isProfileComplete: true, ...filter } }),
            prisma.user.count({ where: { hasCompletedInitialSurvey: true, ...filter } }),
            prisma.user.count({ where: { hasUnlockedDetailedSurvey: true, ...filter } }),
            prisma.submission.count({ where: { surveyType: 'INITIAL', status: 'COMPLETED', ...filter } }),
            prisma.submission.count({ where: { surveyType: 'DETAILED', status: 'COMPLETED', ...filter } }),
            prisma.user.count({
                where: {
                    ...filter,
                    submissions: {
                        some: {
                            startedAt: { gte: sevenDaysAgo }
                        }
                    }
                }
            }),
            prisma.user.count({
                where: {
                    ...filter,
                    submissions: {
                        some: {
                            startedAt: { gte: thirtyDaysAgo }
                        }
                    }
                }
            }),
            prisma.doctor.count(),
            prisma.submission.count({
                where: {
                    surveyType: 'DETAILED',
                    score: { gte: 50 },
                    status: 'COMPLETED',
                    ...filter
                }
            })
        ]);

        const stats = {
            totalRegistered: registeredUsers,
            totalStage2: stage2CompletedUsers,
            totalStage3Unlocked: unlockedStage3Users,
            initialSubmissions,
            detailedSubmissions,
            active7d: activeUsers7d,
            active30d: activeUsers30d,
            totalUsers: allUsersCount,
            totalDoctors,
            criticalAlerts
        };

        const dailyTrend = await Promise.all([...Array(14)].map(async (_, i) => {
            const date = new Date();
            date.setDate(date.getDate() - (13 - i));
            date.setHours(0, 0, 0, 0);
            const nextDate = new Date(date);
            nextDate.setDate(nextDate.getDate() + 1);

            const count = Number(await prisma.submission.count({
                where: { startedAt: { gte: date, lt: nextDate }, status: 'COMPLETED', ...filter }
            }));
            return {
                date: date.toLocaleDateString(undefined, { month: 'short', day: 'numeric' }),
                count
            };
        }));

        const recentUsersRaw = await prisma.user.findMany({
            where: filter,
            orderBy: { createdAt: 'desc' },
            take: 10,
            include: {
                _count: {
                    select: { submissions: true }
                },
                submissions: {
                    orderBy: { startedAt: 'desc' },
                    take: 1
                }
            }
        });

        const recentUsers = recentUsersRaw.map((u: any) => ({
            id: u.id,
            email: u.email,
            name: u.name,
            createdAt: u.createdAt.toISOString(),
            isProfileComplete: u.isProfileComplete,
            submissionCount: u._count.submissions,
            lastActivity: u.submissions[0]?.startedAt?.toISOString() || u.createdAt.toISOString()
        }));

        // Segmentation Data
        const allProfiles = await prisma.user.findMany({
            where: { isProfileComplete: true, ...filter },
            select: { gender: true, maritalStatus: true, age: true }
        });

        const genderCounts: Record<string, number> = {};
        const maritalCounts: Record<string, number> = {};
        const ageCounts: Record<string, number> = {
            'Under 18': 0,
            '18-24': 0,
            '25-34': 0,
            '35-44': 0,
            '45-54': 0,
            '55-64': 0,
            '65+': 0,
            'Other/Unknown': 0
        };

        allProfiles.forEach((u: any) => {
            const g = u.gender || 'Unknown';
            genderCounts[g] = (genderCounts[g] || 0) + 1;

            const m = u.maritalStatus || 'Unknown';
            maritalCounts[m] = (maritalCounts[m] || 0) + 1;

            if (!u.age) {
                ageCounts['Other/Unknown']++;
            } else if (u.age.includes('-')) {
                // Handle ranges like "18-24" directly if they match or bucket them
                if (ageCounts[u.age] !== undefined) {
                    ageCounts[u.age]++;
                } else {
                    // Try to map "36-45" to "35-44" or similar
                    const start = parseInt(u.age.split('-')[0]);
                    if (start < 18) ageCounts['Under 18']++;
                    else if (start <= 24) ageCounts['18-24']++;
                    else if (start <= 34) ageCounts['25-34']++;
                    else if (start <= 44) ageCounts['35-44']++;
                    else if (start <= 54) ageCounts['45-54']++;
                    else if (start <= 64) ageCounts['55-64']++;
                    else ageCounts['65+']++;
                }
            } else {
                const ageNum = parseInt(u.age);
                if (isNaN(ageNum)) {
                    ageCounts['Other/Unknown']++;
                } else {
                    if (ageNum < 18) ageCounts['Under 18']++;
                    else if (ageNum <= 24) ageCounts['18-24']++;
                    else if (ageNum <= 34) ageCounts['25-34']++;
                    else if (ageNum <= 44) ageCounts['35-44']++;
                    else if (ageNum <= 54) ageCounts['45-54']++;
                    else if (ageNum <= 64) ageCounts['55-64']++;
                    else ageCounts['65+']++;
                }
            }
        });

        const segmentation = {
            gender: Object.entries(genderCounts).map(([label, value]) => ({ label, value })),
            marital: Object.entries(maritalCounts).map(([label, value]) => ({ label, value })),
            age: Object.entries(ageCounts).filter(([_, v]) => v > 0).map(([label, value]) => ({ label, value }))
        };

        return {
            stats,
            dailyTrend,
            recentUsers,
            segmentation
        };
    } catch (e: any) {
        console.error("DASHBOARD_LOAD_ERROR:", e);
        return {
            stats: {
                totalRegistered: 0,
                totalStage2: 0,
                totalStage3Unlocked: 0,
                initialSubmissions: 0,
                detailedSubmissions: 0,
                active7d: 0,
                active30d: 0,
                totalUsers: 0
            },
            dailyTrend: [],
            recentUsers: [],
            error: e.message
        };
    }
};
