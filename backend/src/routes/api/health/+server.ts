import { json } from '@sveltejs/kit';
import { prisma } from '$lib/server/prisma';
import type { RequestHandler } from './$types';

export const GET: RequestHandler = async () => {
    try {
        // Quick DB check
        await prisma.$queryRaw`SELECT 1`;
        return json({
            status: 'healthy',
            timestamp: new Date().toISOString(),
            uptime: process.uptime()
        }, { status: 200 });
    } catch (e: any) {
        return json({
            status: 'degraded',
            error: e.message,
            timestamp: new Date().toISOString()
        }, { status: 503 });
    }
};
