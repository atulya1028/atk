export const mentalSection = 'mental_status_examination';

// The retired prompts used the same Yes/No options as their replacements.
export const retiredInitialQuestionIds = new Map([
  ['76', '64'],
  ['82', '37'],
  ['72', '62'],
]);

export function isInitialQuestion(id, section) {
  return section !== mentalSection && !retiredInitialQuestionIds.has(String(id));
}

export function restoreInitialAnswers(answers) {
  const restored = { ...answers };
  for (const [retiredId, retainedId] of retiredInitialQuestionIds) {
    if (restored[retainedId] == null && restored[retiredId] != null) {
      restored[retainedId] = restored[retiredId];
    }
  }
  return restored;
}
