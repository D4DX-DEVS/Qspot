import Spinner from './Spinner'

// Material-style stadium button in the brand colour (dialogs, retry, notices).
// [full] stretches it; [tall] is the 52px notice-sheet size.
export default function ElevatedButton({ children, onClick, disabled = false, loading = false, full = false, tall = false, type = 'button' }) {
  return (
    <button
      type={type}
      onClick={onClick}
      disabled={disabled || loading}
      className={`qs-press inline-flex items-center justify-center gap-2 bg-brand px-6 text-sm font-medium text-white shadow-[0_1px_3px_rgb(0_0_0/0.2)] disabled:opacity-60 ${
        tall ? 'min-h-[52px] rounded-2xl text-[15px] font-semibold' : 'min-h-10 rounded-full'
      } ${full ? 'w-full' : ''}`}
    >
      {loading ? <Spinner size={18} /> : null}
      {children}
    </button>
  )
}
