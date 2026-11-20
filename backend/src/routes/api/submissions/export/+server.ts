import { json } from '@sveltejs/kit';
import { prisma } from '$lib/server/prisma';
import { transporter } from '$lib/server/mailer';
import { env } from '$env/dynamic/private';
import { logAdminAction } from '$lib/server/audit';
import type { RequestHandler } from './$types';

export const GET: RequestHandler = async ({ url }) => {
    const action = url.searchParams.get('action') || 'download';
    const categoryFilter = url.searchParams.get('category') || 'all';
    const stageFilter = url.searchParams.get('stage') || 'all';
    const statusFilter = url.searchParams.get('status') || 'all';
    const riskFilter = url.searchParams.get('risk') || 'all';

    const where: any = {};
    if (categoryFilter !== 'all') {
        where.surveyCategory = categoryFilter.toUpperCase();
    }
    if (stageFilter !== 'all') {
        where.surveyType = stageFilter.toUpperCase();
    }
    if (statusFilter !== 'all') {
        where.status = statusFilter.toUpperCase();
    }

    const [submissions, settings] = await Promise.all([
        prisma.submission.findMany({
            where,
            orderBy: { startedAt: 'desc' },
            include: { user: true }
        }),
        prisma.surveySettings.findMany()
    ]);

    // Apply risk filter in memory
    const enrichedSubmissions = submissions.map((sub: any) => {
        const categorySettings = settings.find((s: any) => s.surveyCategory === sub.surveyCategory);
        const criticalValue = categorySettings?.criticalValue ?? 50;
        const isCritical = sub.surveyType === 'DETAILED' && sub.score >= criticalValue;
        return {
            ...sub,
            email: sub.user?.email || 'Guest Participant',
            criticalValue,
            isCritical
        };
    });

    const filteredSubmissions = riskFilter === 'critical' 
        ? enrichedSubmissions.filter((sub: any) => sub.isCritical)
        : enrichedSubmissions;

    const headers = [
        'Submission ID',
        'Participant Email',
        'Survey Category',
        'Clinical Stage',
        'Assessment Status',
        'Score',
        'Critical Threshold',
        'Risk Warning',
        'Date Started',
        'Date Completed'
    ];

    const escapeCsv = (str: string) => `"${str.replace(/"/g, '""')}"`;

    const rows = filteredSubmissions.map((sub: any) => {
        const formattedStarted = sub.startedAt ? new Date(sub.startedAt).toISOString().replace('T', ' ').slice(0, 19) : '';
        const formattedCompleted = sub.completedAt ? new Date(sub.completedAt).toISOString().replace('T', ' ').slice(0, 19) : '';
        
        return [
            `#${sub.id}`,
            escapeCsv(sub.email),
            sub.surveyCategory === 'MENTAL' ? 'Mental Health' : 'Addiction',
            sub.surveyType === 'INITIAL' ? 'Initial (Stg 2)' : 'Detailed (Stg 3)',
            sub.status,
            sub.score !== null && sub.score !== undefined ? sub.score : '-',
            sub.criticalValue,
            sub.isCritical ? 'CRITICAL' : 'Standard',
            formattedStarted,
            formattedCompleted
        ].join(',');
    });

    const csvContent = [headers.join(','), ...rows].join('\n');

    if (action === 'email') {
        const adminEmail = env.ADMIN_NOTIFICATION_EMAIL;
        if (!adminEmail) {
            return json({ error: 'Admin email not configured' }, { status: 400 });
        }

        const dateStr = new Date().toISOString().slice(0, 10);
        const subject = `[ATK REPORT] Submissions Export - Category: ${categoryFilter.toUpperCase()}, Risk: ${riskFilter.toUpperCase()}`;

        try {
            const senderAddress = env.SMTP_FROM || env.SMTP_USER || 'reports@novtek-atk.com';
            await transporter.sendMail({
                from: senderAddress,
                to: adminEmail,
                subject,
                text: `Hello,\n\nPlease find attached the requested CSV submissions report.\n\nFilters:\n- Category: ${categoryFilter}\n- Stage: ${stageFilter}\n- Status: ${statusFilter}\n- Risk: ${riskFilter}\n\nGenerated on: ${dateStr}`,
                html: `
                    <div style="font-family: sans-serif; padding: 20px; color: #1e293b; max-width: 600px; margin: 0 auto; border: 1px solid #f3f4f6; border-radius: 12px; box-shadow: 0 4px 6px -1px rgb(0 0 0 / 0.05);">
                        <div style="background-color: #4f46e5; color: white; padding: 16px; border-radius: 8px; text-align: center; margin-bottom: 24px;">
                            <h2 style="margin: 0; font-size: 18px; font-weight: bold; letter-spacing: 0.5px;">📊 Submissions Report Exported</h2>
                        </div>
                        <p style="font-size: 15px; color: #374151; line-height: 1.5; margin-bottom: 16px;">
                            Hello,
                        </p>
                        <p style="font-size: 15px; color: #374151; line-height: 1.5; margin-bottom: 24px;">
                            Please find attached the requested CSV submissions report generated from the Admin Web Dashboard.
                        </p>
                        <h3 style="border-bottom: 2px solid #f3f4f6; padding-bottom: 8px; color: #1f2937; font-size: 15px; font-weight: bold; margin-top: 24px;">Active Filters:</h3>
                        <table style="width: 100%; border-collapse: collapse; margin-bottom: 24px;">
                            <tr>
                                <td style="padding: 8px 0; font-weight: bold; color: #4b5563; width: 40%;">Category:</td>
                                <td style="padding: 8px 0; color: #1f2937;">${categoryFilter.toUpperCase()}</td>
                            </tr>
                            <tr>
                                <td style="padding: 8px 0; font-weight: bold; color: #4b5563;">Stage:</td>
                                <td style="padding: 8px 0; color: #1f2937;">${stageFilter.toUpperCase()}</td>
                            </tr>
                            <tr>
                                <td style="padding: 8px 0; font-weight: bold; color: #4b5563;">Status:</td>
                                <td style="padding: 8px 0; color: #1f2937;">${statusFilter.toUpperCase()}</td>
                            </tr>
                            <tr>
                                <td style="padding: 8px 0; font-weight: bold; color: #4b5563;">Risk Warning Filter:</td>
                                <td style="padding: 8px 0; color: #1f2937; font-weight: bold; color: ${riskFilter === 'critical' ? '#ef4444' : '#1f2937'};">${riskFilter.toUpperCase()}</td>
                            </tr>
                        </table>
                        <div style="border-top: 1px solid #f3f4f6; padding-top: 16px; text-align: center; margin-top: 24px;">
                            <p style="font-size: 11px; color: #9ca3af; margin: 0;">
                                Generated on ${dateStr}. This is an automated email notification.
                            </p>
                        </div>
                    </div>
                `,
                attachments: [
                    {
                        filename: `ATK_Submissions_Report_${dateStr}.csv`,
                        content: csvContent
                    }
                ]
            });
            await logAdminAction('EMAIL_REPORT', `Emailed submissions report. Filters: Category=${categoryFilter}, Stage=${stageFilter}, Status=${statusFilter}, Risk=${riskFilter}`);
            return json({ success: true, message: 'Email sent successfully' });
        } catch (e: any) {
            console.error('[REPORT_EMAIL_ERROR]', e);
            return json({ error: `Failed to send email: ${e.message}` }, { status: 500 });
        }
    }

    await logAdminAction('DOWNLOAD_REPORT', `Downloaded submissions CSV. Filters: Category=${categoryFilter}, Stage=${stageFilter}, Status=${statusFilter}, Risk=${riskFilter}`);

    return new Response(csvContent, {
        headers: {
            'Content-Type': 'text/csv',
            'Content-Disposition': `attachment; filename="ATK_Submissions_Report_${new Date().toISOString().slice(0, 10)}.csv"`
        }
    });
};
