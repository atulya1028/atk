export interface EmailTemplateData {
    subject: string;
    bodyHtml: string;
    bodyText: string;
}

export function getDefaultEmailTemplate(category: string): EmailTemplateData {
    const isMental = category.toUpperCase() === 'MENTAL';

    const subject = 'Thank you for taking time for your wellbeing today';

    const bodyHtml = isMental ? `
<div style="font-family: sans-serif; padding: 24px; color: #1e293b; max-width: 600px; margin: 0 auto; border: 1px solid #f3f4f6; border-radius: 12px; box-shadow: 0 4px 6px -1px rgb(0 0 0 / 0.05); line-height: 1.6;">
    <div style="background-color: #4f46e5; color: white; padding: 20px; border-radius: 8px; text-align: center; margin-bottom: 24px;">
        <h2 style="margin: 0; font-size: 20px; font-weight: bold; letter-spacing: 0.5px;">Thank You</h2>
    </div>

    <p style="font-size: 15px; color: #374151; margin-bottom: 16px;">Hello,</p>
    <p style="font-size: 15px; color: #374151; margin-bottom: 16px;">
        Thank you for completing your detailed assessment step today. Prioritizing space to look inward and reflect on our habits is a massive step in itself.
    </p>
    <p style="font-size: 15px; color: #374151; margin-bottom: 16px;">
        As you continue forward, remember this simple truth:
    </p>

    <div style="background-color: #f8fafc; border-left: 4px solid #4f46e5; padding: 16px; margin: 20px 0; border-radius: 4px;">
        <p style="font-style: italic; font-size: 15px; color: #1e293b; margin: 0; line-height: 1.6;">
            "Small healthy habits every day lead to big changes over time."
        </p>
    </div>

    <p style="font-size: 15px; color: #374151; margin-bottom: 16px;">
        Improving our health isn't about massive, overnight shifts—it's about small, gentle steps in the right direction.
    </p>
    <p style="font-size: 15px; color: #374151; margin-bottom: 16px;">
        To support your path, we’ve put together a few excellent, completely free self-help tools and resources authorized by the UK National Health Service (NHS). These guides are entirely self-directed and designed to easily fit into your everyday routine:
    </p>

    <ul style="padding-left: 20px; margin-bottom: 24px; color: #374151; font-size: 15px;">
        <li style="margin-bottom: 12px; line-height: 1.6;">
            <a href="https://www.nhs.uk/every-mind-matters/" style="color: #4f46e5; text-decoration: underline; font-weight: 600;">Every Mind Matters (NHS Guides & Tips)</a> – Simple steps, breathing exercises, and personalized action plans to navigate everyday stress, anxiety, or low mood.
        </li>
        <li style="margin-bottom: 12px; line-height: 1.6;">
            <a href="https://www.nhs.uk/mental-health/self-help/" style="color: #4f46e5; text-decoration: underline; font-weight: 600;">NHS Self-Help Guides & Audio Hub</a> – Practical, evidence-based activities and audio sessions to clear your head and build resilience at your own pace.
        </li>
        <li style="margin-bottom: 12px; line-height: 1.6;">
            <a href="https://www.nhs.uk/tests-and-treatments/talking-therapies/" style="color: #4f46e5; text-decoration: underline; font-weight: 600;">Find Free Local Support (NHS Talking Therapies)</a> – If you ever want an open, non-judgmental professional ear, the NHS allows anyone registered with a UK GP to securely self-refer to confidential talking therapy services online for free.
        </li>
    </ul>

    <p style="font-size: 15px; color: #374151; margin-bottom: 24px;">
        Keep taking care of yourself, one day at a time.
    </p>

    <p style="font-size: 15px; color: #374151; margin-bottom: 0;">
        Warm regards,<br />
        <strong>The ATK Support Team</strong>
    </p>

    <div style="margin-top: 32px; border-top: 1px solid #f3f4f6; padding-top: 16px; text-align: center;">
        <p style="font-size: 12px; color: #9ca3af; margin-bottom: 0;">
            This is an automated system notification. Please do not reply to this email.
        </p>
    </div>
</div>
` : `
<div style="font-family: sans-serif; padding: 24px; color: #1e293b; max-width: 600px; margin: 0 auto; border: 1px solid #f3f4f6; border-radius: 12px; box-shadow: 0 4px 6px -1px rgb(0 0 0 / 0.05); line-height: 1.6;">
    <div style="background-color: #4f46e5; color: white; padding: 20px; border-radius: 8px; text-align: center; margin-bottom: 24px;">
        <h2 style="margin: 0; font-size: 20px; font-weight: bold; letter-spacing: 0.5px;">Thank You</h2>
    </div>

    <p style="font-size: 15px; color: #374151; margin-bottom: 16px;">Hello,</p>
    <p style="font-size: 15px; color: #374151; margin-bottom: 16px;">
        Thank you for completing your detailed assessment step today. Prioritizing space to look inward and reflect on our habits is a massive step in itself.
    </p>
    <p style="font-size: 15px; color: #374151; margin-bottom: 16px;">
        As you continue forward, remember this simple truth:
    </p>

    <div style="background-color: #f8fafc; border-left: 4px solid #4f46e5; padding: 16px; margin: 20px 0; border-radius: 4px;">
        <p style="font-style: italic; font-size: 15px; color: #1e293b; margin: 0; line-height: 1.6;">
            "Small healthy habits every day lead to big changes over time."
        </p>
    </div>

    <p style="font-size: 15px; color: #374151; margin-bottom: 16px;">
        Improving our health isn't about massive, overnight shifts—it's about small, gentle steps in the right direction.
    </p>
    <p style="font-size: 15px; color: #374151; margin-bottom: 16px;">
        To support your path, we’ve put together a few excellent, completely free self-help tools and resources authorized by the UK National Health Service (NHS). These guides are entirely self-directed and designed to easily fit into your everyday routine:
    </p>

    <ul style="padding-left: 20px; margin-bottom: 24px; color: #374151; font-size: 15px;">
        <li style="margin-bottom: 12px; line-height: 1.6;">
            <a href="https://www.talktofrank.com/" style="color: #4f46e5; text-decoration: underline; font-weight: 600;">Frank (Honest Information About Drugs)</a> – The official UK national advisory platform providing totally confidential, non-judgmental information, self-help tools, and a 24/7 helpline regarding substances and their effects.
        </li>
        <li style="margin-bottom: 12px; line-height: 1.6;">
            <a href="https://www.nhs.uk/live-well/alcohol-advice/alcohol-support/" style="color: #4f46e5; text-decoration: underline; font-weight: 600;">NHS Alcohol & Substance Support Services</a> – The primary NHS directory helping individuals locate free, confidential local community support frameworks and interactive self-assessment tracking tools.
        </li>
        <li style="margin-bottom: 12px; line-height: 1.6;">
            <a href="https://www.wearewithyou.org.uk/" style="color: #4f46e5; text-decoration: underline; font-weight: 600;">WithYou (Free Confidential Support)</a> – One of the UK’s largest NHS-commissioned health charities providing free, confidential web chat support, self-help toolkits, and localized advice for managing alcohol and substance habits safely.
        </li>
    </ul>

    <p style="font-size: 15px; color: #374151; margin-bottom: 24px;">
        Keep taking care of yourself, one day at a time.
    </p>

    <p style="font-size: 15px; color: #374151; margin-bottom: 0;">
        Warm regards,<br />
        <strong>The ATK Support Team</strong>
    </p>

    <div style="margin-top: 32px; border-top: 1px solid #f3f4f6; padding-top: 16px; text-align: center;">
        <p style="font-size: 12px; color: #9ca3af; margin-bottom: 0;">
            This is an automated system notification. Please do not reply to this email.
        </p>
    </div>
</div>
`;

    const bodyText = isMental ? `Hello,

Thank you for completing your detailed assessment step today. Prioritizing space to look inward and reflect on our habits is a massive step in itself.

As you continue forward, remember this simple truth:
"Small healthy habits every day lead to big changes over time."

Improving our health isn't about massive, overnight shifts—it's about small, gentle steps in the right direction.

To support your path, we’ve put together a few excellent, completely free self-help tools and resources authorized by the UK National Health Service (NHS). These guides are entirely self-directed and designed to easily fit into your everyday routine:

• Every Mind Matters (NHS Guides & Tips) – Simple steps, breathing exercises, and personalized action plans to navigate everyday stress, anxiety, or low mood. (https://www.nhs.uk/every-mind-matters/)

• NHS Self-Help Guides & Audio Hub – Practical, evidence-based activities and audio sessions to clear your head and build resilience at your own pace. (https://www.nhs.uk/mental-health/self-help/)

• Find Free Local Support (NHS Talking Therapies) – If you ever want an open, non-judgmental professional ear, the NHS allows anyone registered with a UK GP to securely self-refer to confidential talking therapy services online for free. (https://www.nhs.uk/tests-and-treatments/talking-therapies/)

Keep taking care of yourself, one day at a time.

Warm regards,
The ATK Support Team` : `Hello,

Thank you for completing your detailed assessment step today. Prioritizing space to look inward and reflect on our habits is a massive step in itself.

As you continue forward, remember this simple truth:
"Small healthy habits every day lead to big changes over time."

Improving our health isn't about massive, overnight shifts—it's about small, gentle steps in the right direction.

To support your path, we’ve put together a few excellent, completely free self-help tools and resources authorized by the UK National Health Service (NHS). These guides are entirely self-directed and designed to easily fit into your everyday routine:

• Frank (Honest Information About Drugs) – The official UK national advisory platform providing totally confidential, non-judgmental information, self-help tools, and a 24/7 helpline regarding substances and their effects. (https://www.talktofrank.com/)

• NHS Alcohol & Substance Support Services – The primary NHS directory helping individuals locate free, confidential local community support frameworks and interactive self-assessment tracking tools. (https://www.nhs.uk/live-well/alcohol-advice/alcohol-support/)

• WithYou (Free Confidential Support) – One of the UK’s largest NHS-commissioned health charities providing free, confidential web chat support, self-help toolkits, and localized advice for managing alcohol and substance habits safely. (https://www.wearewithyou.org.uk/)

Keep taking care of yourself, one day at a time.

Warm regards,
The ATK Support Team`;

    return { subject, bodyHtml, bodyText };
}
