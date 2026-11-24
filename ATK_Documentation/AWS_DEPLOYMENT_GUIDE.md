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
                         │   │  (Runs SvelteKit Node Container) │   │
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

## 3. Step 2: Deploy Backend Container

You can deploy the backend using either **AWS App Runner** (recommended: simplest, auto-scaling, managed SSL) or **AWS ECS Fargate**.

### Option A: AWS App Runner (Recommended)

1. In the **AWS Console**, navigate to **AWS App Runner** $\to$ **Create service**.
2. **Source**:
   - If using GitHub: Select **Source code repository**, connect your GitHub repo, select branch `main`, directory `/backend`, and configuration file `apprunner.yaml`.
   - If using Container Registry (ECR): Select **Container registry**, select your ECR image.
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

### Option B: AWS ECS (Elastic Container Service) with Fargate

1. **Build & Push to Amazon ECR**:
   ```bash
   # 1. Authenticate Docker with Amazon ECR
   aws ecr get-login-password --region eu-west-2 | docker login --username AWS --password-stdin <ACCOUNT_ID>.dkr.ecr.eu-west-2.amazonaws.com

   # 2. Build Docker Image
   docker build -t atk-backend ./backend

   # 3. Tag and Push
   docker tag atk-backend:latest <ACCOUNT_ID>.dkr.ecr.eu-west-2.amazonaws.com/atk-backend:latest
   docker push <ACCOUNT_ID>.dkr.ecr.eu-west-2.amazonaws.com/atk-backend:latest
   ```
2. **Register Task Definition**:
   Update `aws-task-definition.json` with your Account ID, Region, and Secrets Manager ARNs, then run:
   ```bash
   aws ecs register-task-definition --cli-input-json file://aws-task-definition.json
   ```
3. **Create Service**:
   Create an ECS Service running on Fargate with an Application Load Balancer (ALB) pointing to target port `3000` with health check path `/api/health`.

---

## 4. Step 3: CI/CD Pipeline (GitHub Actions)

We have created `.github/workflows/deploy-aws.yml`. To enable automated deployments on every git push:

1. In your GitHub repository, go to **Settings** $\to$ **Secrets and variables** $\to$ **Actions**.
2. Add the following repository secrets:
   - `AWS_ACCESS_KEY_ID`: IAM user access key with ECR and ECS deployment permissions.
   - `AWS_SECRET_ACCESS_KEY`: IAM user secret key.
3. Every push to the `main` branch will build the Docker container, push it to ECR, and update the ECS task definition.

---

## 5. Step 4: Configure Email Alerts (AWS SES)

1. In the **AWS Console**, navigate to **Amazon SES**.
2. Under **Verified identities**, verify your sending domain or email address.
3. Under **Account dashboard** $\to$ **SMTP settings**, click **Create SMTP credentials**.
4. Use the generated SMTP username and password in your environment variables.

---

## 6. Step 5: Connect the Flutter Mobile App

Update the API endpoint in the Flutter mobile application (`app/lib/config/api_config.dart`):

```dart
const String _defaultProdUrl = 'https://<YOUR-APP-RUNNER-OR-ALB-DOMAIN>/api';
```

Or build the Flutter app specifying the URL at compile time:
```bash
flutter build apk --dart-define=API_BASE_URL=https://<YOUR-AWS-DOMAIN>/api
```
