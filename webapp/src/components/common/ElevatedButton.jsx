import Spinner from './Spinner'

// Stadium button in the pink-to-coral action colours (dialogs, retry,
// notices). [full] stretches it; [tall] is the 52px notice-sheet size.
export default function ElevatedButton({ children, onClick, disabled = false, loading = false, full = false, tall = false, type = 'button' }) {
  return (
    <button
      type={type}
      onClick={onClick}
      disabled={disabled || loading}
      style={{ backgroundImage: 'var(--qs-cta)', boxShadow: '0 6px 16px var(--qs-cta-shadow)' }}
      className={`qs-press inline-flex items-center justify-center gap-2 px-6 text-sm font-semibold text-white disabled:opacity-60 ${
        tall ? 'min-h-[52px] rounded-full text-[15px]' : 'min-h-11 rounded-full'
      } ${full ? 'w-full' : ''}`}
    >
      {loading ? <Spinner size={18} /> : null}
      {children}
    </button>
  )
}
