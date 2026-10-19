import Spinner from './Spinner'

// Full-width 56px brand button with an icon ("View Certificate").
export default function FilledButton({ icon: Icon, label, onClick, loading = false, disabled = false }) {
  return (
    <button
      type="button"
      onClick={onClick}
      disabled={disabled || loading}
      className="qs-press flex h-14 w-full items-center justify-center gap-2 rounded-2xl bg-brand px-4 text-base font-bold text-on-brand disabled:opacity-60"
    >
      {loading ? <Spinner size={20} stroke={2.5} /> : <Icon size={22} aria-hidden="true" />}
      {label}
    </button>
  )
}
