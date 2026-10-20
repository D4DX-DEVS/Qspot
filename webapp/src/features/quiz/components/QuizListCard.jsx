import { CalendarClock, ChevronRight, Play } from 'lucide-react'
import FactItem from '../../../components/common/FactItem'
import GlassCard from '../../../components/common/GlassCard'
import PillButton from '../../../components/common/PillButton'
import ScoreBar from '../../../components/common/ScoreBar'
import { questionsLabel, scheduleLabel } from '../models/quizFacts'
import QuizFactsRow from './QuizFactsRow'
import QuizThumb from './QuizThumb'

const statusOf = (quiz) =>
  quiz.isEnded
    ? { label: 'Ended', dot: 'ended' }
    : quiz.hasAttempted
      ? { label: 'Attempted', dot: 'done' }
      : quiz.isLive
        ? { label: 'Live', dot: 'live', pulse: true }
        : quiz.isUpcoming
          ? { label: 'Upcoming', dot: 'upcoming' }
          : { label: 'Ended', dot: 'ended' }

// What the card's button says, or null when tapping only shows a notice.
function actionOf(quiz, record) {
  if (quiz.isLive && !quiz.myAttempt) return { label: record ? 'Continue' : 'Start Quiz', look: 'go', icon: Play }
  if (quiz.myAttempt?.answersRevealed) return { label: 'View Result', look: 'outline' }
  if (quiz.isUpcoming) return { label: 'See Details', look: 'outline' }
  return null
}

// One quiz in the list: its picture with a status badge, title, type,
// question count and time, when it ends or opens, then the student's score
// (once the quiz has closed) and the button. A quiz started on this device
// ([record]) offers to continue. The whole card is the tap target.
export default function QuizListCard({ quiz, record, onOpen }) {
  const status = statusOf(quiz)
  const action = actionOf(quiz, record)
  const attempt = quiz.myAttempt
  const toTake = quiz.isLive && !attempt
  const schedule = scheduleLabel(quiz)
  return (
    <GlassCard onClick={() => onOpen(quiz)} padding="p-3 sm:p-4" label={`${quiz.title}. ${status.label}. ${questionsLabel(quiz)}`}>
      <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:gap-6">
        {/* Picture and words side by side; on wider screens the button joins the row. */}
        <div className="flex min-w-0 gap-3.5 sm:contents">
          <QuizThumb badge={status.label} dot={status.dot} pulse={status.pulse} faded={quiz.isEnded} />
          <div className="min-w-0 flex-1 py-0.5 sm:py-0">
            <p className="line-clamp-2 text-[15.5px] font-bold leading-snug text-ink sm:line-clamp-none sm:text-lg lg:text-xl">{quiz.title}</p>
            <p className="mt-0.5 text-[13px] text-muted sm:mt-1 sm:text-[15px]">{quiz.assessmentType === 'practical' ? 'Practical Exam' : 'Knowledge Quiz'}</p>
            <div className="mt-2 flex flex-col gap-1.5 sm:mt-3 sm:gap-2">
              <QuizFactsRow quiz={quiz} />
              {schedule ? <FactItem icon={CalendarClock} label={schedule} /> : null}
            </div>
            {record && toTake ? (
              <p className="mt-2 text-[13.5px] font-semibold text-brand">
                {record.answeredCount} of {record.questionIds.length} answered
              </p>
            ) : null}
            {attempt && !attempt.answersRevealed ? <p className="mt-2.5 text-[13.5px] font-semibold text-brand">Answers submitted</p> : null}
            {attempt?.answersRevealed ? (
              <div className="mt-2.5 max-w-sm">
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
        {action ? (
          <div className="sm:pr-2">
            <PillButton
              as="span"
              label={action.label}
              look={action.look}
              icon={action.icon}
              fillIcon
              trailing={ChevronRight}
              className="w-full sm:min-h-[52px] sm:w-auto sm:gap-2.5 sm:px-6 sm:text-base"
            />
          </div>
        ) : null}
      </div>
    </GlassCard>
  )
}
