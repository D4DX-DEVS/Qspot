// Shared quiz/video-question helpers. `correct_answer` is stored as either
// English option text or a numeric index (CONTRACT.md), so both QuizPage and
// VideoQuestionsPage resolve it the same way instead of each guessing
// independently (GAP-REPORT D4).

export const QUESTION_TYPE_OPTIONS = ['Multiple Choice', 'True / False'];
export const DIFFICULTY_OPTIONS = ['Easy', 'Medium', 'Hard'];

export const isTrueFalseType = (type) => /true/i.test(type || '');

export const parseOptionsList = (value) => {
  if (!value) return [];
  if (Array.isArray(value)) return value.map((v) => v?.toString?.().trim()).filter(Boolean);
  try {
    const parsed = JSON.parse(value);
    if (Array.isArray(parsed)) {
      return parsed.map((item) => item?.toString?.().trim()).filter(Boolean);
    }
  } catch {
    // fall back to splitting string values
  }
  return value
    .split(/\r?\n|,/)
    .map((item) => item.trim().replace(/^"(.*)"$/, '$1'))
    .filter(Boolean);
};

// Resolves the stored `correct_answer` (English option text OR a numeric
// index) to a form index. Text match first, then index.
export const questionToFormShape = (question) => {
  const optionsEnList = parseOptionsList(question.options_en);
  const optionsMlList = parseOptionsList(question.options_ml);
  const count = Math.max(optionsEnList.length, optionsMlList.length, 2);
  const options = Array.from({ length: count }, (_, index) => ({
    en: optionsEnList[index] || '',
    ml: optionsMlList[index] || ''
  }));

  let correctIndex = optionsEnList.findIndex(
    (option) => option.trim().toLowerCase() === (question.correct_answer || '').trim().toLowerCase()
  );
  if (correctIndex === -1) {
    const asIndex = Number(question.correct_answer);
    if (Number.isInteger(asIndex) && asIndex >= 0 && asIndex < options.length) {
      correctIndex = asIndex;
    }
  }

  return {
    type: isTrueFalseType(question.type) ? 'True / False' : 'Multiple Choice',
    difficulty: question.difficulty || DIFFICULTY_OPTIONS[0],
    question_en: question.question_en || '',
    question_ml: question.question_ml || '',
    options,
    correctIndex: correctIndex === -1 ? null : correctIndex
  };
};
