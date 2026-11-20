import { prisma } from '$lib/server/prisma';
import { logAdminAction } from '$lib/server/audit';
import { fail } from '@sveltejs/kit';
import type { PageServerLoad, Actions } from './$types';

export const load: PageServerLoad = async () => {
    const logs = await prisma.auditLog.findMany({
        orderBy: { createdAt: 'desc' }
    });

    return {
        logs: JSON.parse(JSON.stringify(logs))
    };
};

export const actions: Actions = {
    purgeLogs: async ({ request }) => {
        const data = await request.formData();
        const timeframe = String(data.get('timeframe') || '30days');

        let where: any = {};
        const now = new Date();
        if (timeframe === '7days') {
            where = { createdAt: { lt: new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000) } };
        } else if (timeframe === '30days') {
            where = { createdAt: { lt: new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000) } };
        } else if (timeframe === '90days') {
            where = { createdAt: { lt: new Date(now.getTime() - 90 * 24 * 60 * 60 * 1000) } };
        } else if (timeframe === 'all') {
            where = {};
        }

        const result = await prisma.auditLog.deleteMany({ where });

        await logAdminAction('PURGE_LOGS', `Admin purged ${result.count} audit log records (Filter: ${timeframe})`);

        return { success: true, count: result.count };
    }
};
