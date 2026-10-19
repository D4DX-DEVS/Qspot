import { jsonDouble, jsonInt, parseDate } from '../../../utils/jsonParsing'

// Quiz shapes from the API (mobile-app/lib/screens/quiz/model/quiz_model.dart).
// All grading happens on the server: an in-progress question never carries a
// correct answer, and scores are only ever read from the server's reply.

const options = (value) => (Array.isArray(value) ? value.map(String) : [])

// Text for 'en' or 'ml', falling back to English when Malayalam is missing.
export const questionText = (q, locale) => (locale === 'ml' && q.questionMl ? q.questionMl : q.questionEn)

// Options for the locale, falling back to English when the Malayalam list is
// missing or shorter (incomplete content must not break a question).
export const optionsFor = (q, locale) =>
  locale === 'ml' && q.optionsMl.length > 0 && q.optionsMl.length >= q.optionsEn.length ? q.optionsMl : q.optionsEn

// The server's 'English'/'Malayalam' as a locale code.
export const localeOf = (language) => (language === 'Malayalam' ? 'ml' : 'en')

export function myAttemptFromJson(json) {
  return {
    attemptId: json.attemptId == null ? '' : String(json.attemptId),
    score: jsonInt(json.score) ?? 0,
    totalQuestions: jsonInt(json.totalQuestions) ?? 0,
    percentage: jsonDouble(json.percentage) ?? 0,
    createdAt: parseDate(json.createdAt),
    answersRevealed: json.answersRevealed === true,
    answersAvailableAt: parseDate(json.answersAvailableAt),
  }
}

// One entry of GET /api/user-quizzes (or GET /api/user-quizzes/:id).
export function quizListItemFromJson(json) {
  const status = typeof json.status === 'string' ? json.status : 'ended'
  const myAttempt = json.myAttempt && typeof json.myAttempt === 'object' ? myAttemptFromJson(json.myAttempt) : null
  return {
    id: json._id == null ? '' : String(json._id),
    title: typeof json.title === 'string' ? json.title : '',
    assessmentType: typeof json.assessmentType === 'string' ? json.assessmentType : 'quiz',
    startDate: parseDate(json.startDate),
    endDate: parseDate(json.endDate),
    timerMode: typeof json.timerMode === 'string' ? json.timerMode : 'none',
    status,
    questionCount: jsonInt(json.questionCount) ?? 0,
    myAttempt,
    isLive: status === 'live',
    isUpcoming: status === 'upcoming',
    isEnded: status === 'ended',
    hasAttempted: myAttempt != null,
  }
}

// One question of GET /api/user-quizzes/:id/questions (no correct answer).
export function quizQuestionFromJson(json) {
  return {
    id: json._id == null ? '' : String(json._id),
    type: typeof json.type === 'string' ? json.type : 'multiple_choice',
    questionEn: typeof json.question_en === 'string' ? json.question_en : '',
    questionMl: typeof json.question_ml === 'string' ? json.question_ml : '',
    optionsEn: options(json.options_en),
    optionsMl: options(json.options_ml),
    difficulty: typeof json.difficulty === 'string' ? json.difficulty : 'medium',
  }
}

// One server-graded question of an attempt.
export function questionResultFromJson(json) {
  return {
    questionId: json.questionId == null ? '' : String(json.questionId),
    questionEn: typeof json.question_en === 'string' ? json.question_en : '',
    questionMl: typeof json.question_ml === 'string' ? json.question_ml : '',
    optionsEn: options(json.options_en),
    optionsMl: options(json.options_ml),
    attemptedAnswer: jsonInt(json.attemptedAnswer),
    correctAnswer: jsonInt(json.correctAnswer) ?? -1,
    isCorrect: json.isCorrect === true,
  }
}

// The `attempt` of POST /api/quizzes/attempt (201, or a 409 that carries the
// attempt already saved) and of GET /api/user/quiz-attempts/:id.
export function quizAttemptFromJson(json) {
  const results = Array.isArray(json.results) ? json.results.map(questionResultFromJson) : []
  return {
    attemptId: json.attemptId == null ? '' : String(json.attemptId),
    quizId: json.quizId == null ? '' : String(json.quizId),
    title: typeof json.title === 'string' ? json.title : '',
    language: typeof json.language === 'string' ? json.language : 'en',
    score: jsonInt(json.score) ?? 0,
    totalQuestions: jsonInt(json.totalQuestions) ?? 0,
    percentage: jsonDouble(json.percentage) ?? 0,
    totalDuration: jsonInt(json.totalDuration) ?? 0,
    createdAt: parseDate(json.createdAt),
    // Per-question results are empty until the exam closes for everyone.
    results,
    // Older servers send no flag and always include the answers.
    answersRevealed: typeof json.answersRevealed === 'boolean' ? json.answersRevealed : results.length > 0,
    answersAvailableAt: parseDate(json.answersAvailableAt),
  }
}
