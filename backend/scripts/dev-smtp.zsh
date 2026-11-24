#!/bin/zsh
set -eu

read -r 'SMTP_HOST?SMTP host [novus.novtekconsulting.in]: '
SMTP_HOST=${SMTP_HOST:-novus.novtekconsulting.in}
read -r 'SMTP_PORT?SMTP port (465 or 587) [465]: '
SMTP_PORT=${SMTP_PORT:-465}
case "$SMTP_PORT" in
    465) SMTP_SECURE=true ;;
    587) SMTP_SECURE=false ;;
    *) print -u2 'Use port 465 for implicit TLS or 587 for STARTTLS.'; exit 1 ;;
esac
read -r 'SMTP_USER?SMTP username: '
read -r 'SMTP_FROM?Approved sender email: '
read -rs 'SMTP_PASS?SMTP password: '
printf '\n'

if [[ -z "$SMTP_USER" || -z "$SMTP_FROM" || -z "$SMTP_PASS" ]]; then
    print -u2 'SMTP username, approved sender email, and password are required.'
    exit 1
fi

export SMTP_HOST SMTP_PORT SMTP_SECURE SMTP_USER SMTP_FROM SMTP_PASS
node --input-type=module <<'JS'
import nodemailer from 'nodemailer';

const { SMTP_HOST, SMTP_PORT, SMTP_SECURE, SMTP_USER, SMTP_PASS } = process.env;
const transport = nodemailer.createTransport({
    host: SMTP_HOST,
    port: Number(SMTP_PORT),
    secure: SMTP_SECURE === 'true',
    requireTLS: SMTP_SECURE !== 'true',
    auth: { user: SMTP_USER, pass: SMTP_PASS },
    connectionTimeout: 10000,
    greetingTimeout: 10000,
    socketTimeout: 10000,
});
try {
    await transport.verify();
    console.log('SMTP connection and authentication verified.');
} catch (error) {
    console.error('SMTP verification failed:', error.code, error.responseCode ?? '');
    process.exitCode = 1;
} finally {
    transport.close();
}
JS

exec node --env-file=.env node_modules/vite/bin/vite.js dev --host 127.0.0.1 --port 8080 --strictPort
