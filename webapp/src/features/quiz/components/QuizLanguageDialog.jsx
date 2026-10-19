// Asks which language to take a quiz in; closes with 'en' or 'ml' (or null).
export default function QuizLanguageDialog({ onClose }) {
  const choice = (label, value) => (
    <button
      type="button"
      onClick={() => onClose(value)}
      className="qs-press h-[50px] flex-1 rounded-full bg-brand text-[15px] font-semibold text-card"
    >
      {label}
    </button>
  )
  return (
    <div role="dialog" aria-modal="true" aria-label="Select Quiz Language" className="qs-dialog w-full max-w-[400px] rounded-3xl border border-line bg-card p-6 text-center shadow-2xl">
      <h2 className="text-[19px] font-bold text-ink">Select Quiz Language</h2>
      <p className="mt-2 text-[13.5px] text-muted">This cannot be changed once the quiz starts.</p>
      <div className="mt-6 flex gap-3">
        {choice('English', 'en')}
        {choice('മലയാളം', 'ml')}
      </div>
      <button type="button" onClick={() => onClose(null)} className="mt-4 min-h-10 px-3 text-sm font-medium text-muted">
        Cancel
      </button>
    </div>
  )
}
