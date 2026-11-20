# Novtek ATK — Technical Architecture & Project Summary

## 1. Executive Project Summary

- **Clinical Purpose:** Novtek ATK is a comprehensive healthcare screening and well-being platform designed to facilitate early identification, confidential tracking, and clinical triage of substance dependency and mental health conditions.
- **Multi-Track Architecture:**
  - **Patient Track:** Confidential self-assessments (Initial 26-question baseline assessment, standalone mental health screenings, unlocked Stage 3 Detailed addiction assessment), demographic onboarding, and daily well-being check-ins (Emotional well-being, Anxiety & worry, Stress management, Sleep & relaxation).
  - **Doctor / Clinician Track:** Real-time clinical portal allowing authenticated practitioners to monitor participants within their geographical coverage areas (pincodes / postcodes) and immediately identify participants flagged with critical clinical risk.
- **Security & Privacy First:** Passwordless email authentication via cryptographic single-use HMAC-SHA256 OTP verification codes with strict rate-limiting, short-lived JWT access tokens, and encrypted refresh token rotation.
- **Adaptive Screening Progression:** Staged assessment engine enforcing prerequisites where detailed clinical assessments unlock only when earlier screening milestones meet designated severity score thresholds.
- **Doctor Coverage Matching:** Clinicians configure comma-separated postal codes; the system automatically aggregates patient assessments and filters matching participants into active triage cohorts.

---

## 2. Frontend Tech Stack (Flutter Mobile, Desktop & Web)

| Layer / Component | Package / Technology | Description & Implementation Details |
|---|---|---|
| **Core Framework** | `Flutter SDK (Dart 3.14+)` | Single codebase client compiling natively to macOS, iOS, Android, and Web. |
| **State Management** | `flutter_bloc: ^9.1.1` | Predictable, reactive Cubit architecture (`LoginCubit`, `IntroCubit`, `WellbeingCubit`, `HomeCubit`, `AddictionDashboardCubit`). |
| **Responsive Scaling** | `flutter_screenutil: ^5.9.3` | Device-independent pixel scaling with base geometry `390 × 844` for fluid typography and responsive controls. |
| **Design System** | `material_ui: ^1.1.0`<br>`cupertino_ui: ^1.1.6` | Custom Material 3 theme palette: Primary Teal (`#197278`), Dark Slate (`#283D3B`), Alert Coral (`#C44536`), and Canvas (`#F9FAFB`). |
| **Secure Persistence** | `flutter_secure_storage: ^9.2.4` | Platform-level hardware/keychain-backed encrypted storage for session tokens (`atk_access_token`, `atk_refresh_token`). |
| **HTTP & API Client** | `http: ^1.5.0` | Custom `ApiClient` and `DoctorService` with automatic JWT authorization header injection, 401 token refresh interception, and timeout guards. |
| **Modular Structure** | `app/lib/patient/`<br>`app/lib/doctor/` | Clear domain boundaries separating patient onboarding/surveys from clinician dashboards, filters, and profile management. |

---

## 3. Backend Tech Stack (Node.js & PostgreSQL)

| Component | Technology | Description & Functionality |
|---|---|---|
| **Runtime & Server** | `Node.js >= 22.18`<br>`express: ^5.1.0` | Lightweight, fast ES-module backend using modern Express 5 with async route error propagators. |
| **Database & Engine** | `PostgreSQL`<br>`@prisma/adapter-pg: ^7.10.1` | Relational database utilizing connection pooling for low-latency queries and transaction isolation. |
| **Object-Relational Map** | `Prisma ORM: ^7.10.1` | Type-safe client generation, migrations tracking, and schema definitions for users, profiles, challenges, and survey submissions. |
| **Concurrency & Locking** | `pg_advisory_xact_lock` | PostgreSQL transaction-level advisory locks preventing race conditions during OTP verification and survey draft completion. |
| **Authentication & JWT** | `jsonwebtoken: ^9.0.2` | Cryptographically signed HMAC-SHA256 JWTs with 1-hour access validity, role segregation (`user` vs. `doctor`), and refresh token rotation. |
| **Input Validation** | `zod: ^4.1.5` | Strict runtime validation and schema enforcement on emails, authentication payloads, survey responses, and profile inputs. |
| **Security & Hardening** | `helmet: ^8.1.0`<br>`express-rate-limit: ^8.1.0` | HTTP header protection, origin allowlisting (`APP_ORIGINS`), 5 requests/hour OTP limits, and 60-second cooldown per target email. |
| **Mailing Service** | `nodemailer: ^10.6.0` | SMTP transactional transport delivering single-use 6-digit verification codes valid for 10 minutes. |
| **DevOps & Deploy** | `Docker` & `docker-compose.yml` | Containerized PostgreSQL and API service with health checks (`/health/live`, `/health/ready`) and backup scripts. |

---

## 4. Command Line Arguments & Quick Start Reference

### Backend Execution Commands

```bash
# 1. Install dependencies
cd backend && npm install

# 2. Start PostgreSQL in background (Docker)
docker compose up -d db

# 3. Generate Prisma client & apply database migrations
npm run db:generate
npm run migrate

# 4. Seed question bank into PostgreSQL
npm run db:seed-questions

# 5. Start API server in Development Mode (Hot Reload)
npm run dev

# 6. Start API server on a Custom Port (e.g. 8080 or 4000)
PORT=8080 npm run dev

# 7. Run full syntax and module check
npm run check
```

### Flutter Client Execution Commands

```bash
# 1. Fetch dependencies and run static code analysis
cd app && flutter pub get
flutter analyze

# 2. Run on macOS Desktop connected to local backend (port 8080)
flutter run -d macos --dart-define=ATK_API_URL=http://localhost:8080

# 3. Run in Google Chrome (Web)
flutter run -d chrome --dart-define=ATK_API_URL=http://localhost:8080

# 4. Run on Android Emulator (10.0.2.2 routes to host machine)
flutter run -d android --dart-define=ATK_API_URL=http://10.0.2.2:8080

# 5. Run on Physical Mobile Device over Local Wi-Fi
flutter run --dart-define=ATK_API_URL=http://<YOUR_COMPUTER_LAN_IP>:8080

# 6. Production Builds (Release Mode with HTTPS Endpoint)
flutter build apk --release --dart-define=ATK_API_URL=https://api.yourdomain.com
flutter build appbundle --release --dart-define=ATK_API_URL=https://api.yourdomain.com
flutter build macos --release --dart-define=ATK_API_URL=https://api.yourdomain.com
flutter build web --release --dart-define=ATK_API_URL=https://api.yourdomain.com
```
