#!/bin/sh
set -e

echo "Starting ATK Backend Container for AWS..."

schema=prisma/schema.prisma
case "$DATABASE_URL" in
    mysql://*|mysql2://*)
        schema=prisma/schema.mysql.prisma
        npx prisma generate --schema="$schema"
        ;;
esac

if [ -n "$DATABASE_URL" ] && [ "$SKIP_DB_PUSH" != "true" ]; then
    npx prisma db push --schema="$schema" --skip-generate || {
        echo "Warning: Database push encountered an issue, proceeding to start application..."
    }
fi

echo "Starting SvelteKit Node server on port ${PORT:-3000}..."
exec node build
