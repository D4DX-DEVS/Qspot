import { withAlpha } from '../../../theme/authPalette'

// Layered burgundy wave sweeping into the top-right corner (corner_wave_painter.dart).
export function paintCornerWave(ctx, w, h, palette) {
  ctx.fillStyle = withAlpha(palette.cornerEnd, 0.3)
  ctx.beginPath()
  ctx.moveTo(w * 0.3, 0)
  ctx.bezierCurveTo(w * 0.46, h * 0.05, w * 0.5, h * 0.42, w * 0.72, h * 0.5)
  ctx.bezierCurveTo(w * 0.88, h * 0.56, w * 0.95, h * 0.8, w, h)
  ctx.lineTo(w, 0)
  ctx.closePath()
  ctx.fill()

  // Gradient over the front wave's bounds, top-right to bottom-left.
  const g = ctx.createLinearGradient(w, 0, w * 0.44, h * 0.82)
  g.addColorStop(0, palette.cornerStart)
  g.addColorStop(1, palette.cornerEnd)
  ctx.fillStyle = g
  ctx.beginPath()
  ctx.moveTo(w * 0.44, 0)
  ctx.bezierCurveTo(w * 0.56, h * 0.02, w * 0.6, h * 0.3, w * 0.77, h * 0.38)
  ctx.bezierCurveTo(w * 0.9, h * 0.44, w * 0.96, h * 0.62, w, h * 0.82)
  ctx.lineTo(w, 0)
  ctx.closePath()
  ctx.fill()
}

// Soft layered pink waves along the bottom edge, with a deeper accent rising
// in the right corner (bottom_waves_painter.dart).
export function paintBottomWaves(ctx, w, h, palette) {
  ctx.fillStyle = palette.waveSoft
  ctx.beginPath()
  ctx.moveTo(0, h * 0.3)
  ctx.bezierCurveTo(w * 0.25, h * 0.05, w * 0.45, h * 0.7, w * 0.7, h * 0.45)
  ctx.bezierCurveTo(w * 0.85, h * 0.3, w * 0.95, h * 0.25, w, h * 0.15)
  ctx.lineTo(w, h)
  ctx.lineTo(0, h)
  ctx.closePath()
  ctx.fill()

  ctx.fillStyle = palette.waveMid
  ctx.beginPath()
  ctx.moveTo(0, h * 0.65)
  ctx.bezierCurveTo(w * 0.3, h * 0.4, w * 0.55, h * 0.95, w, h * 0.55)
  ctx.lineTo(w, h)
  ctx.lineTo(0, h)
  ctx.closePath()
  ctx.fill()

  const g = ctx.createLinearGradient(w, h, w * 0.62, h * 0.5)
  g.addColorStop(0, palette.cornerEnd)
  g.addColorStop(1, palette.waveMid)
  ctx.fillStyle = g
  ctx.beginPath()
  ctx.moveTo(w * 0.62, h)
  ctx.bezierCurveTo(w * 0.78, h * 0.85, w * 0.88, h * 0.62, w, h * 0.5)
  ctx.lineTo(w, h)
  ctx.closePath()
  ctx.fill()
}
