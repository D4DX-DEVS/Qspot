// Material-style alert: title, message and right-aligned actions, on the card
// colour with 18px corners (home theme's dialogTheme).
export default function AlertDialog({ icon, title, children, actions, centered = false }) {
  return (
    <div role="alertdialog" aria-modal="true" aria-label={typeof title === 'string' ? title : undefined} className="qs-dialog max-h-[calc(100dvh-48px)] w-full max-w-[400px] overflow-y-auto rounded-[18px] bg-card p-6 shadow-2xl">
      {icon ? <div className="mb-4 flex justify-center text-brand">{icon}</div> : null}
      <h2 className={`text-lg font-bold text-ink ${centered ? 'text-center text-xl' : ''}`}>{title}</h2>
      <div className={`mt-4 ${centered ? 'text-center' : ''}`}>{children}</div>
      <div className={`mt-6 flex flex-wrap items-center gap-2 ${centered ? 'justify-center' : 'justify-end'}`}>{actions}</div>
    </div>
  )
}
