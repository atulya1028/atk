# AWS Deployment Guide for Novtek ATK Platform

This guide outlines how to deploy the **ATK SvelteKit Backend & Database** to Amazon Web Services (AWS).

---

## Architecture Overview

```
                         ┌────────────────────────────────────────┐
                         │           AWS Cloud Platform           │
                         │                                        │
  [ Flutter App /        │   ┌────────────────────────────────┐   │
    Web Admin Users ] ──────▶│ AWS App Runner / ECS (Fargate) │   │
                         │   │  (Runs SvelteKit Node Server) │   │
                         │   └───────────────┬────────────────┘   │
                         │                   │                    │
                         │                   ▼                    │
                         │   ┌────────────────────────────────┐   │
                         │   │   AWS RDS (MySQL 8.0 Engine)   │   │
                         │   └────────────────────────────────┘   │
                         │                   │                    │
                         │                   ▼                    │
                         │   ┌────────────────────────────────┐   │
                         │   │ AWS SES (Simple Email Service) │   │
                         │   └────────────────────────────────┘   │
                         └────────────────────────────────────────┘
```

---

## 1. Prerequisites on AWS

1. **AWS Account**: Active AWS Account with administrative access.
2. **AWS Region**: Recommended: `eu-west-2` (London) or your nearest region (e.g. `us-east-1`, `ap-south-1`).

---

## 2. Step 1: Provision AWS RDS MySQL Database

1. In the **AWS Console**, navigate to **Amazon RDS** $\to$ **Databases** $\to$ **Create database**.
2. Select:
   - **Engine type**: MySQL (version `8.0` or higher).
   - **Templates**: *Free tier* (for testing) or *Production*.
   - **DB instance identifier**: `atk-mysql-db`.
   - **Master username**: `admin`.
   - **Master password**: Generate a secure password (store securely).
   - **Public access**: *Yes* (or *No* if deploying App Runner/ECS inside the same VPC).
   - **Initial database name**: `atk_backend`.
3. Once created, copy the **Endpoint** (e.g., `atk-mysql-db.c3xyz.eu-west-2.rds.amazonaws.com`).
4. Format your database connection URL:
   ```bash
   DATABASE_URL="mysql://admin:<PASSWORD>@<RDS_ENDPOINT>:3306/atk_backend"
   ```

---

## 3. Step 2: Deploy Backend from Source

1. In the **AWS Console**, navigate to **AWS App Runner** $\to$ **Create service**.
2. **Source**:
   - Select **Source code repository**, connect your GitHub repo, select branch `main` and source directory `/backend`, and use the repository configuration file `apprunner.yaml`.
   - With access to the MySQL database and `DATABASE_URL` set, initialize the schema from `backend/` using `npm run db:push -- --schema=prisma/schema.mysql.prisma`.
3. **Environment variables**:
   Set the following variables in the App Runner console:
   - `DATABASE_URL`: Your AWS RDS MySQL connection string.
   - `PORT`: `3000`
   - `NODE_ENV`: `production`
   - `JWT_SECRET`: Random 64-char string.
   - `ADMIN_PASSWORD`: Your secret admin password.
   - `ADMIN_NOTIFICATION_EMAIL`: Email to receive critical risk submission alerts.
   - `SMTP_HOST`: `email-smtp.<region>.amazonaws.com` (or your existing SMTP host).
   - `SMTP_PORT`: `465`
   - `SMTP_SECURE`: `true`
   - `SMTP_USER`: Your AWS SES SMTP username.
   - `SMTP_PASS`: Your AWS SES SMTP password.
   - `SMTP_FROM`: `"ATK Support" <no-reply@yourdomain.com>`
4. **Health check**:
   - Protocol: `HTTP`
   - Path: `/api/health`
5. Click **Deploy**. App Runner will provide a live HTTPS URL (e.g., `https://xyz.eu-west-2.awsapprunner.com`).

---

## 4. Step 3: Configure Email Alerts (AWS SES)

1. In the **AWS Console**, navigate to **Amazon SES**.
2. Under **Verified identities**, verify your sending domain or email address.
3. Under **Account dashboard** $\to$ **SMTP settings**, click **Create SMTP credentials**.
4. Use the generated SMTP username and password in your environment variables.

---

## 5. Step 4: Connect the Flutter Mobile App

Build the Flutter app with the deployed backend URL:

```sh
cd app
flutter build apk --dart-define=ATK_API_URL=https://<YOUR-AWS-DOMAIN>
```
