import { useEffect } from 'react'
import { ListChecks, Lock } from 'lucide-react'
import { useBlocker, useNavigate, useParams } from 'react-router-dom'
import NoCopy from '../../../components/common/NoCopy'
import OfflineNotice from '../../../components/common/OfflineNotice'
import Spinner from '../../../components/common/Spinner'
import StateMessageView from '../../../components/common/StateMessageView'
import { useLocalNotifier, useNotifier } from '../../../lib/useNotifier'
import QuizBottomBar from '../components/QuizBottomBar'
import QuizPlayBackdrop from '../components/QuizPlayBackdrop'
import QuizPlayHeader from '../components/QuizPlayHeader'
import QuizQuestionView from '../components/QuizQuestionView'
import { QuizPlayStore } from '../stores/quizPlayStore'
import { quizStore } from '../stores/quizStore'

// One question at a time on a glass card over the night wall
// (quiz_question_screen.dart). The language is locked for the whole quiz;
// every tap is saved on this device, so a refresh or a dropped connection
// loses nothing. The title, progress and timers stay pinned at the top;
// leaving a timed quiz asks first. Nothing on it can be copied or pasted.
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
    <NoCopy className="relative flex min-h-dvh flex-col bg-bg">
      <QuizPlayBackdrop />
      <div className="sticky top-0 z-20 bg-[color-mix(in_srgb,var(--qs-bg)_82%,transparent)] backdrop-blur-md">
        <QuizPlayHeader title={title} current={quiz.currentQuestionIndex + 1} total={showing ? total : 0} timer={timer} onBack={() => navigate('/quizzes')} />
      </div>
      {!ready ? (
        <div className="relative grid flex-1 place-items-center text-brand" aria-busy="true">
          {play.resuming || quiz.isSessionLoading ? <Spinner size={36} stroke={3} /> : null}
        </div>
      ) : total === 0 ? (
        <div className="relative flex-1">
          <StateMessageView icon={ListChecks} title="No Questions Available" message="This quiz has no questions right now. Please try again later." />
        </div>
      ) : (
        <>
          <main className="relative mx-auto flex w-full max-w-[1040px] flex-1 flex-col gap-3 px-4 pb-6 pt-2 sm:pt-4">
            {quiz.openedFromDevice ? (
              <OfflineNotice message="You're offline. Your answers are being saved on this device and will be sent when you submit with a connection." />
            ) : null}
            {quiz.hasPerQuestionTimer && quiz.currentQuestionIndex === 0 ? (
              <p className="flex items-center gap-2 rounded-[14px] bg-slate-soft px-3 py-2.5 text-xs text-ink">
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
    </NoCopy>
  )
}
