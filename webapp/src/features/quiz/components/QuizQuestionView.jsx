import { optionsFor, questionText } from '../models/quizModels'
import DifficultyChip from './DifficultyChip'
import QuizOptionTile from './QuizOptionTile'

// The current question: difficulty, text and its options, fading in when the
// question changes (keyed by the page).
export default function QuizQuestionView({ question, locale, selected, onPick }) {
  const options = optionsFor(question, locale)
  return (
    <div className="qs-fade mx-auto w-full max-w-3xl p-4">
      <DifficultyChip difficulty={question.difficulty} />
      <h2 className="mt-6 text-xl font-bold leading-[1.4] text-ink" lang={locale === 'ml' ? 'ml' : 'en'}>
        {questionText(question, locale)}
      </h2>
      <div className="mt-6 flex flex-col gap-4" role="radiogroup" aria-label="Options" lang={locale === 'ml' ? 'ml' : 'en'}>
        {options.map((option, index) => (
          <QuizOptionTile key={`${question.id}-${index}`} label={option} selected={selected === index} onPick={() => onPick(index)} />
        ))}
      </div>
    </div>
  )
}
