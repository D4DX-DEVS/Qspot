import { useEffect, useRef } from 'react'

// Text whose first whole number counts up from zero when it first shows
// (count_up_text.dart, 700ms ease-out). Screen readers get the final text.
export default function CountUpText({ text, className = '' }) {
  const ref = useRef(null)
  useEffect(() => {
    const node = ref.current
    const match = /\d+/.exec(text)
    if (!node || !match || window.matchMedia('(prefers-reduced-motion: reduce)').matches) return undefined
    const target = Number(match[0])
    const before = text.slice(0, match.index)
    const after = text.slice(match.index + match[0].length)
    const start = performance.now()
    let frame = 0
    const step = (time) => {
      const t = Math.min(1, (time - start) / 700)
      const eased = 1 - (1 - t) ** 3
      node.textContent = `${before}${Math.round(target * eased)}${after}`
      if (t < 1) frame = requestAnimationFrame(step)
    }
    frame = requestAnimationFrame(step)
    return () => {
      cancelAnimationFrame(frame)
      node.textContent = text
    }
  }, [text])
  return (
    <span className={className} aria-label={text}>
      <span ref={ref} aria-hidden="true">
        {text}
      </span>
    </span>
  )
}
