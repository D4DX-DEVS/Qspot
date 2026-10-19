import { useEffect, useRef } from 'react'
import { useIsDark } from '../../../lib/colorScheme'
import { AUTH_PALETTE } from '../../../theme/authPalette'

// Paints decorative artwork with the light or dark palette, filling its
// (sized) parent and repainting on resize or a light/dark change (AuthArt in
// the app). [paint](ctx, width, height, palette) draws in CSS pixels.
// [palette] replaces the light/dark one, for art on a fixed-colour surface.
export default function AuthArt({ paint, palette: fixed = null, className = 'absolute inset-0' }) {
  const ref = useRef(null)
  const isDark = useIsDark()

  useEffect(() => {
    const canvas = ref.current
    if (!canvas) return undefined
    const palette = fixed ?? (isDark ? AUTH_PALETTE.dark : AUTH_PALETTE.light)
    const draw = () => {
      const { width, height } = canvas.getBoundingClientRect()
      if (width === 0 || height === 0) return
      const ratio = window.devicePixelRatio || 1
      canvas.width = Math.round(width * ratio)
      canvas.height = Math.round(height * ratio)
      const ctx = canvas.getContext('2d')
      ctx.setTransform(ratio, 0, 0, ratio, 0, 0)
      ctx.clearRect(0, 0, width, height)
      paint(ctx, width, height, palette)
    }
    draw()
    const observer = new ResizeObserver(draw)
    observer.observe(canvas)
    return () => observer.disconnect()
  }, [isDark, paint, fixed])

  return <canvas ref={ref} aria-hidden="true" className={`pointer-events-none size-full ${className}`} />
}
