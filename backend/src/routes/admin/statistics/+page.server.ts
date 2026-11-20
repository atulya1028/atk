import { prisma } from '$lib/server/prisma';
import type { PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ url }) => {
    const categoryParam = url.searchParams.get('category')?.toUpperCase();
    const whereCategory = categoryParam && categoryParam !== 'ALL' ? { surveyCategory: categoryParam } : {};

    const [
        totalUsers,
        stage1Users,
        stage2Users,
        stage3UnlockedUsers,
        submissions,
        settings,
        topPincodesRaw
    ] = await Promise.all([
        prisma.user.count({ where: whereCategory }),
        prisma.user.count({ where: { isProfileComplete: true, ...whereCategory } }),
        prisma.user.count({ where: { hasCompletedInitialSurvey: true, ...whereCategory } }),
        prisma.user.count({ where: { hasUnlockedDetailedSurvey: true, ...whereCategory } }),
        prisma.submission.findMany({
            where: {
                status: 'COMPLETED',
                ...whereCategory
            },
            include: {
                user: {
                    select: { pinCode: true, age: true, gender: true }
                }
            },
            orderBy: { completedAt: 'desc' }
        }),
        prisma.surveySettings.findMany(),
        prisma.user.groupBy({
            by: ['pinCode'],
            _count: { id: true },
            where: { pinCode: { not: null }, ...whereCategory },
            orderBy: { _count: { id: 'desc' } },
            take: 10
        })
    ]);

    const criticalMap: Record<string, number> = {};
    const thresholdMap: Record<string, number> = {};
    for (const s of settings) {
        const cat = s.surveyCategory.toUpperCase();
        criticalMap[cat] = s.criticalValue;
        thresholdMap[cat] = s.threshold;
    }

    // Funnel calculations
    const stage3CompletedCount = submissions.filter((s: any) => s.surveyType === 'DETAILED').length;
    let criticalCount = 0;
    let moderateCount = 0;
    let mildCount = 0;

    // Monthly/Weekly trends
    const monthCounts: Record<string, { total: number; critical: number }> = {};
    const categoryDistribution: Record<string, number> = { ADDICTION: 0, MENTAL: 0 };
    const pincodeRiskMap: Record<string, { total: number; critical: number }> = {};

    submissions.forEach((s: any) => {
        const cat = (s.surveyCategory || 'ADDICTION').toUpperCase();
        categoryDistribution[cat] = (categoryDistribution[cat] || 0) + 1;

        const critThreshold = criticalMap[cat] ?? 50;
        const initThreshold = thresholdMap[cat] ?? 30;

        const isCritical = s.surveyType === 'DETAILED' && s.score >= critThreshold;
        const isModerate = s.score >= initThreshold && !isCritical;

        if (isCritical) criticalCount++;
        else if (isModerate) moderateCount++;
        else mildCount++;

        // Pincode stats
        const pin = s.user?.pinCode?.trim().toUpperCase() || 'UNSPECIFIED';
        if (!pincodeRiskMap[pin]) pincodeRiskMap[pin] = { total: 0, critical: 0 };
        pincodeRiskMap[pin].total++;
        if (isCritical) pincodeRiskMap[pin].critical++;

        // Monthly bucket
        if (s.completedAt) {
            const m = new Date(s.completedAt).toLocaleDateString(undefined, { month: 'short', year: 'numeric' });
            if (!monthCounts[m]) monthCounts[m] = { total: 0, critical: 0 };
            monthCounts[m].total++;
            if (isCritical) monthCounts[m].critical++;
        }
    });

    const topPincodes = Object.entries(pincodeRiskMap)
        .sort((a, b) => b[1].total - a[1].total)
        .slice(0, 8)
        .map(([pincode, stats]) => ({
            pincode,
            totalSubmissions: stats.total,
            criticalCount: stats.critical,
            criticalRate: Math.round((stats.critical / stats.total) * 100) || 0
        }));

    const funnel = [
        { stage: '1. Registered Users', count: totalUsers, pct: 100 },
        { stage: '2. Profile Completed', count: stage1Users, pct: totalUsers ? Math.round((stage1Users / totalUsers) * 100) : 0 },
        { stage: '3. Initial Screening (Stg 2)', count: stage2Users, pct: totalUsers ? Math.round((stage2Users / totalUsers) * 100) : 0 },
        { stage: '4. Stage 3 Unlocked', count: stage3UnlockedUsers, pct: totalUsers ? Math.round((stage3UnlockedUsers / totalUsers) * 100) : 0 },
        { stage: '5. Detailed Assessment Done', count: stage3CompletedCount, pct: totalUsers ? Math.round((stage3CompletedCount / totalUsers) * 100) : 0 },
        { stage: '6. Critical Risk Alerts', count: criticalCount, pct: totalUsers ? Math.round((criticalCount / totalUsers) * 100) : 0 }
    ];

    const riskDistribution = [
        { label: 'Mild / Low Risk', count: mildCount, color: 'bg-emerald-500', text: 'text-emerald-700', bgLight: 'bg-emerald-50' },
        { label: 'Moderate / At-Risk', count: moderateCount, color: 'bg-amber-500', text: 'text-amber-700', bgLight: 'bg-amber-50' },
        { label: 'Critical / Severe (Alerted)', count: criticalCount, color: 'bg-rose-500', text: 'text-rose-700', bgLight: 'bg-rose-50' }
    ];

    return {
        selectedCategory: categoryParam || 'ALL',
        funnel,
        riskDistribution,
        categoryDistribution: Object.entries(categoryDistribution).map(([cat, count]) => ({
            category: cat === 'MENTAL' ? 'Mental Health' : 'Addiction Recovery',
            raw: cat,
            count
        })),
        topPincodes,
        monthlyTrend: Object.entries(monthCounts).map(([month, data]) => ({
            month,
            total: data.total,
            critical: data.critical
        })),
        totalCompletedSubmissions: submissions.length,
        criticalAlertsCount: criticalCount
    };
};
