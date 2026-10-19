import { ListChecks } from 'lucide-react'
import Entrance from '../../../components/common/Entrance'
import InfoNoteCard from '../../../components/common/InfoNoteCard'
import { pendingMessage, retakeAction } from '../actions/quizListActions'
import { refusalMessage } from '../models/quizRefusal'
import QuizPendingBanner from './QuizPendingBanner'
import QuizRefusedBanner from './QuizRefusedBanner'
import QuizSection from './QuizSection'

// The loaded list: refused and waiting notices, then Live Now (or a "no live
// quiz" note), Upcoming and Ended.
export default function QuizListContent({ quiz, navigate, onOpen }) {
  const live = quiz.quizList.filter((q) => q.isLive)
  const upcoming = quiz.quizList.filter((q) => q.isUpcoming)
  const ended = quiz.quizList.filter((q) => q.isEnded)
  const pending = quiz.pendingSubmissions
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
      {live.length === 0 ? (
        <Entrance className="mt-2">
          <InfoNoteCard icon={ListChecks} tone="amber" message="No live quiz right now. Check back later, or see upcoming and past quizzes below." />
        </Entrance>
      ) : (
        <QuizSection title="Live Now" quizzes={live} onOpen={onOpen} />
      )}
      {upcoming.length ? <QuizSection title="Upcoming" quizzes={upcoming} onOpen={onOpen} /> : null}
      {ended.length ? <QuizSection title="Ended" quizzes={ended} onOpen={onOpen} /> : null}
    </div>
  )
}
