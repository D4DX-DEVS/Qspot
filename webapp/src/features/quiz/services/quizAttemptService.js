import { ApiClient } from '../../../services/apiClient'
import { quizAttemptFromJson, quizListItemFromJson } from '../models/quizModels'

// One finished attempt; per-question results come back only once the exam has
// closed for everyone (mobile-app/lib/services/quiz_attempt_service.dart).
export async function fetchAttempt(attemptId) {
  return quizAttemptFromJson((await ApiClient.get(`/api/user/quiz-attempts/${attemptId}`)) ?? {})
}

// One quiz from the list, with this student's attempt summary.
export async function fetchQuiz(quizId) {
  return quizListItemFromJson((await ApiClient.get(`/api/user-quizzes/${quizId}`)) ?? {})
}
