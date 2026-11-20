const nodemailer = require('nodemailer');
const dotenv = require('dotenv');
const fs = require('fs');
const path = require('path');

// Try to load .env from the backend root
const envPath = path.resolve(__dirname, '../.env');
if (fs.existsSync(envPath)) {
    dotenv.config({ path: envPath });
}

async function main() {
    const transporter = nodemailer.createTransport({
        host: process.env.SMTP_HOST || 'novus.novtekconsulting.in',
        port: Number(process.env.SMTP_PORT) || 465,
        secure: process.env.SMTP_SECURE === 'true' || true,
        auth: {
            user: process.env.SMTP_USER || 'no-reply@novus.novtekconsulting.in',
            pass: process.env.SMTP_PASS || 'xJUDQeNpNT9IhmXqB8',
        },
        logger: true,
        debug: true,
    });

    try {
        console.log('Attempting to send email...');
        console.log('Using SMTP Config:', {
            host: process.env.SMTP_HOST,
            port: process.env.SMTP_PORT,
            user: process.env.SMTP_USER,
            from: process.env.SMTP_FROM
        });

        const info = await transporter.sendMail({
            from: process.env.SMTP_FROM || '"ATK Support" <no-reply@novus.novtekconsulting.in>',
            to: (process.env.SMTP_USER || 'no-reply@novus.novtekconsulting.in'),
            subject: 'Test Email from ATK script',
            text: 'This is a test email.',
            html: '<p>This is a test email.</p>'
        });
        console.log('Email sent successfully:', info.messageId);
    } catch (e) {
        console.error('Failed to send email:', e);
    }
}

main();
