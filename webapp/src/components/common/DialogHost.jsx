import { useEffect } from 'react'
import { useNotifier } from '../../lib/useNotifier'
import { dialogStore } from '../../stores/dialogStore'

// Draws open dialogs (centred) and bottom sheets over a dim scrim. Escape or a
// tap outside dismisses the top one unless it is not dismissible.
export default function DialogHost() {
  const { stack } = useNotifier(dialogStore)
  const top = stack.at(-1)

  useEffect(() => {
    if (!top?.dismissible) return undefined
    const onKey = (e) => {
      if (e.key === 'Escape') top.dismiss()
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [top])

  useEffect(() => {
    document.body.style.overflow = stack.length ? 'hidden' : ''
  }, [stack.length])

  return stack.map((dialog) => (
    <div
      key={dialog.id}
      className={`fixed inset-0 z-50 flex bg-[var(--qs-scrim)] backdrop-blur-[3px] ${dialog.kind === 'sheet' ? 'items-end justify-center' : 'items-center justify-center p-6'}`}
      onMouseDown={(e) => {
        if (e.target === e.currentTarget && dialog.dismissible) dialog.dismiss()
      }}
    >
      {dialog.render(dialog.close)}
    </div>
  ))
}
