import { withAlpha } from '../../../theme/authPalette'

// Vertical fade: solid [color] down to [fadeAt] (0..1), clear at the bottom.
export function verticalFade(ctx, top, bottom, color, fadeAt) {
  const g = ctx.createLinearGradient(0, top, 0, bottom)
  g.addColorStop(fadeAt, color)
  g.addColorStop(1, withAlpha(color, 0))
  return g
}

// Runs [draw] with a blur when the browser supports canvas filters
// (Flutter's MaskFilter.blur); without support it draws unblurred.
export function blurred(ctx, sigma, draw) {
  ctx.save()
  if ('filter' in ctx) ctx.filter = `blur(${sigma}px)`
  draw()
  ctx.restore()
}
