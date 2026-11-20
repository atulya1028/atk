import { json } from '@sveltejs/kit';
import { prisma } from '$lib/server/prisma';
import { transporter, getSenderAddress } from '$lib/server/mailer';
import { env } from '$env/dynamic/private';
import type { RequestHandler } from './$types';

export const GET: RequestHandler = async () => {
    const startTime = Date.now();
    let dbConnected = false;
    let dbLatencyMs = -1;
    let provider = 'sqlite';
    let maskedDbUrl = 'Local SQLite (dev.db)';

    const dbUrl = env.DATABASE_URL || process.env.DATABASE_URL || '';
    if (dbUrl.startsWith('mysql://') || dbUrl.startsWith('mysql2://')) {
        provider = 'mysql';
        // Mask password in database URL for safe display
        try {
            const parsed = new URL(dbUrl);
            parsed.password = '••••••••';
            maskedDbUrl = parsed.toString();
        } catch {
            maskedDbUrl = 'AWS RDS MySQL (configured)';
        }
    }

    try {
        await prisma.$queryRaw`SELECT 1`;
        dbLatencyMs = Date.now() - startTime;
        dbConnected = true;
    } catch (e: any) {
        console.error('SYSTEM_STATUS_DB_ERROR:', e);
    }

    const isAws = provider === 'mysql' && (maskedDbUrl.includes('.rds.amazonaws.com') || !!env.AWS_REGION || !!process.env.AWS_EXECUTION_ENV);
    const sesConfigured = !!(env.SMTP_HOST && (env.SMTP_USER || env.SMTP_FROM));
    const isSesHost = (env.SMTP_HOST || '').includes('.amazonaws.com');

    // System resource telemetry
    const mem = process.memoryUsage();
    const uptimeSec = Math.floor(process.uptime());
    const hours = Math.floor(uptimeSec / 3600);
    const minutes = Math.floor((uptimeSec % 3600) / 60);
    const seconds = uptimeSec % 60;
    const uptimeFormatted = `${hours}h ${minutes}m ${seconds}s`;

    let metrics = {
        totalUsers: 0,
        totalSubmissions: 0,
        criticalSubmissions: 0,
        totalDoctors: 0
    };

    if (dbConnected) {
        try {
            const [users, subs, crit, docs] = await Promise.all([
                prisma.user.count(),
                prisma.submission.count(),
                prisma.submission.count({
                    where: { surveyType: 'DETAILED', score: { gte: 50 }, status: 'COMPLETED' }
                }),
                prisma.doctor.count()
            ]);
            metrics = {
                totalUsers: users,
                totalSubmissions: subs,
                criticalSubmissions: crit,
                totalDoctors: docs
            };
        } catch (mErr) {
            console.warn('SYSTEM_STATUS_METRICS_WARN:', mErr);
        }
    }

    return json({
        status: dbConnected ? 'healthy' : 'degraded',
        timestamp: new Date().toISOString(),
        db: {
            connected: dbConnected,
            latencyMs: dbLatencyMs,
            provider: isAws ? 'AWS RDS (MySQL 8.0)' : provider.toUpperCase(),
            endpoint: maskedDbUrl
        },
        aws: {
            isAwsDeployment: isAws,
            region: env.AWS_REGION || process.env.AWS_DEFAULT_REGION || 'eu-west-2 (London)',
            sesConfigured,
            isSesHost,
            sesHost: env.SMTP_HOST || 'Not configured',
            sesPort: env.SMTP_PORT || '587',
            senderAddress: getSenderAddress(),
            alertRecipient: env.ADMIN_NOTIFICATION_EMAIL || 'Not configured'
        },
        system: {
            uptimeSeconds: uptimeSec,
            uptimeFormatted,
            nodeVersion: process.version,
            platform: process.platform,
            environment: env.NODE_ENV || process.env.NODE_ENV || 'production',
            memoryMb: {
                heapUsed: Math.round(mem.heapUsed / 1024 / 1024),
                heapTotal: Math.round(mem.heapTotal / 1024 / 1024),
                rss: Math.round(mem.rss / 1024 / 1024)
            }
        },
        metrics
    });
};

export const POST: RequestHandler = async ({ request }) => {
    const data = await request.formData();
    const action = data.get('action');

    if (action === 'test-email') {
        const recipient = env.ADMIN_NOTIFICATION_EMAIL;
        if (!recipient) {
            return json({ success: false, error: 'ADMIN_NOTIFICATION_EMAIL is not defined in environment variables.' }, { status: 400 });
        }

        const sender = getSenderAddress();
        const start = Date.now();

        try {
            const info = await transporter.sendMail({
                from: sender,
                to: recipient,
                subject: `[AWS SES TEST] Novtek ATK System Verification - ${new Date().toLocaleTimeString()}`,
                text: `This is a test notification confirming that the AWS SES email delivery service is correctly configured and operational from the Novtek ATK Clinical Admin Panel.`,
                html: `
                    <div style="font-family: sans-serif; padding: 24px; max-width: 500px; border: 1px solid #e2e8f0; border-radius: 12px; background: #ffffff;">
                        <div style="background: #4f46e5; color: white; padding: 12px 16px; border-radius: 8px; text-align: center; font-weight: bold;">
                            ☁️ AWS SES System Connectivity Test
                        </div>
                        <p style="margin-top: 20px; font-size: 14px; color: #334155;">
                            This test email confirms that your AWS SES / SMTP integration is online and able to dispatch clinical triage notifications.
                        </p>
                        <table style="width: 100%; font-size: 13px; color: #475569; border-collapse: collapse; margin-top: 16px;">
                            <tr><td style="padding: 6px 0; font-weight: bold;">Sender:</td><td>${sender}</td></tr>
                            <tr><td style="padding: 6px 0; font-weight: bold;">Recipient:</td><td>${recipient}</td></tr>
                            <tr><td style="padding: 6px 0; font-weight: bold;">Timestamp:</td><td>${new Date().toISOString()}</td></tr>
                        </table>
                    </div>
                `
            });
            const durationMs = Date.now() - start;
            return json({
                success: true,
                messageId: info.messageId,
                durationMs,
                recipient,
                sender
            });
        } catch (e: any) {
            console.error('SES_TEST_EMAIL_ERROR:', e);
            return json({ success: false, error: e.message || 'SMTP communication failure.' }, { status: 500 });
        }
    }

    return json({ error: 'Unknown action' }, { status: 400 });
};
