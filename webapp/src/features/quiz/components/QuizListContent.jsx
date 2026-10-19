import { pendingMessage, retakeAction } from '../actions/quizListActions'
import { refusalMessage } from '../models/quizRefusal'
import QuizPendingBanner from './QuizPendingBanner'
import QuizRefusedBanner from './QuizRefusedBanner'
import QuizSection from './QuizSection'

// The loaded list: refused and waiting notices, then Live Now, Coming Up and
// Past Quizzes (the home hero card covers "no live quiz").
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
      {live.length ? <QuizSection emoji="⚡" title="Live Now" quizzes={live} onOpen={onOpen} /> : null}
      {upcoming.length ? <QuizSection emoji="🗓️" title="Coming Up" quizzes={upcoming} onOpen={onOpen} /> : null}
      {ended.length ? <QuizSection emoji="🏆" title="Past Quizzes" quizzes={ended} onOpen={onOpen} /> : null}
    </div>
  )
}
