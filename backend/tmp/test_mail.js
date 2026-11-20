const nodemailer = require('nodemailer');
require('dotenv').config({ path: 'backend/.env' });

async function main() {
    const transporter = nodemailer.createTransport({
        host: process.env.SMTP_HOST,
        port: Number(process.env.SMTP_PORT),
        secure: process.env.SMTP_SECURE === 'true',
        auth: {
            user: process.env.SMTP_USER,
            pass: process.env.SMTP_PASS,
        },
        logger: true,
        debug: true,
    });

    try {
        console.log('Attempting to send email...');
        const info = await transporter.sendMail({
            from: process.env.SMTP_FROM,
            to: process.env.SMTP_USER, // Send to self for testing
            subject: 'Test Email',
            text: 'This is a test email.',
            html: '<p>This is a test email.</p>'
        });
        console.log('Email sent successfully:', info.messageId);
    } catch (e) {
        console.error('Failed to send email:', e);
    }
}

main();
