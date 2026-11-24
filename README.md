# Novtek ATK

Flutter wellbeing app in [app/](app/) with a SvelteKit API in [backend/](backend/).

## Start the backend locally

Install Node.js 22, Flutter, and Chrome. For the local test inbox, install Mailpit (`brew install mailpit` on macOS). From the repository root, run:

```sh
./run-local.sh
```

The launcher prepares the local SQLite database, starts the API at `http://localhost:8080`, and opens Flutter in Chrome. Request a code and read it in the Mailpit inbox at `http://127.0.0.1:8025`.

For real email delivery, run `./run-local.sh --real-email`. Press Enter to accept the Novtek SMTP host and port defaults, then enter your SMTP username, approved sender address, and password. The launcher verifies the credentials before starting the API.

To run the components separately, use `npm run mail:local` and `npm run dev:local` in separate terminals from `backend/`. Use `npm run dev:smtp` for a real SMTP provider. From `app/`, start Flutter with `flutter run -d chrome --dart-define=ATK_API_URL=http://localhost:8080`.

## Hosted backend

For hosting with MySQL, set `DATABASE_URL` to your MySQL connection string and initialize the database with `npm run db:push -- --schema=prisma/schema.mysql.prisma`. The [Render Blueprint](render.yaml) and [AWS deployment guide](AWS_DEPLOYMENT_GUIDE.md) use the MySQL schema.
