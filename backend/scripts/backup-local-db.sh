#!/usr/bin/env sh
set -eu
umask 077
script_dir=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
backup_dir="$script_dir/backups"
mkdir -p "$backup_dir"
stamp=$(date -u +%Y%m%dT%H%M%SZ)
docker compose -f "$script_dir/docker-compose.yml" exec -T db pg_dump -U atk -d atk -Fc > "$backup_dir/atk-$stamp.dump"
find "$backup_dir" -type f -name 'atk-*.dump' -mtime +7 -delete
printf 'Database backup written to %s\n' "$backup_dir/atk-$stamp.dump"
