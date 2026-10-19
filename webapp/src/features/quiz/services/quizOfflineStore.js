import { Storage } from '../../../services/storage'
import { QuizProgressRecord } from '../models/quizProgressRecord'

// This device's copy of a quiz in progress, per student and per quiz
// (mobile-app/lib/services/quiz_offline_store.dart). Two entries per quiz:
//  - the session: the questions exactly as the server sent them, saved once
//    when the quiz opens, so it can be taken (and reopened) offline;
//  - the progress: a small QuizProgressRecord, rewritten on every tap.
// localStorage writes are synchronous, so the last tap always wins and a
// late write can never land after clear(). Nothing here throws.
const SESSION_PREFIX = 'quiz_offline_session_'
const PROGRESS_PREFIX = 'quiz_offline_progress_'

const id = (userId, quizId) => `${userId}_${quizId}`

function readJson(key) {
  try {
    const raw = Storage.getString(key)
    return raw ? JSON.parse(raw) : null
  } catch {
    return null
  }
}

function records(userId, keep) {
  const found = []
  for (const key of Storage.keysStartingWith(`${PROGRESS_PREFIX}${userId}_`)) {
    // A damaged entry is skipped, never deleted.
    const record = QuizProgressRecord.tryFromJSON(readJson(key))
    if (record && keep(record)) found.push(record)
  }
  return found.sort((a, b) => a.startedAt - b.startedAt)
}

export const QuizOfflineStore = {
  saveSession: (userId, quizId, session) =>
    Storage.setString(`${SESSION_PREFIX}${id(userId, quizId)}`, JSON.stringify(session)),

  loadSession(userId, quizId) {
    const session = readJson(`${SESSION_PREFIX}${id(userId, quizId)}`)
    return session && typeof session === 'object' && !Array.isArray(session) ? session : null
  },

  saveProgress: (userId, record) =>
    Storage.setString(`${PROGRESS_PREFIX}${id(userId, record.quizId)}`, JSON.stringify(record)),

  loadProgress: (userId, quizId) => QuizProgressRecord.tryFromJSON(readJson(`${PROGRESS_PREFIX}${id(userId, quizId)}`)),

  // Submit was pressed and the server has not refused them for good.
  pending: (userId) => records(userId, (r) => r.isRetryable),

  // Refused for good (too late, switched off, changed, removed), waiting for
  // the student to see why.
  refused: (userId) => records(userId, (r) => r.isRefused),

  // Started here, not submitted, still open at [now]: can be continued offline.
  inProgress: (userId, now) => records(userId, (r) => !r.submitPending && r.rejectedStatus == null && !r.closedUnsubmitted(now)),

  abandoned: (userId, now) => records(userId, (r) => r.abandoned(now)),

  closedUnsubmitted: (userId, now) => records(userId, (r) => r.closedUnsubmitted(now)),

  // Answers not yet with the server: submitted but waiting, or a quiz in
  // progress with at least one answer.
  unsent: (userId) => records(userId, (r) => !r.isRefused && (r.submitPending || r.answeredCount > 0)),

  // Every quiz copy of [userId], on logout after the unsent-answers warning.
  clearAll(userId) {
    for (const key of [
      ...Storage.keysStartingWith(`${SESSION_PREFIX}${userId}_`),
      ...Storage.keysStartingWith(`${PROGRESS_PREFIX}${userId}_`),
    ]) {
      Storage.remove(key)
    }
  },

  // Call only once the server's answer is final: confirmed, or refused and
  // the student has seen why.
  clear(userId, quizId) {
    Storage.remove(`${SESSION_PREFIX}${id(userId, quizId)}`)
    Storage.remove(`${PROGRESS_PREFIX}${id(userId, quizId)}`)
  },
}
