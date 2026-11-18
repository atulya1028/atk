import { createRequire } from 'node:module';
import { prisma } from './db.js';
import { isInitialQuestion, mentalSection } from './survey_question_bank.js';

const require = createRequire(import.meta.url);
const rows = require('./questions.json');

function normalize(row, surveyType, index) {
  const questionId = row['#'];
  const text = row.Question?.trim();
  if (!Number.isInteger(questionId) || !text) {
    throw new Error(`Invalid survey question at source row ${index + 1}`);
  }

  const sourceOptions = String(row['Answer options'] ?? '')
    .split('\n')
    .map(option => option.replace(/^\s*-\s*/, '').trim())
    .filter(Boolean);
  const numeric = sourceOptions.length === 1 &&
    /^(numeric(?:\s|$)|1[–-]10\s+scale)/i.test(sourceOptions[0]);
  if (!numeric && sourceOptions.length === 0) {
    throw new Error(`Question ${questionId} has no answer options`);
  }
  const scale = numeric && /1[–-]10\s+scale/i.test(sourceOptions[0]);
  return {
    id: `${surveyType}:${questionId}`,
    surveyType,
    questionId: String(questionId),
    sourceOrder: index,
    definition: {
      id: String(questionId),
      text,
      kind: numeric ? 'number' : 'choice',
      options: numeric ? [] : sourceOptions.map(label => ({ label })),
      ...(numeric ? { min: scale ? 1 : 0, max: scale ? 10 : 120 } : {}),
      section: row.Section,
      sectionSlug: row.SectionSlug,
      sectionOrder: row.SectionOrder,
      logic: row['Logic Builder'],
    },
  };
}

const initialRows = rows.filter(row => isInitialQuestion(row['#'], row.SectionSlug));
const questionRecords = [
  ...initialRows.map((row, index) => normalize(row, 'INITIAL', index)),
  ...rows
    .filter(row => row.SectionSlug === mentalSection)
    .map((row, index) => normalize(row, 'MENTAL', index)),
];

if (new Set(questionRecords.map(record => record.id)).size !== questionRecords.length) {
  throw new Error('Survey question IDs must be unique within each survey type');
}

try {
  for (const record of questionRecords) {
    const { id, ...data } = record;
    await prisma.surveyQuestion.upsert({
      where: { id },
      create: { id, ...data },
      update: data,
    });
  }
  console.log(JSON.stringify({ event: 'survey_questions_synced', total: questionRecords.length, initial: initialRows.length, mental: questionRecords.length - initialRows.length }));
} finally {
  await prisma.$disconnect();
}
