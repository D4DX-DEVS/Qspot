import GlassCard from '../../../components/common/GlassCard'
import { optionsFor, questionText } from '../models/quizModels'
import DifficultyChip from './DifficultyChip'
import QuizOptionTile from './QuizOptionTile'

// The current question on a glass card: difficulty, text and its options,
// sliding in when the question changes (keyed by the page).
export default function QuizQuestionView({ question, locale, selected, onPick }) {
  const options = optionsFor(question, locale)
  const lang = locale === 'ml' ? 'ml' : 'en'
  return (
    <div className="qs-slide-in">
      <GlassCard radius="rounded-[24px] sm:rounded-[28px]" padding="p-4 sm:p-8 lg:p-10">
        <DifficultyChip difficulty={question.difficulty} />
        <h2 className="mt-5 text-[21px] font-bold leading-[1.45] text-ink sm:mt-6 sm:text-[26px] lg:text-[30px]" lang={lang}>
          {questionText(question, locale)}
        </h2>
        <div className="mt-6 flex flex-col gap-3 sm:mt-8 sm:gap-4" role="radiogroup" aria-label="Options" lang={lang}>
          {options.map((option, index) => (
            <QuizOptionTile key={`${question.id}-${index}`} label={option} selected={selected === index} onPick={() => onPick(index)} />
          ))}
        </div>
      </GlassCard>
    </div>
  )
}
