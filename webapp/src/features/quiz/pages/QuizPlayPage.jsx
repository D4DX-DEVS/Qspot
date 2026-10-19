import { useEffect } from 'react'
import { ListChecks } from 'lucide-react'
import { useNavigate, useParams } from 'react-router-dom'
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
// dropped connection loses nothing.
export default function QuizPlayPage() {
  const { quizId } = useParams()
  const navigate = useNavigate()
  const play = useLocalNotifier(() => new QuizPlayStore(quizId))
  const timer = useNotifier(play.timer)
  const quiz = useNotifier(quizStore)

  useEffect(() => play.attach(navigate), [play, navigate])

  const total = quiz.totalQuestions
  const title = total > 0 ? `Question ${quiz.currentQuestionIndex + 1} of ${total}` : quiz.quizTitle || 'Quiz'
  const question = quiz.currentQuestion
  const ready = quiz.isQuizActive && quiz.quizId === quizId

  return (
    <div className="flex min-h-dvh flex-col bg-bg">
      <AppBar title={title} width="max-w-3xl" onBack={() => navigate('/quizzes')} />
      {!ready ? (
        <div className="grid flex-1 place-items-center text-brand" aria-busy="true">
          {play.resuming || quiz.isSessionLoading ? <Spinner size={36} stroke={3} /> : null}
        </div>
      ) : total === 0 ? (
        <StateMessageView icon={ListChecks} title="No Questions Available" message="This quiz has no questions right now. Please try again later." />
      ) : (
        <>
          <div className="mx-auto w-full max-w-3xl">
            {quiz.openedFromDevice ? (
              <div className="px-4 pt-2">
                <OfflineNotice message="You're offline. Your answers are being saved on this device and will be sent when you submit with a connection." />
              </div>
            ) : null}
            <div className="px-4 py-2">
              <AnimatedProgressBar value={(quiz.currentQuestionIndex + 1) / total} label={title} />
            </div>
            {timer.hasCountdown ? <QuizTimerChips timer={timer} /> : null}
          </div>
          <div className="flex-1">
            <QuizQuestionView
              key={question.id}
              question={question}
              locale={quiz.sessionLanguage}
              selected={quiz.selectedAnswer(question.id)}
              onPick={(index) => quiz.selectAnswer(index)}
            />
          </div>
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
