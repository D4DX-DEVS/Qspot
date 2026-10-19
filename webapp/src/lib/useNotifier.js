import { useRef, useSyncExternalStore } from 'react'

// Re-renders the component whenever [notifier] notifies; returns it so the
// component can read its getters (like Provider's Consumer).
export function useNotifier(notifier) {
  useSyncExternalStore(notifier.subscribe, notifier.getVersion, notifier.getVersion)
  return notifier
}

// A store that lives as long as the component (a screen-local provider),
// created once on first render.
export function useLocalNotifier(create) {
  const ref = useRef(null)
  if (ref.current === null) ref.current = create()
  return useNotifier(ref.current)
}
