import { ChangeNotifier } from '../../../lib/ChangeNotifier'
import { userFriendlyError } from '../../../utils/userFriendlyError'
import { submittedMessage } from '../models/answersAvailability'
import { localeOf } from '../models/quizModels'
import { fetchAttempt, fetchQuiz } from '../services/quizAttemptService'

// The result page's data. Shown strictly from what the server sent: a fresh
// attempt, the list's summary, or (after a refresh) the quiz's summary loaded
// again. Never worked out here.
export function resultFromAttempt(attempt) {
  return {
    title: attempt.title,
    score: attempt.score,
    totalQuestions: attempt.totalQuestions,
    percentage: attempt.percentage,
    completedAt: attempt.createdAt,
    results: attempt.results,
    // The server's 'English'/'Malayalam' as a locale code for the review.
    language: localeOf(attempt.language),
    quizId: attempt.quizId,
    answersRevealed: attempt.answersRevealed,
    answersAvailableAt: attempt.answersAvailableAt,
    attemptId: attempt.attemptId || null,
  }
}

export class QuizResultStore extends ChangeNotifier {
  result = null
  error = null
  loadingReview = false

  constructor(quizId, initial) {
    super()
    this.quizId = quizId
    this.#show(initial?.attempt ? resultFromAttempt(initial.attempt) : (initial?.result ?? null))
  }

  // The score is held back until the quiz closes for everyone, so a result
  // reached before then (an old link, the back button) shows a note instead.
  #show(result) {
    if (result && !result.answersRevealed) this.error = submittedMessage(result.answersAvailableAt)
    else this.result = result
  }

  get correctCount() {
    const r = this.result
    return r.results.length ? r.results.filter((x) => x.isCorrect).length : r.score
  }

  get wrongCount() {
    return this.result.totalQuestions - this.correctCount
  }

  // Same cut-off as the "Nice Work!" message: confetti from 70%.
  get scoredWell() {
    return this.result.percentage >= 70
  }

  async loadIfNeeded() {
    if (this.result || this.error) return
    try {
      const quiz = await fetchQuiz(this.quizId)
      const a = quiz.myAttempt
      if (!a) {
        this.error = 'There is no result for this quiz yet.'
      } else {
        this.#show({
          title: quiz.title,
          score: a.score,
          totalQuestions: a.totalQuestions,
          percentage: a.percentage,
          completedAt: a.createdAt,
          results: [],
          language: 'en',
          quizId: quiz.id,
          answersRevealed: a.answersRevealed,
          answersAvailableAt: a.answersAvailableAt,
          attemptId: a.attemptId || null,
        })
      }
    } catch (e) {
      this.error = userFriendlyError(e)
    }
    this.notifyListeners()
  }

  // For a result without its answers (opened from the list): loads the
  // attempt; null with a message when it can't (quiz_attempt_review_provider.dart).
  async loadReview() {
    if (this.loadingReview || !this.result?.attemptId) return { attempt: null, error: null }
    this.loadingReview = true
    this.notifyListeners()
    try {
      const attempt = await fetchAttempt(this.result.attemptId)
      if (attempt.results.length === 0) return { attempt: null, error: "The answers aren't available yet." }
      return { attempt, error: null }
    } catch (e) {
      return { attempt: null, error: userFriendlyError(e) }
    } finally {
      this.loadingReview = false
      this.notifyListeners()
    }
  }
}
