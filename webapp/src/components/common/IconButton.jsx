// Round 48px icon button for app bars and dialogs; its icon grows a touch
// on hover.
export default function IconButton({ icon: Icon, label, onClick, className = '' }) {
  return (
    <button
      type="button"
      aria-label={label}
      title={label}
      onClick={onClick}
      className={`group qs-press grid size-12 shrink-0 place-items-center rounded-full text-ink hover:bg-brand-soft ${className}`}
    >
      <Icon size={24} aria-hidden="true" className="transition-transform duration-200 motion-safe:group-hover:scale-110" />
    </button>
  )
}
