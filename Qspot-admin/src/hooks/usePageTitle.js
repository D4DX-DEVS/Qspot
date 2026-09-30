import { useEffect } from 'react';

// Sets document.title for the lifetime of the page. Single implementation
// so every page gets a real tab title instead of the Vite default.
export default function usePageTitle(title) {
  useEffect(() => {
    const previous = document.title;
    document.title = title ? `${title} · QSpot Admin` : 'QSpot Admin';
    return () => {
      document.title = previous;
    };
  }, [title]);
}
