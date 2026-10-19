import { useEffect } from 'react'
import { ListChecks, Lock } from 'lucide-react'
import { useBlocker, useNavigate, useParams } from 'react-router-dom'
import AnimatedProgressBar from '../../../components/common/AnimatedProgressBar'
import AppBar from '../../../components/common/AppBar'
import OfflineNotice from '../../../components/common/OfflineNotice'
import Spinner from '../../../components/common/Spinner'
import StateMessageView from '../../../components/common/StateMessageView'
import { useLocalNotifier, useNotifier } from '../../../lib/useNotifier'
import QuizBottomBar from '../components/QuizBottomBar'
import QuizQuestionView from '../components/QuizQuestionView'
import QuizTimerChips from '../components/QuizTimerChips'
import { QuizPlayStore } from '../stores/quizPlayStore'
import { quizStore } from '../stores/quizStore'

// One question at a time (quiz_question_screen.dart). The language is locked
// for the whole quiz; every tap is saved on this device, so a refresh or a
// dropped connection loses nothing. The title, progress and timers stay
// pinned at the top; leaving a timed quiz asks first.
export default function QuizPlayPage() {
  const { quizId } = useParams()
  const navigate = useNavigate()
  const play = useLocalNotifier(() => new QuizPlayStore(quizId))
  const timer = useNotifier(play.timer)
  const quiz = useNotifier(quizStore)
  const blocker = useBlocker(({ currentLocation, nextLocation }) => play.shouldConfirmLeave && currentLocation.pathname !== nextLocation.pathname)

  useEffect(() => play.attach(navigate), [play, navigate])
  useEffect(() => {
    if (blocker.state === 'blocked') play.confirmLeave(blocker)
  }, [blocker, play])

  const total = quiz.totalQuestions
  const title = total > 0 ? `Question ${quiz.currentQuestionIndex + 1} of ${total}` : quiz.quizTitle || 'Quiz'
  const question = quiz.currentQuestion
  const ready = quiz.isQuizActive && quiz.quizId === quizId
  const showing = ready && total > 0

  return (
    <div className="flex min-h-dvh flex-col bg-bg">
      <div className="sticky top-0 z-20 bg-bg shadow-[0_2px_4px_var(--qs-appbar-shadow)]">
        <AppBar flat title={title} width="max-w-3xl" onBack={() => navigate('/quizzes')} />
        {showing ? (
          <div className="mx-auto w-full max-w-3xl">
            <div className="px-4 pb-2 pt-1">
              <AnimatedProgressBar value={(quiz.currentQuestionIndex + 1) / total} label={title} />
            </div>
            {timer.hasCountdown ? <QuizTimerChips timer={timer} /> : null}
          </div>
        ) : null}
      </div>
      {!ready ? (
        <div className="grid flex-1 place-items-center text-brand" aria-busy="true">
          {play.resuming || quiz.isSessionLoading ? <Spinner size={36} stroke={3} /> : null}
        </div>
      ) : total === 0 ? (
        <StateMessageView icon={ListChecks} title="No Questions Available" message="This quiz has no questions right now. Please try again later." />
      ) : (
        <>
          <main className="mx-auto w-full max-w-3xl flex-1">
            {quiz.openedFromDevice ? (
              <div className="px-4 pt-3">
                <OfflineNotice message="You're offline. Your answers are being saved on this device and will be sent when you submit with a connection." />
              </div>
            ) : null}
            {quiz.hasPerQuestionTimer && quiz.currentQuestionIndex === 0 ? (
              <p className="mx-4 mt-3 flex items-center gap-2 rounded-[14px] bg-slate-soft px-3 py-2.5 text-xs text-ink">
                <Lock size={16} className="shrink-0 text-slate" aria-hidden="true" />
                Each question has its own timer, and you can't go back to earlier questions.
              </p>
            ) : null}
            <QuizQuestionView
              key={question.id}
              question={question}
              locale={quiz.sessionLanguage}
              selected={quiz.selectedAnswer(question.id)}
              onPick={(index) => quiz.selectAnswer(index)}
            />
          </main>
          <QuizBottomBar
            quiz={quiz}
            submitting={timer.submitting}
            onPrevious={() => play.previous()}
            onNext={() => play.next()}
            onJump={(index) => play.jump(index)}
          />
        </>
      )}
    </div>
  )
}
