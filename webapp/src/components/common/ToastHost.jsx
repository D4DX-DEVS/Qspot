import { useNotifier } from '../../lib/useNotifier'
import { toastStore } from '../../stores/toastStore'

const COLORS = { success: 'bg-toast-success', danger: 'bg-toast-danger', warning: 'bg-toast-warning' }

// Floating snack bar at the bottom, white text on the outcome colour.
export default function ToastHost() {
  const toast = useNotifier(toastStore).current
  return (
    <div aria-live="polite" className="pointer-events-none fixed inset-x-0 bottom-0 z-[60] flex justify-center px-4 pb-[max(16px,env(safe-area-inset-bottom))]">
      {toast ? (
        <button
          key={toast.id}
          type="button"
          onClick={() => toastStore.hide()}
          className={`qs-toast pointer-events-auto w-full max-w-[560px] rounded-lg px-4 py-3.5 text-left text-sm font-medium text-white shadow-lg ${COLORS[toast.tone] ?? COLORS.danger}`}
        >
          {toast.message}
        </button>
      ) : null}
    </div>
  )
}
