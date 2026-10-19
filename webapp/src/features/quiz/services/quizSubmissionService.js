import { ApiClient, ApiException } from '../../../services/apiClient'
import { quizAttemptFromJson } from '../models/quizModels'
import { TOO_LATE_CODE } from '../models/quizProgressRecord'
import { QuizOfflineStore } from './quizOfflineStore'

// Sends a student's answers and decides what happens to the device copy
// (mobile-app/lib/services/quiz_submission_service.dart).
//
// The rule that protects the student: the copy is deleted only when the
// server has confirmed the attempt, a 201, or a 409 whose body carries the
// already-saved attempt. Every other outcome (offline, timeout, server error,
// even a refusal) leaves the answers here. The server grades once per student
// and quiz, so sending again is always safe.

// Pauses before the automatic re-sends of an overloaded-server reply.
export const retryDelays = { values: [800, 2400] }

const isOverloaded = (status) => [429, 502, 503, 504].includes(status)

// A refusal the server will repeat however often it is asked.
export const isDefiniteRejection = (e) =>
  e instanceof ApiException && e.status >= 400 && e.status < 500 && !e.isAuthFailure && ![408, 409, 429].includes(e.status)

// Refused because the answers arrived after the quiz closed.
export const isTooLate = (e) => e instanceof ApiException && e.status === 403 && e.body?.code === TOO_LATE_CODE

// Says nothing about the quiz itself (offline, timeout, server fault), so a
// saved copy can stand in for the server.
export const isConnectionTrouble = (e) =>
  !(e instanceof ApiException) || e.status >= 500 || e.status === 408 || e.status === 429

const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms))

async function post(body) {
  for (let tried = 0; ; tried += 1) {
    try {
      return await ApiClient.post('/api/quizzes/attempt', { body })
    } catch (e) {
      if (!(e instanceof ApiException) || !isOverloaded(e.status) || tried >= retryDelays.values.length) throw e
      // A random extra pause so a whole class does not come back at once.
      const base = retryDelays.values[tried]
      await sleep(base + base * Math.random() * 0.5)
    }
  }
}

// Sends [record] and returns the graded attempt; on success the device copy
// is removed. Throws on every failure, leaving the copy (marked as refused
// when the server's answer is final).
export async function sendSubmission(userId, record) {
  try {
    const data = await post(record.toSubmissionBody(record.totalDuration ?? 0))
    const attempt = quizAttemptFromJson(data?.attempt ?? {})
    if (userId != null) QuizOfflineStore.clear(userId, record.quizId)
    return attempt
  } catch (e) {
    const saved = e instanceof ApiException && e.status === 409 ? e.body?.attempt : null
    if (saved && typeof saved === 'object') {
      // Already attempted: the server holds the answers, show that result.
      if (userId != null) QuizOfflineStore.clear(userId, record.quizId)
      return quizAttemptFromJson(saved)
    }
    if (userId != null && isDefiniteRejection(e)) {
      const code = typeof e.body?.code === 'string' ? e.body.code : null
      QuizOfflineStore.saveProgress(userId, record.copyWith({ rejectedStatus: e.status, rejectedCode: code }))
    }
    throw e
  }
}

// Deletes copies opened but never answered once the quiz is over.
export function discardAbandoned(userId, now, except) {
  for (const record of QuizOfflineStore.abandoned(userId, now)) {
    if (record.quizId !== except) QuizOfflineStore.clear(userId, record.quizId)
  }
}

// A quiz whose end time passed while the page was not open on it was never
// submitted: its answers as last saved become a waiting submission, sent by
// flushPending (accepted within the grace period, otherwise refused as too
// late, which the student is then told). Unanswered ones are left alone.
export function sealClosedQuizzes(userId, now, except) {
  for (const record of QuizOfflineStore.closedUnsubmitted(userId, now)) {
    if (record.answeredCount > 0 && record.quizId !== except) {
      QuizOfflineStore.saveProgress(userId, record.sealedAfterClose())
    }
  }
}

// Tries every waiting submission; true when any was accepted. A failure just
// leaves that one for the next try.
export async function flushPending(userId, except) {
  let sent = false
  for (const record of QuizOfflineStore.pending(userId)) {
    if (record.quizId === except) continue
    try {
      await sendSubmission(userId, record)
      sent = true
    } catch (e) {
      console.warn(`Quiz submission for ${record.quizId} still waiting:`, e)
    }
  }
  return sent
}
