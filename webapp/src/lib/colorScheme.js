import { useSyncExternalStore } from 'react'

const query = typeof window === 'undefined' ? null : window.matchMedia('(prefers-color-scheme: dark)')

function subscribe(listener) {
  query?.addEventListener('change', listener)
  return () => query?.removeEventListener('change', listener)
}

const isDark = () => query?.matches ?? false

// True while the device is in dark mode; follows changes live, like the
// app's platformBrightness.
export function useIsDark() {
  return useSyncExternalStore(subscribe, isDark, () => false)
}
