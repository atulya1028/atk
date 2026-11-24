#!/bin/bash
set -euo pipefail

case "${1:-}" in
    '') real_email=false ;;
    --real-email) real_email=true ;;
    -h|--help)
        echo 'Usage: ./run-local.sh [--real-email]'
        echo 'Default: start the API, Mailpit, and Flutter in Chrome.'
        echo '--real-email: prompt for SMTP credentials and use your provider.'
        exit 0 ;;
    *) echo 'Usage: ./run-local.sh [--real-email]' >&2; exit 2 ;;
esac

cd "$(dirname "$0")"
project_dir=$PWD

if lsof -nP -iTCP:8080 -sTCP:LISTEN >/dev/null; then
    echo 'Port 8080 is already in use. Stop the previous backend with Ctrl+C and rerun this command.' >&2
    lsof -nP -iTCP:8080 -sTCP:LISTEN >&2
    exit 1
fi

api_pid=
mail_pid=
cleanup() {
    if [ -n "$api_pid" ]; then kill "$api_pid" 2>/dev/null || true; fi
    if [ -n "$mail_pid" ]; then kill "$mail_pid" 2>/dev/null || true; fi
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

cd backend
if [ ! -f .env ]; then
    sed "s/^JWT_SECRET=$/JWT_SECRET=$(openssl rand -hex 32)/" .env.example > .env
fi
if [ ! -x node_modules/.bin/prisma ]; then
    npm ci
fi
if ! grep -q '^DATABASE_URL=' .env; then
    echo 'Set DATABASE_URL in backend/.env before starting the API.' >&2
    exit 1
fi
if grep -Eq '^DATABASE_URL="?file:\./dev\.db"?$' .env && [ ! -e prisma/dev.db ]; then
    sqlite3 prisma/dev.db 'PRAGMA user_version = 0;'
fi
npm run db:generate
npm run db:push -- --skip-generate

if [ "$real_email" = true ]; then
    zsh scripts/dev-smtp.zsh </dev/tty &
else
    if ! curl -fsS --max-time 2 http://127.0.0.1:8025/api/v1/messages >/dev/null; then
        mailpit --smtp 127.0.0.1:1025 --listen 127.0.0.1:8025 &
        mail_pid=$!
        if ! curl -fsS --retry 5 --retry-connrefused --retry-delay 1 --max-time 2 \
            http://127.0.0.1:8025/api/v1/messages >/dev/null 2>&1; then
            echo 'Mailpit failed to start. Check that it is installed and ports 1025 and 8025 are available.' >&2
            exit 1
        fi
    fi
    echo 'Local OTP inbox: http://127.0.0.1:8025'
    SMTP_HOST=127.0.0.1 SMTP_PORT=1025 SMTP_SECURE=false SMTP_USER= SMTP_PASS= \
        SMTP_FROM='ATK Local <no-reply@atk.test>' \
        node --env-file=.env node_modules/vite/bin/vite.js dev --host 127.0.0.1 --port 8080 --strictPort &
fi
api_pid=$!

# Wait for the API. In real-email mode this also gives the user time to enter credentials.
while true; do
    api_status=$(curl -s --max-time 2 -o /dev/null -w '%{http_code}' http://127.0.0.1:8080/api/health || true)
    if [ "$api_status" = 200 ]; then break; fi
    if [ "$api_status" = 503 ]; then
        echo 'The API started but could not connect to the database. Check backend/.env.' >&2
        exit 1
    fi
    if ! kill -0 "$api_pid" 2>/dev/null; then
        wait "$api_pid"
        exit 1
    fi
    sleep 1
done

cd "$project_dir/app"
flutter run -d chrome --dart-define=ATK_API_URL=http://localhost:8080
