# Backend Implementation Plan

## Objective
Create a Svelte-based backend application to serve the Flutter mobile app. The backend will manage survey questions, users, and submissions.

## Tech Stack
- **Framework**: SvelteKit (Full-stack web framework)
- **Database**: MySQL
- **ORM**: Prisma (Type-safe database interaction)
- **Styling**: Tailwind CSS (For the Admin Dashboard)
- **Runtime**: Node.js

## Architecture

### Database Schema (Prisma)
We will use a relational schema to track users, surveys, and answers.
Connection String Concept: `mysql://root:Whoareyou%401989%23@localhost:3306/atk_backend`

```prisma
datasource db {
  provider = "mysql"
  url      = env("DATABASE_URL")
}

generator client {
  provider = "prisma-client-js"
}

// User (Respondent)
model User {
  id        Int      @id @default(autoincrement())
  email     String   @unique
  otp       String?  // Temporary OTP storage (hashed in production, plain for now)
  createdAt DateTime @default(now())
  submissions Submission[]
}

// Survey Questions
model Question {
  id          Int      @id @default(autoincrement())
  slug        String   @unique // The 'id' expected by the app (e.g. 'param_gender')
  text        String   // properties -> text
  description String?
  type        String   // 'select', 'multi_select', 'text', 'number', 'yesno'
  order       Int      @default(0)
  options     Option[]
  
  answers     Answer[]
}

// Options for 'select'/'multi_select' questions
model Option {
  id         Int      @id @default(autoincrement())
  label      String
  value      String
  questionId Int
  question   Question @relation(fields: [questionId], references: [id])
}

// A generic container for a user's survey attempt
model Submission {
  id        Int      @id @default(autoincrement())
  userId    Int
  user      User     @relation(fields: [userId], references: [id])
  startedAt DateTime @default(now())
  completedAt DateTime?
  answers   Answer[]
}

// Individual Answers
model Answer {
  id           Int      @id @default(autoincrement())
  submissionId Int
  submission   Submission @relation(fields: [submissionId], references: [id])
  questionId   Int
  question     Question   @relation(fields: [questionId], references: [id])
  value        String   // JSON string or simple value
}
```

### API Endpoints
These endpoints will mimic the expectations of the Flutter App (`SurveyApiService.dart`).

1.  **POST `/api/send-otp`**
    *   **Body**: `{ email: string }`
    *   **Action**: Generate OTP, find/create User, save OTP.
    *   **Response**: `{ debug_otp: string }` (for easier testing in dev).

2.  **POST `/api/verify-otp`**
    *   **Body**: `{ email: string, otp: string }`
    *   **Action**: Verify OTP. Issue generic token (or just return success for this simple scope).
    *   **Response**: `{ token: string, user: ... }`

3.  **POST `/api/surveys/start`**
    *   **Headers**: `Authorization: Bearer <token>`
    *   **Action**: Validate User. Create a new `Submission` record.
    *   **Response**: `{ data: { id: submissionId, answers: [] }, user_stats: {...} }`

4.  **GET `/api/surveys/questions`**
    *   **Headers**: `Authorization: Bearer <token>`
    *   **Action**: Fetch all `Question` records with `Option`s.
    *   **Response**: `{ success: true, questions: [ { id, text, type, options: [...] }, ... ] }`

5.  **POST `/api/surveys/answer`**
    *   **Headers**: `Authorization: Bearer <token>`
    *   **Body**: `{ submission_id, question_slug, value }`
    *   **Action**: Find Question by slug. Record Answer linked to Submission.
    *   **Response**: `200 OK`.

### Admin Dashboard (Frontend)
Located at `/admin` layout.
1.  **Dashboard**: View total users, submissions.
2.  **Questions Manager**:
    *   List all questions.
    *   Form to Add/Edit Question (Slug, Text, Type, Options).
    *   Reorder questions.
3.  **Review Submissions**: See what users have answered.

## Implementation Steps
1.  **Setup**: Initialize SvelteKit project in `backend`. Install Tailwind, Prisma using `sqlite`.
2.  **Database**: Define schema `schema.prisma` and run migration.
3.  **Seed**: Create a seed script to populate initial questions (e.g. from the Flutter app's fallback/logic).
4.  **API**: Implement the SvelteKit API routes (`+server.ts`).
5.  **Admin UI**: Build the management interface.
