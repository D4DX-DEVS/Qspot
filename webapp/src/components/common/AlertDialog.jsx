import { X } from 'lucide-react'

// Alert on a glass card with a warm rim: optional icon, title, message and
// actions (right-aligned, or centred with [centered]). [onClose] adds a
// close button in the corner.
export default function AlertDialog({ icon, title, children, actions, centered = false, onClose }) {
  return (
    <div
      role="alertdialog"
      aria-modal="true"
      aria-label={typeof title === 'string' ? title : undefined}
      className="qs-dialog relative max-h-[calc(100dvh-48px)] w-full max-w-[440px] overflow-y-auto rounded-[26px] border border-card-rim bg-glass-strong p-6 shadow-[0_0_44px_var(--qs-glass-glow),0_24px_60px_rgb(0_0_0/0.35)] backdrop-blur-md sm:p-8"
    >
      {onClose ? (
        <button type="button" aria-label="Close" onClick={onClose} className="qs-press absolute right-3 top-3 grid size-11 place-items-center rounded-full text-muted hover:bg-soft-fill hover:text-ink">
          <X size={22} aria-hidden="true" />
        </button>
      ) : null}
      {icon ? <div className="mb-4 flex justify-center text-brand">{icon}</div> : null}
      <h2 className={`font-bold text-ink ${centered ? 'text-center text-2xl sm:text-[26px]' : 'text-lg'}`}>{title}</h2>
      <div className={`mt-4 ${centered ? 'text-center' : ''}`}>{children}</div>
      <div className={`mt-6 flex flex-wrap items-center gap-2 ${centered ? 'justify-center' : 'justify-end'}`}>{actions}</div>
    </div>
  )
}
