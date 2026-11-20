#!/usr/bin/env node

/**
 * Database Setup Script
 * 
 * Usage:
 *   node scripts/setup-db.mjs              # Default: SQLite
 *   node scripts/setup-db.mjs sqlite       # Explicit SQLite
 *   node scripts/setup-db.mjs mysql        # MySQL (production)
 * 
 * What it does:
 *   1. Copies the correct Prisma schema (sqlite or mysql) to schema.prisma
 *   2. Sets the DATABASE_URL in .env if not already configured
 *   3. Runs prisma generate + prisma db push
 *   4. Optionally seeds the database
 */

import { execSync } from 'child_process';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const ROOT = path.resolve(__dirname, '..');

const PRISMA_DIR = path.join(ROOT, 'prisma');
const ENV_FILE = path.join(ROOT, '.env');

const provider = (process.argv[2] || 'sqlite').toLowerCase();

if (!['sqlite', 'mysql'].includes(provider)) {
    console.error(`Unknown provider: "${provider}". Use "sqlite" or "mysql".`);
    process.exit(1);
}

console.log(`\nSetting up database: ${provider.toUpperCase()}\n`);

// Step 1: Copy the correct schema
const schemaSource = provider === 'sqlite'
    ? path.join(PRISMA_DIR, 'schema.sqlite.prisma')
    : path.join(PRISMA_DIR, 'schema.mysql.prisma');

const schemaDest = path.join(PRISMA_DIR, 'schema.prisma');

if (!fs.existsSync(schemaSource)) {
    console.error(`Schema file not found: ${schemaSource}`);
    process.exit(1);
}

fs.copyFileSync(schemaSource, schemaDest);
console.log(`Copied ${path.basename(schemaSource)} -> schema.prisma`);

// Step 2: Ensure .env has the right DATABASE_URL
let envContent = '';
if (fs.existsSync(ENV_FILE)) {
    envContent = fs.readFileSync(ENV_FILE, 'utf-8');
}

if (provider === 'sqlite') {
    const sqliteUrl = `file:./dev.db`;
    if (!envContent.includes('DATABASE_URL') || envContent.match(/DATABASE_URL\s*=\s*"?(mysql|postgres)/)) {
        envContent = envContent.replace(
            /^DATABASE_URL\s*=.*$/m,
            `DATABASE_URL="${sqliteUrl}"`
        );
        if (!envContent.includes('DATABASE_URL')) {
            envContent += `\nDATABASE_URL="${sqliteUrl}"\n`;
        }
        fs.writeFileSync(ENV_FILE, envContent);
        console.log(`Set DATABASE_URL to "${sqliteUrl}"`);
    } else {
        console.log(`DATABASE_URL already set, keeping existing value`);
    }
} else {
    if (!envContent.includes('DATABASE_URL') || envContent.match(/DATABASE_URL\s*=\s*"?file:/)) {
        console.log(`Please set DATABASE_URL in .env to your MySQL connection string`);
        console.log(`   Example: DATABASE_URL="mysql://user:password@localhost:3306/atk_backend"`);
    } else {
        console.log(`DATABASE_URL already set for MySQL`);
    }
}

// Step 3: Run Prisma commands
console.log(`\nGenerating Prisma client...`);
execSync('npx prisma@6 generate', { cwd: ROOT, stdio: 'inherit' });

console.log(`\nPushing schema to database...`);
execSync('npx prisma@6 db push', { cwd: ROOT, stdio: 'inherit' });

console.log(`\nDatabase setup complete! (${provider.toUpperCase()})`);
console.log(`\nTo seed the database, run: npx tsx prisma/seed.ts\n`);
