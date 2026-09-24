import { useEffect } from 'react';

// Locks body scroll while `active` is true (e.g. a modal/sheet is open).
// Single implementation shared by every modal/dialog in the app.
export default function useBodyScrollLock(active = true) {
  useEffect(() => {
    if (!active) return undefined;
    const previousOverflow = document.body.style.overflow;
    document.body.style.overflow = 'hidden';
    return () => {
      document.body.style.overflow = previousOverflow;
    };
  }, [active]);
}
