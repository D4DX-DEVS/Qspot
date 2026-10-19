import SurfaceCard from '../../../components/common/SurfaceCard'
import ToneChip from '../../../components/common/ToneChip'
import { optionsFor, questionText } from '../models/quizModels'
import ReviewOptionRow from './ReviewOptionRow'

const answerAt = (options, index) => (index != null && index >= 0 && index < options.length ? options[index] : null)

// One graded question: verdict, text, options with the right and wrong picks
// marked, then the correct answer and the student's answer in words.
export default function ReviewQuestionCard({ number, result, locale }) {
  const options = optionsFor(result, locale)
  const verdict = result.isCorrect ? 'mint' : 'coral'
  return (
    <SurfaceCard borderClass={result.isCorrect ? 'border-mint/35' : 'border-coral/35'}>
      <div lang={locale}>
        <div className="flex items-center justify-between gap-2">
          <p className="text-[13.5px] font-medium text-muted">Question {number}</p>
          <ToneChip label={result.isCorrect ? 'Correct' : 'Incorrect'} tone={verdict} />
        </div>
        <p className="mt-4 text-[15.5px] font-semibold leading-[1.4] text-ink">{questionText(result, locale)}</p>
        <p className="mt-4 text-[13px] text-muted">Options</p>
        <div className="mt-2 flex flex-col gap-2">
          {options.map((option, i) => (
            <ReviewOptionRow key={i} label={option} correct={i === result.correctAnswer} wrongPick={i === result.attemptedAnswer && !result.isCorrect} />
          ))}
        </div>
        <div className="mt-4 flex flex-col gap-2">
          <div>
            <p className="text-xs text-muted">Correct answer</p>
            <p className="mt-0.5 text-sm font-bold text-mint">{answerAt(options, result.correctAnswer) ?? '-'}</p>
          </div>
          <div>
            <p className="text-xs text-muted">Your answer</p>
            <p className={`mt-0.5 text-sm font-bold ${result.isCorrect ? 'text-mint' : 'text-coral'}`}>
              {answerAt(options, result.attemptedAnswer) ?? 'Not answered'}
            </p>
          </div>
        </div>
      </div>
    </SurfaceCard>
  )
}
