import { createElement } from 'react'
import { CalendarClock, CalendarX } from 'lucide-react'
import NoticeSheet from '../../../components/common/NoticeSheet'
import { ApiException } from '../../../services/apiClient'
import { dialogStore } from '../../../stores/dialogStore'
import { toastStore } from '../../../stores/toastStore'
import { dayMonthYear } from '../../../utils/formatDate'
import QuizLanguageDialog from '../components/QuizLanguageDialog'
import { SUBMITTED_WAITING_MESSAGE, quizStore } from '../stores/quizStore'

// What tapping things on the Quiz page does (quiz_list_screen.dart's
// handlers), kept out of the page component.

const notice = (props) =>
  dialogStore.show((close) => createElement(NoticeSheet, { ...props, onClose: () => close() }), { kind: 'sheet' })

// The result page for a quiz the student already took, from its summary.
export function showAttemptSummary(quiz, navigate) {
  const a = quiz.myAttempt
  navigate(`/quizzes/${quiz.id}/result`, {
    state: {
      result: {
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
      },
    },
  })
}

export async function openQuizFromList(quiz, navigate) {
  if (quiz.hasAttempted) return showAttemptSummary(quiz, navigate)
  if (quiz.isEnded) {
    return notice({
      icon: CalendarX,
      title: "You Didn't Attempt This Quiz",
      message: "This quiz ended before you took it, so there is no score to show. Keep an eye on Live Now so you don't miss the next one.",
    })
  }
  if (quiz.isUpcoming) {
    return notice({
      icon: CalendarClock,
      tone: 'amber',
      title: "This Quiz Hasn't Started Yet",
      message: quiz.startDate
        ? `It opens on ${dayMonthYear(quiz.startDate)}. Come back then to take it.`
        : 'Come back once it goes live to take it.',
    })
  }
  if (!quiz.isLive) return undefined
  if (quizStore.isWaitingToSend(quiz.id)) {
    // Submitted already: final, not reopened. Try sending it again.
    toastStore.show(SUBMITTED_WAITING_MESSAGE, 'warning')
    quizStore.fetchQuizList()
    return undefined
  }
  return chooseLanguageAndOpen(quiz.id, navigate)
}

async function chooseLanguageAndOpen(quizId, navigate) {
  const language = await dialogStore.show((close) => createElement(QuizLanguageDialog, { onClose: close }))
  if (language) await openQuiz(quizId, language, navigate)
}

// Carries on with a quiz started here, in its language; works offline.
export const continueQuiz = (record, navigate) => openQuiz(record.quizId, record.language, navigate)

export async function openQuiz(quizId, language, navigate) {
  try {
    await quizStore.startQuiz(quizId, language)
    navigate(`/quizzes/${quizId}/play`)
  } catch (e) {
    if (e instanceof ApiException && e.status === 409) {
      // Already taken: refresh so the existing result shows instead.
      await quizStore.fetchQuizList()
      toastStore.show("You've already taken this quiz", 'warning')
    } else {
      toastStore.show(e instanceof ApiException ? e.message : 'Something went wrong. Please try again.', 'danger')
    }
  }
}

// "Open Quiz Again" for answers refused because the questions changed, while
// the quiz is still open: the old copy goes and the quiz starts afresh.
export function retakeAction(record, navigate) {
  if (!record.canRetake) return null
  const quiz = quizStore.quizList.find((q) => q.id === record.quizId && q.isLive && !q.hasAttempted)
  if (!quiz) return null
  return async () => {
    quizStore.dismissRefused(record.quizId)
    await chooseLanguageAndOpen(quiz.id, navigate)
  }
}

export function pendingMessage(pending) {
  const what =
    pending.length === 1 ? (pending[0].title === '' ? 'your quiz' : `"${pending[0].title}"`) : `${pending.length} quizzes`
  return `Your answers for ${what} are saved on this device but have not been sent yet. They will be sent when you are back online.`
}
