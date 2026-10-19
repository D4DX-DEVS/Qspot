import { withAlpha } from '../../../theme/authPalette'

// Small hanging lantern with a soft glow, hung from the top of its box
// (hanging_lantern_painter.dart).
function roundRect(ctx, left, top, right, bottom, r) {
  ctx.beginPath()
  ctx.roundRect(left, top, right - left, bottom - top, r)
}

export function paintHangingLantern(ctx, w, h, palette) {
  const cx = w / 2
  const body = { x: cx, y: h * 0.65 }

  const glow = ctx.createRadialGradient(body.x, body.y, 0, body.x, body.y, w * 1.3)
  glow.addColorStop(0, withAlpha(palette.lanternGlow, 0.55))
  glow.addColorStop(1, withAlpha(palette.lanternGlow, 0))
  ctx.fillStyle = glow
  ctx.beginPath()
  ctx.arc(body.x, body.y, w * 1.3, 0, Math.PI * 2)
  ctx.fill()

  ctx.strokeStyle = palette.lanternFrame
  ctx.lineWidth = 1.2
  ctx.beginPath()
  ctx.moveTo(cx, 0)
  ctx.lineTo(cx, h * 0.4)
  ctx.stroke()

  ctx.fillStyle = palette.lanternFrame
  // Domed cap.
  ctx.beginPath()
  ctx.moveTo(cx - w * 0.3, h * 0.48)
  ctx.quadraticCurveTo(cx - w * 0.2, h * 0.4, cx, h * 0.38)
  ctx.quadraticCurveTo(cx + w * 0.2, h * 0.4, cx + w * 0.3, h * 0.48)
  ctx.closePath()
  ctx.fill()

  const left = cx - w * 0.34
  const right = cx + w * 0.34
  const top = h * 0.48
  const bottom = h * 0.82
  roundRect(ctx, left, top, right, bottom, w * 0.12)
  ctx.fill()
  const d = w * 0.08
  ctx.fillStyle = palette.lanternGlow
  roundRect(ctx, left + d, top + d, right - d, bottom - d, w * 0.08)
  ctx.fill()

  ctx.strokeStyle = palette.lanternFrame
  for (const dx of [-w * 0.1, w * 0.1]) {
    ctx.beginPath()
    ctx.moveTo(cx + dx, top + d)
    ctx.lineTo(cx + dx, bottom - d)
    ctx.stroke()
  }

  // Base and finial.
  ctx.fillStyle = palette.lanternFrame
  ctx.beginPath()
  ctx.moveTo(cx - w * 0.3, h * 0.82)
  ctx.lineTo(cx + w * 0.3, h * 0.82)
  ctx.lineTo(cx + w * 0.12, h * 0.89)
  ctx.lineTo(cx - w * 0.12, h * 0.89)
  ctx.closePath()
  ctx.fill()
  ctx.beginPath()
  ctx.arc(cx, h * 0.93, w * 0.06, 0, Math.PI * 2)
  ctx.fill()
}
