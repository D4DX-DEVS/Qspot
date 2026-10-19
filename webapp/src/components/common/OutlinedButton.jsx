import Spinner from './Spinner'

// Full-width 56px outlined brand button ("Review Answers").
export default function OutlinedButton({ icon: Icon, label, onClick, loading = false }) {
  return (
    <button
      type="button"
      onClick={onClick}
      disabled={loading}
      className="qs-press flex h-14 w-full items-center justify-center gap-2 rounded-2xl border-[1.5px] border-brand px-4 text-base font-bold text-brand hover:bg-brand-soft disabled:opacity-60"
    >
      {loading ? <Spinner size={18} /> : <Icon size={22} aria-hidden="true" />}
      {label}
    </button>
  )
}
