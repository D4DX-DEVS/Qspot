import { Clock3, FileText } from 'lucide-react'
import FactItem from '../../../components/common/FactItem'
import { minutesLabel, questionsLabel } from '../models/quizFacts'

// "10 Questions   5 min" with their icons (minutes only for a timed quiz).
export default function QuizFactsRow({ quiz, onArt = false }) {
  const minutes = minutesLabel(quiz)
  return (
    <div className="flex flex-wrap items-center gap-x-4 gap-y-1.5 sm:gap-x-6">
      <FactItem icon={FileText} label={questionsLabel(quiz)} onArt={onArt} />
      {minutes ? <FactItem icon={Clock3} label={minutes} onArt={onArt} /> : null}
    </div>
  )
}
