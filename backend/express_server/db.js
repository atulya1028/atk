import 'dotenv/config';
import { Pool } from 'pg';
import { PrismaPg } from '@prisma/adapter-pg';
import { PrismaClient } from './generated/prisma/client.ts';

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: process.env.PGSSL === 'true' ? true : undefined,
  max: 20,
  connectionTimeoutMillis: 5000,
  idleTimeoutMillis: 30000,
});

const adapter = new PrismaPg(pool, { disposeExternalPool: true });
export const prisma = new PrismaClient({ adapter });
