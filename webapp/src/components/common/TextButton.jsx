// Flat dialog action; [danger] uses the error colour, [muted] the quiet one.
export default function TextButton({ children, onClick, danger = false, muted = false }) {
  const color = danger ? 'text-danger' : muted ? 'text-muted' : 'text-brand'
  return (
    <button type="button" onClick={onClick} className={`qs-press min-h-10 rounded-full px-3 text-sm font-medium hover:bg-brand-soft ${color}`}>
      {children}
    </button>
  )
}
