import { prisma } from "../db.js";
import { isInitialQuestion } from "../survey_question_bank.js";

export const surveyTypes = ["INITIAL", "DETAILED", "MENTAL", "MENTAL_STANDALONE"];
export const mentalSurveyTypes = ["MENTAL", "MENTAL_STANDALONE"];

export const detailedSurveyQuestions = [
  "How often do you use more than you planned to?",
  "How often have you tried to cut down without success?",
  "How often does it affect your work or studies?",
  "How often does it cause problems with family or friends?",
  "How often do you feel unable to stop even when you want to?",
].map((text, id) => ({
  id,
  text,
  options: ["Never", "Sometimes", "Often", "Almost always"].map(
    (label, index) => ({ label, score: index * 5 }),
  ),
}));

export const questionsForType = async (type) => {
  if (type === "DETAILED") return detailedSurveyQuestions;
  const rows = await prisma.surveyQuestion.findMany({
    where: { surveyType: type === "MENTAL_STANDALONE" ? "MENTAL" : type },
    orderBy: [{ sourceOrder: "asc" }, { questionId: "asc" }],
  });
  const questionIds = new Set();
  const prompts = new Set();
  return rows
    .map((row) => row.definition)
    .filter((question) => {
      if (
        type === "INITIAL" &&
        !isInitialQuestion(question.id, question.sectionSlug)
      ) {
        return false;
      }
      const id = String(question.id);
      const prompt = question.text
        .normalize("NFKC")
        .toLowerCase()
        .replace(/[^\p{L}\p{N}]+/gu, " ")
        .trim();
      if (questionIds.has(id) || prompts.has(prompt)) return false;
      questionIds.add(id);
      prompts.add(prompt);
      return true;
    });
};

export const publicSurveyQuestions = (questions) =>
  questions.map((question) => ({
    id: question.id,
    text: question.text,
    kind: question.kind ?? "choice",
    options: question.options.map(({ label }) => ({ label })),
    ...(question.min == null ? {} : { min: question.min }),
    ...(question.max == null ? {} : { max: question.max }),
    ...(question.section == null ? {} : { section: question.section }),
    ...(question.sectionSlug == null
      ? {}
      : { sectionSlug: question.sectionSlug }),
    ...(question.sectionOrder == null
      ? {}
      : { sectionOrder: question.sectionOrder }),
    ...(question.logic == null ? {} : { logic: question.logic }),
  }));

export const isAnswerValid = (question, value) => {
  if (!Number.isInteger(value)) return false;
  if (question.kind === "number") {
    return value >= question.min && value <= question.max;
  }
  return value >= 0 && value < question.options.length;
};

const SEVERE_YES_KEYWORDS = [
  "harming yourself",
  "ending your life",
  "seizures",
  "delirium tremens",
  "hospital admission",
  "lost control",
  "liver disease",
  "pancreatitis",
  "drive or operate",
  "daily tasks",
];

const CLINICAL_YES_KEYWORDS = [
  "substance",
  "alcohol",
  "withdrawal",
  "cravings",
  "blackouts",
  "morning",
  "treatment",
  "tolerance",
  "tremors",
  "shaking",
  "sweating",
  "nausea",
  "anxiety",
  "palpitations",
  "medical problems",
  "social, occupational",
  "financial",
  "legal",
  "risk-taking",
  "audit",
];

export const calculateOptionScore = (question, selectedIndex) => {
  if (selectedIndex == null || selectedIndex < 0) return 0;
  if (!question.options || !question.options[selectedIndex]) {
    if (question.kind === "number" && typeof selectedIndex === "number") {
      return Math.min(10, Math.max(0, selectedIndex));
    }
    return 0;
  }
  const option = question.options[selectedIndex];
  if (typeof option.score === "number") return option.score;
  const label = (option.label || "").trim().toLowerCase();
  const qText = (question.text || "").toLowerCase();

  if (
    label === "suicidal" ||
    label === "impaired" ||
    label === "relapsed" ||
    label === "significant issues" ||
    (label === "yes" && SEVERE_YES_KEYWORDS.some((kw) => qText.includes(kw)))
  ) {
    return 10;
  }

  if (
    label === "abnormal" ||
    label === "poor" ||
    label === "severe" ||
    label === "almost always" ||
    label === "nearly always" ||
    label === "daily" ||
    label === "binge" ||
    (label === "yes" && CLINICAL_YES_KEYWORDS.some((kw) => qText.includes(kw)))
  ) {
    return 5;
  }

  if (
    label === "partial" ||
    label === "partially reliable" ||
    label === "fair" ||
    label === "moderate" ||
    label === "unstable" ||
    label === "unemployed" ||
    label === "often" ||
    label === "weekly" ||
    label === "yes"
  ) {
    return 3;
  }

  if (label === "sometimes" || label === "mild" || label === "occasional") {
    return 2;
  }

  return 0;
};

export const surveyScore = (type, answers, questions) => {
  if (!answers || !questions || !questions.length) return 0;
  let total = 0;
  for (const question of questions) {
    const rawAnswer = answers[question.id] ?? answers[String(question.id)];
    if (rawAnswer !== undefined) {
      total += calculateOptionScore(question, rawAnswer);
    }
  }
  return total;
};
