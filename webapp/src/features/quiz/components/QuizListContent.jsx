import { CalendarClock, Trophy, Zap } from 'lucide-react'
import { useLocalNotifier } from '../../../lib/useNotifier'
import { pendingMessage, retakeAction } from '../actions/quizListActions'
import { refusalMessage } from '../models/quizRefusal'
import { PAST_SECTION_ID, QuizSectionsStore } from '../stores/quizSectionsStore'
import QuizPendingBanner from './QuizPendingBanner'
import QuizRefusedBanner from './QuizRefusedBanner'
import QuizSection from './QuizSection'

// The loaded list: refused and waiting notices, then Live, Upcoming and Past
// Quizzes (the home hero card covers "no live quiz").
export default function QuizListContent({ quiz, navigate, onOpen }) {
  const sections = useLocalNotifier(() => new QuizSectionsStore())
  const live = quiz.quizList.filter((q) => q.isLive)
  const upcoming = quiz.quizList.filter((q) => q.isUpcoming)
  const ended = quiz.quizList.filter((q) => q.isEnded)
  const pending = quiz.pendingSubmissions
  // Quizzes started on this device, so their cards say "Continue".
  const started = new Map(quiz.inProgressQuizzes.map((r) => [r.quizId, r]))
  const shared = { started, onOpen, sections }
  return (
    <div className="flex flex-col gap-2">
      {quiz.refusedSubmissions.map((record) => (
        <QuizRefusedBanner
          key={record.quizId}
          message={refusalMessage(record)}
          onDismiss={() => quiz.dismissRefused(record.quizId)}
          onReopen={retakeAction(record, navigate)}
        />
      ))}
      {pending.length ? <QuizPendingBanner message={pendingMessage(pending)} sending={quiz.isFlushing} onSend={() => quiz.fetchQuizList()} /> : null}
      {live.length ? <QuizSection id="live-quizzes" title="Live Quizzes" icon={Zap} iconClass="fill-current text-amber" quizzes={live} {...shared} /> : null}
      {upcoming.length ? <QuizSection id="upcoming-quizzes" title="Upcoming Quizzes" icon={CalendarClock} iconClass="text-amber" quizzes={upcoming} {...shared} /> : null}
      {ended.length ? <QuizSection id={PAST_SECTION_ID} title="Past Quizzes" icon={Trophy} iconClass="text-amber" quizzes={ended} {...shared} /> : null}
    </div>
  )
}
