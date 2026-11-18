# Novtek ATK

Flutter wellbeing app in [`app/`](app/) with a PostgreSQL-backed API in [`backend/`](backend/).

## Start the backend locally

1. Install Docker and Node.js 22.18 or newer.
2. In `backend/`, copy `.env.example` to `.env`, replace `JWT_SECRET` with a long random value, and configure SMTP credentials from a transactional email provider.
3. Run `docker compose up --build`. This starts PostgreSQL and the API at `http://localhost:8080`; the database migration runs on first startup.
4. Verify your sender domain/address with an email provider, then set `SMTP_HOST`, `SMTP_PORT`, `SMTP_USER`, `SMTP_PASSWORD`, and `OTP_FROM_EMAIL` in `backend/.env`. Without these values, email requests fail closed; OTP codes are never returned by the app.

To run the API directly instead of in Docker, start only the database with `docker compose up -d db`, then run `npm ci`, `npm run db:generate`, `npm run migrate`, and `NODE_ENV=development npm run dev` from `backend/`. The development mode allows Flutter Web's changing localhost port; production mode continues to enforce the configured origin allowlist.

## Run the Flutter app against the API

```sh
cd app
flutter pub get
flutter run --dart-define=ATK_API_URL=http://localhost:8080
```

For the Android emulator, use `--dart-define=ATK_API_URL=http://10.0.2.2:8080`. For a physical phone, use the computer's LAN IP and allow the API port through the local firewall. Production builds should set `ATK_API_URL` to the deployed HTTPS API URL.

## API

- [Open the local API success page](http://localhost:8080/) — available when the local API is running.
- `GET /health/live` — API process status.
- `GET /health/ready` — API and database readiness.
- `POST /auth/send-otp` — `{ "email": "you@example.com", "role": "user" }`; sends a real email verification code.
- `POST /auth/verify-otp` — same fields plus `{ "otp": "123456" }`; returns short-lived access and refresh tokens after a valid code is entered.
- `POST /auth/refresh` — rotate a refresh token and issue a new access token.
- `POST /auth/logout` — revoke a supplied refresh token.
- `GET /user/profile` — authenticated profile read.
- `PUT /user/profile` — authenticated profile create/update.

Email OTP codes expire after 10 minutes, are stored only as keyed hashes, and are never logged or returned. The API limits each email to five requests per hour with a 60-second resend cooldown and five verification attempts per code. Access tokens are kept in platform secure storage by the app. Database models are defined in `backend/prisma/schema.prisma`; Prisma migrations live in `backend/prisma/migrations/`.

## Operations

The API uses Prisma Client for database queries and applies Prisma migrations on startup. Concurrent migration runs are coordinated by Prisma Migrate. `/health/live` is a process liveness check; `/health/ready` checks PostgreSQL and is suitable for a hosting platform's readiness probe. The API writes structured startup, migration, shutdown, and error logs to stdout/stderr for the platform log collector.

For a local snapshot, run `sh backend/scripts/backup-local-db.sh` while Docker Compose is up. It writes a compressed dump under `backend/backups/`, limits permissions, and prunes dumps older than seven days. Restore locally with `docker compose -f backend/docker-compose.yml exec -T db pg_restore -U atk -d atk --clean --if-exists < backend/backups/<dump-file>`. Keep backups outside Git. Before production, enable automated encrypted backups and point-in-time recovery with the managed PostgreSQL provider, define retention, and test restore into a separate database.

For a public launch, use managed PostgreSQL with TLS, a transactional email provider, HTTPS hosting, strong unique secrets, `NODE_ENV=production`, an explicit `APP_ORIGINS` allowlist, and `PGSSL=true` when required by the database provider. Set `TRUST_PROXY=1` only behind a single trusted reverse proxy so IP-based rate limits use client IPs correctly. Configure an uptime check against `/health/ready`, alert on failed health checks and elevated 5xx responses, and review provider logs for API errors. The local Docker credentials are development-only.

For a hosted launch, use the [deployment guide](backend/DEPLOYMENT.md) and review `render.yaml`. Creating hosted resources can incur charges; the Blueprint has not been deployed.
# atk
