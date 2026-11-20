import { prisma } from './prisma';
import { transporter } from './mailer';
import { env } from '$env/dynamic/private';
import { getDefaultEmailTemplate } from './defaultTemplates';

/**
 * Handle side effects of a completed survey submission.
 * If the submission belongs to Stage 3 (DETAILED) and its score meets or exceeds
 * the Critical Value set for that category, an alert email is dispatched to the admin.
 */
export async function handleCriticalSubmission(submissionId: number, score: number, origin: string) {
    try {
        console.log(`[ALERTS] Checking critical alert status for submission ID ${submissionId} with score ${score} on origin ${origin}`);
        
        // 1. Fetch submission and participant details
        const submission = await prisma.submission.findUnique({
            where: { id: submissionId },
            include: { user: true }
        });

        if (!submission) {
            console.error(`[ALERTS] Submission not found: ${submissionId}`);
            return;
        }

        // Only evaluate Stage 3 (DETAILED) assessments for critical alerts
        if (submission.surveyType !== 'DETAILED') {
            console.log(`[ALERTS] Submission ${submissionId} is of type ${submission.surveyType}. Skipping critical alert checks.`);
            return;
        }

        const surveyCategory = submission.surveyCategory.toUpperCase();

        // 2. Fetch critical value threshold from settings (and include customizable templates)
        const settings = await prisma.surveySettings.findUnique({
            where: { surveyCategory },
            include: { emailTemplate: true }
        });
        const criticalValue = settings?.criticalValue ?? 50;

        console.log(`[ALERTS] Category: ${surveyCategory}, Score: ${score}, Critical Value Threshold: ${criticalValue}`);

        // 3. Trigger email if score meets or exceeds the threshold
        if (score >= criticalValue) {
            const adminEmail = env.ADMIN_NOTIFICATION_EMAIL;
            if (!adminEmail) {
                console.warn(`[ALERTS] ADMIN_NOTIFICATION_EMAIL environment variable is not defined. Email alert skipped.`);
                return;
            }

            const participant = submission.user;
            const completionTime = submission.completedAt ? new Date(submission.completedAt).toLocaleString() : new Date().toLocaleString();

            const subject = `[CRITICAL ALERT] High Risk Submission Detected - ${surveyCategory}`;
            const textContent = `[CRITICAL ALERT] High Risk Submission Detected

=========================================
SUBMISSION SUMMARY:
=========================================
- Submission ID: ${submission.id}
- Survey Stage: Stage 3 (Detailed Assessment)
- Survey Category: ${surveyCategory}
- Participant Score: ${score}
- Critical Threshold: ${criticalValue}
- Submission Time: ${completionTime}

=========================================
PARTICIPANT DETAILS:
=========================================
- Name: ${participant.name ?? 'N/A'}
- Email: ${participant.email}
- Phone Number: ${participant.phoneNumber ?? 'N/A'}
- Age: ${participant.age ?? 'N/A'}
- Gender: ${participant.gender ?? 'N/A'}
- Occupation: ${participant.occupation ?? 'N/A'}
- Marital Status: ${participant.maritalStatus ?? 'N/A'}
- Pin Code: ${participant.pinCode ?? 'N/A'}

Please log into the Admin Dashboard to review their full clinical responses.`;

            const htmlContent = `
                <div style="font-family: sans-serif; padding: 20px; color: #1e293b; max-width: 600px; margin: 0 auto; border: 1px solid #f3f4f6; border-radius: 12px; box-shadow: 0 4px 6px -1px rgb(0 0 0 / 0.05);">
                    <div style="background-color: #ef4444; color: white; padding: 16px; border-radius: 8px; text-align: center; margin-bottom: 24px;">
                        <h2 style="margin: 0; font-size: 20px; font-weight: bold; letter-spacing: 0.5px;">🚨 CRITICAL RISK DETECTED</h2>
                    </div>

                    <p style="font-size: 16px; line-height: 1.5; color: #374151; margin-bottom: 24px;">
                        A detailed Stage 3 assessment has been submitted that meets or exceeds the configured critical threshold.
                    </p>

                    <h3 style="border-bottom: 2px solid #f3f4f6; padding-bottom: 8px; color: #ef4444; font-size: 16px; font-weight: bold; margin-top: 24px;">Submission Summary</h3>
                    <table style="width: 100%; border-collapse: collapse; margin-bottom: 16px;">
                        <tr>
                            <td style="padding: 8px 0; font-weight: bold; color: #4b5563; width: 40%;">Submission ID:</td>
                            <td style="padding: 8px 0; color: #1f2937;">#${submission.id}</td>
                        </tr>
                        <tr>
                            <td style="padding: 8px 0; font-weight: bold; color: #4b5563;">Survey Category:</td>
                            <td style="padding: 8px 0; color: #1f2937; font-weight: 600;">${surveyCategory}</td>
                        </tr>
                        <tr>
                            <td style="padding: 8px 0; font-weight: bold; color: #4b5563;">Participant Score:</td>
                            <td style="padding: 8px 0; color: #ef4444; font-weight: bold; font-size: 16px;">${score}</td>
                        </tr>
                        <tr>
                            <td style="padding: 8px 0; font-weight: bold; color: #4b5563;">Critical Threshold:</td>
                            <td style="padding: 8px 0; color: #1f2937;">${criticalValue}</td>
                        </tr>
                        <tr>
                            <td style="padding: 8px 0; font-weight: bold; color: #4b5563;">Submission Time:</td>
                            <td style="padding: 8px 0; color: #1f2937;">${completionTime}</td>
                        </tr>
                    </table>

                    <h3 style="border-bottom: 2px solid #f3f4f6; padding-bottom: 8px; color: #1f2937; font-size: 16px; font-weight: bold; margin-top: 24px;">Participant Details</h3>
                    <table style="width: 100%; border-collapse: collapse; margin-bottom: 16px;">
                        <tr>
                            <td style="padding: 8px 0; font-weight: bold; color: #4b5563; width: 40%;">Name:</td>
                            <td style="padding: 8px 0; color: #1f2937;">${participant.name ?? 'N/A'}</td>
                        </tr>
                        <tr>
                            <td style="padding: 8px 0; font-weight: bold; color: #4b5563;">Email:</td>
                            <td style="padding: 8px 0; color: #1f2937;"><a href="mailto:${participant.email}" style="color: #3b82f6; text-decoration: none;">${participant.email}</a></td>
                        </tr>
                        <tr>
                            <td style="padding: 8px 0; font-weight: bold; color: #4b5563;">Phone Number:</td>
                            <td style="padding: 8px 0; color: #1f2937;">${participant.phoneNumber ?? 'N/A'}</td>
                        </tr>
                        <tr>
                            <td style="padding: 8px 0; font-weight: bold; color: #4b5563;">Age / Gender:</td>
                            <td style="padding: 8px 0; color: #1f2937;">${participant.age ?? 'N/A'} / ${participant.gender ?? 'N/A'}</td>
                        </tr>
                        <tr>
                            <td style="padding: 8px 0; font-weight: bold; color: #4b5563;">Occupation:</td>
                            <td style="padding: 8px 0; color: #1f2937;">${participant.occupation ?? 'N/A'}</td>
                        </tr>
                        <tr>
                            <td style="padding: 8px 0; font-weight: bold; color: #4b5563;">Marital Status:</td>
                            <td style="padding: 8px 0; color: #1f2937;">${participant.maritalStatus ?? 'N/A'}</td>
                        </tr>
                        <tr>
                            <td style="padding: 8px 0; font-weight: bold; color: #4b5563;">Pin Code:</td>
                            <td style="padding: 8px 0; color: #1f2937;">${participant.pinCode ?? 'N/A'}</td>
                        </tr>
                    </table>

                    <div style="margin-top: 32px; border-top: 1px solid #f3f4f6; padding-top: 16px; text-align: center;">
                        <p style="font-size: 14px; color: #4b5563; line-height: 1.5; margin-bottom: 12px;">
                            Please log into the <a href="${origin}/admin/submissions" style="color: #3b82f6; text-decoration: underline; font-weight: 500;">Admin Dashboard</a> to review their full clinical responses.
                        </p>
                        <p style="font-size: 12px; color: #9ca3af; margin-bottom: 0;">
                            This is an automated security system alert. Please do not reply to this email.
                        </p>
                    </div>
                </div>
            `;

            console.log(`[ALERTS] Dispatched critical risk alert email to ${adminEmail}`);
            const senderAddress = env.SMTP_FROM || env.SMTP_USER || 'alerts@novtek-atk.com';
            await transporter.sendMail({
                from: senderAddress,
                to: adminEmail,
                subject,
                text: textContent,
                html: htmlContent
            });

            // 4. Send Thank You email to respective participant
            // Introduce a safe delay (10 seconds) to prevent tripping Mailtrap Free Sandbox rate limits (max 5 emails/10 seconds)
            try {
                await new Promise(resolve => setTimeout(resolve, 10000));

                const participantEmail = participant.email;
                let participantSubject = 'Thank you for taking time for your wellbeing today';
                let participantTextContent = '';
                let participantHtmlContent = '';

                if (settings?.emailTemplate && settings.emailTemplate.subject && settings.emailTemplate.bodyHtml && settings.emailTemplate.bodyText) {
                    const template = settings.emailTemplate;
                    participantSubject = template.subject || '';
                    participantTextContent = template.bodyText || '';
                    participantHtmlContent = template.bodyHtml || '';
                } else {
                    const defaultTemplate = getDefaultEmailTemplate(surveyCategory);
                    participantSubject = defaultTemplate.subject;
                    participantTextContent = defaultTemplate.bodyText;
                    participantHtmlContent = defaultTemplate.bodyHtml;
                }

                console.log(`[ALERTS] Dispatching thank you email to participant ${participantEmail}`);
                await transporter.sendMail({
                    from: senderAddress,
                    to: participantEmail,
                    subject: participantSubject,
                    text: participantTextContent,
                    html: participantHtmlContent
                });
            } catch (participantError: any) {
                console.warn(`[ALERTS_WARN] Failed to send thank-you email to participant: ${participantError.message}`);
            }
        }
    } catch (error) {
        console.error(`[ALERTS_ERROR] Failed to run critical submission alert handler:`, error);
    }
}
