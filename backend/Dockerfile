# ==========================================
# Multi-stage Dockerfile for AWS Deployment
# Compatible with AWS App Runner, ECS, ECR, Elastic Beanstalk
# ==========================================

# 1. Build Stage
FROM node:22-alpine AS builder

WORKDIR /app

# Install system dependencies needed for native modules / Prisma
RUN apk add --no-cache openssl libc6-compat

# Copy package management files
COPY package*.json ./
COPY prisma ./prisma/

# Install all dependencies (including devDependencies needed for build)
RUN npm ci

# Generate Prisma Client
RUN npx prisma generate

# Copy the rest of the application code
COPY . .

# Build SvelteKit application with Node adapter
RUN npm run build

# Prune development dependencies
RUN npm prune --production

# ==========================================
# 2. Production Runner Stage
# ==========================================
FROM node:22-alpine AS runner

WORKDIR /app

# Install runtime dependencies (OpenSSL is needed by Prisma on Alpine)
RUN apk add --no-cache openssl libc6-compat

# Set production environment variables
ENV NODE_ENV=production
ENV PORT=3000
ENV HOST=0.0.0.0

# Create a non-root system user for security
RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 sveltekit

# Copy package and node_modules from builder
COPY --from=builder --chown=sveltekit:nodejs /app/package.json ./package.json
COPY --from=builder --chown=sveltekit:nodejs /app/node_modules ./node_modules
COPY --from=builder --chown=sveltekit:nodejs /app/prisma ./prisma
COPY --from=builder --chown=sveltekit:nodejs /app/build ./build

# Copy startup script
COPY --chown=sveltekit:nodejs docker-entrypoint.sh ./docker-entrypoint.sh
RUN chmod +x ./docker-entrypoint.sh

USER sveltekit

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD wget -qO- http://localhost:3000/api/health || exit 1

ENTRYPOINT ["./docker-entrypoint.sh"]
