import { PencilLine, Wrench } from 'lucide-react'
import SoftIconTile from '../../../components/common/SoftIconTile'
import SurfaceCard from '../../../components/common/SurfaceCard'
import ToneChip from '../../../components/common/ToneChip'
import { dayMonthYear } from '../../../utils/formatDate'

const statusOf = (quiz) =>
  quiz.isEnded ? ['Ended', 'slate'] : quiz.hasAttempted ? ['Attempted', 'rose'] : quiz.isLive ? ['Live', 'mint'] : quiz.isUpcoming ? ['Upcoming', 'amber'] : ['Ended', 'slate']

// One quiz in the list: tinted icon, title, type, question count, start date
// or the student's score, and a status chip.
export default function QuizListCard({ quiz, onOpen }) {
  const [status, tone] = statusOf(quiz)
  const practical = quiz.assessmentType === 'practical'
  const count = `${quiz.questionCount} Question${quiz.questionCount === 1 ? '' : 's'}`
  const attempt = quiz.myAttempt
  return (
    <SurfaceCard onClick={() => onOpen(quiz)} padding="p-3.5" label={`${quiz.title}. ${status}. ${count}`}>
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
          {attempt ? (
            <p className="mt-2.5 text-[13.5px] font-semibold text-brand">
              Your Score: {attempt.score}/{attempt.totalQuestions} ({attempt.percentage}%)
            </p>
          ) : null}
        </div>
      </div>
    </SurfaceCard>
  )
}
