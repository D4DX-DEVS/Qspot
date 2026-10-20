import { PencilLine, Wrench } from 'lucide-react'
import ScoreBar from '../../../components/common/ScoreBar'
import SoftIconTile from '../../../components/common/SoftIconTile'
import SurfaceCard from '../../../components/common/SurfaceCard'
import TintedPillLink from '../../../components/common/TintedPillLink'
import ToneChip from '../../../components/common/ToneChip'
import { dayMonthYear, whenLabel } from '../../../utils/formatDate'

const statusOf = (quiz) =>
  quiz.isEnded ? ['Ended', 'slate'] : quiz.hasAttempted ? ['Attempted', 'rose'] : quiz.isLive ? ['Live', 'mint'] : quiz.isUpcoming ? ['Upcoming', 'amber'] : ['Ended', 'slate']

// One quiz in the list: tinted icon, title, type, question count, a status
// chip, then when it ends or opens, or the student's score with a bar (once
// the quiz has closed). A quiz started on this device ([record]) offers to
// continue.
export default function QuizListCard({ quiz, record, onOpen }) {
  const [status, tone] = statusOf(quiz)
  const practical = quiz.assessmentType === 'practical'
  const count = `${quiz.questionCount} Question${quiz.questionCount === 1 ? '' : 's'}`
  const attempt = quiz.myAttempt
  const toTake = quiz.isLive && !attempt
  return (
    <SurfaceCard onClick={() => onOpen(quiz)} padding="p-3.5" className="h-full" label={`${quiz.title}. ${status}. ${count}`}>
      <div className="flex items-start gap-3">
        <SoftIconTile icon={practical ? Wrench : PencilLine} tone={tone} size={46} />
        <div className="min-w-0 flex-1">
          <div className="flex items-start gap-2">
            <p className="min-w-0 flex-1 text-[15.5px] font-bold text-ink">{quiz.title}</p>
            <ToneChip label={status} tone={tone} />
          </div>
          <p className="mt-1 text-[13px] text-muted">
            {practical ? 'Practical Exam' : 'Knowledge Quiz'} · {count}
          </p>
          {quiz.isUpcoming && quiz.startDate ? <p className="mt-1 text-xs text-muted">Starts {dayMonthYear(quiz.startDate)}</p> : null}
          {toTake ? (
            <div className="mt-2.5 flex flex-wrap items-center justify-between gap-2">
              <p className="text-xs text-muted">
                {record ? `${record.answeredCount} of ${record.questionIds.length} answered` : quiz.endDate ? `Ends ${whenLabel(quiz.endDate)}` : 'Open now'}
              </p>
              <TintedPillLink label={record ? 'Continue' : 'Start'} tone="mint" />
            </div>
          ) : null}
          {attempt && !attempt.answersRevealed ? <p className="mt-2.5 text-[13.5px] font-semibold text-brand">Answers submitted</p> : null}
          {attempt?.answersRevealed ? (
            <div className="mt-2.5">
              <p className="text-[13.5px] font-semibold text-brand">
                Your Score: {attempt.score}/{attempt.totalQuestions} ({attempt.percentage}%)
              </p>
              <div className="mt-1.5">
                <ScoreBar percentage={attempt.percentage} />
              </div>
            </div>
          ) : null}
        </div>
      </div>
    </SurfaceCard>
  )
}
