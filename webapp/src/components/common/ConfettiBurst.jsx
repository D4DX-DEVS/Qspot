import { useEffect, useRef } from 'react'

const GRAVITY = 1.9
const COLORS = ['--qs-brand', '--qs-coral', '--qs-teal']
const EXTRA = ['#ffc107', '#ff7a59']

// Small seeded random, so the burst looks the same every time.
function seeded(seed) {
  let a = seed
  return () => {
    a = (a + 0x6d2b79f5) | 0
    let t = Math.imul(a ^ (a >>> 15), 1 | a)
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296
  }
}

function particles(count, palette) {
  const random = seeded(7)
  return Array.from({ length: count }, () => ({
    angle: -Math.PI / 2 + (random() - 0.5) * Math.PI * 0.9,
    speed: 0.55 + random() * 0.75,
    spin: (random() - 0.5) * 14,
    size: 5 + random() * 6,
    color: palette[Math.floor(random() * palette.length)],
    round: random() < 0.5,
  }))
}

// One burst of confetti from the bottom centre over its parent, for a good
// score (confetti_burst.dart). Skipped when the device asks for less motion.
export default function ConfettiBurst({ count = 36 }) {
  const ref = useRef(null)
  useEffect(() => {
    const canvas = ref.current
    if (!canvas || window.matchMedia('(prefers-reduced-motion: reduce)').matches) return undefined
    const styles = getComputedStyle(canvas)
    const palette = [...COLORS.map((name) => styles.getPropertyValue(name).trim()), ...EXTRA]
    const pieces = particles(count, palette)
    const ctx = canvas.getContext('2d')
    const start = performance.now()
    let frame = 0
    const draw = (time) => {
      const t = Math.min(1, (time - start) / 2200)
      const ratio = window.devicePixelRatio || 1
      const { width, height } = canvas.getBoundingClientRect()
      canvas.width = width * ratio
      canvas.height = height * ratio
      ctx.setTransform(ratio, 0, 0, ratio, 0, 0)
      ctx.clearRect(0, 0, width, height)
      ctx.globalAlpha = Math.min(1, Math.max(0, 1 - (t - 0.55) / 0.45))
      for (const p of pieces) {
        const dx = Math.cos(p.angle) * p.speed * height * t
        const dy = Math.sin(p.angle) * p.speed * height * t + GRAVITY * height * t * t * 0.5
        ctx.save()
        ctx.translate(width / 2 + dx, height + dy)
        ctx.rotate(p.spin * t)
        ctx.fillStyle = p.color
        if (p.round) {
          ctx.beginPath()
          ctx.arc(0, 0, p.size / 2, 0, Math.PI * 2)
          ctx.fill()
        } else {
          ctx.fillRect(-p.size / 2, (-p.size * 0.55) / 2, p.size, p.size * 0.55)
        }
        ctx.restore()
      }
      if (t < 1) frame = requestAnimationFrame(draw)
    }
    frame = requestAnimationFrame(draw)
    return () => cancelAnimationFrame(frame)
  }, [count])
  return <canvas ref={ref} aria-hidden="true" className="pointer-events-none fixed inset-0 z-10 size-full" />
}
