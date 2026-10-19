import { useNotifier } from '../../lib/useNotifier'
import { toastStore } from '../../stores/toastStore'

const COLORS = { success: 'bg-toast-success', danger: 'bg-toast-danger', warning: 'bg-toast-warning' }

// Floating snack bar at the bottom, white text on the outcome colour. It sits
// above a bottom bar (the quiz's Next/Submit) when one sets --qs-toast-offset.
// Errors are announced at once; tap to dismiss.
export default function ToastHost() {
  const toast = useNotifier(toastStore).current
  return (
    <div
      className="pointer-events-none fixed inset-x-0 z-[60] flex justify-center px-4 pb-[max(16px,env(safe-area-inset-bottom))]"
      style={{ bottom: 'var(--qs-toast-offset, 0px)' }}
    >
      {toast ? (
        <div key={toast.id} role={toast.tone === 'danger' ? 'alert' : 'status'} className="qs-toast pointer-events-auto w-full max-w-[560px]">
          <button
            type="button"
            title="Dismiss"
            onClick={() => toastStore.hide()}
            className={`w-full rounded-lg px-4 py-3.5 text-left text-sm font-medium text-white shadow-lg ${COLORS[toast.tone] ?? COLORS.danger}`}
          >
            {toast.message}
          </button>
        </div>
      ) : null}
    </div>
  )
}
