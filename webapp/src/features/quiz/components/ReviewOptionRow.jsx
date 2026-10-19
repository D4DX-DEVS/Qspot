import { Check, X } from 'lucide-react'

// One option in the review: green with a tick when correct, red with a cross
// when it was the student's wrong pick.
export default function ReviewOptionRow({ label, correct, wrongPick }) {
  const marked = correct ? 'border-mint bg-mint-soft font-bold text-mint' : wrongPick ? 'border-coral bg-coral-soft font-bold text-coral' : 'border-line bg-brand-soft/50 text-ink dark:bg-brand-soft'
  return (
    <div className={`flex items-center gap-2 rounded-xl border px-3 py-2.5 text-sm ${marked}`}>
      <span className="min-w-0 flex-1">{label}</span>
      {correct ? <Check size={18} aria-label="Correct answer" /> : null}
      {wrongPick ? <X size={18} aria-label="Your answer" /> : null}
    </div>
  )
}
