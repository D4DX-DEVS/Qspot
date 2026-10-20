import { blurred } from '../features/auth/art/canvasTools'
import { withAlpha } from '../theme/authPalette'
import { paintNightScene } from './nightScene'

// Pointed arch from [left] to [right] with its tip at [top] and straight
// sides from [shoulder] down to [bottom]. [closed] joins the bottom, for
// clipping; open, it is the frame line only.
export function pointedArch(left, top, right, bottom, shoulder, closed = true) {
  const w = right - left
  const cx = left + w / 2
  const rise = shoulder - top
  const path = new Path2D()
  path.moveTo(left, bottom)
  path.lineTo(left, shoulder)
  path.bezierCurveTo(left, shoulder - rise * 0.55, cx - w * 0.08, top + rise * 0.2, cx, top)
  path.bezierCurveTo(cx + w * 0.08, top + rise * 0.2, right, shoulder - rise * 0.55, right, shoulder)
  path.lineTo(right, bottom)
  if (closed) path.closePath()
  return path
}

// A night scene seen through a pointed arch with a dark frame and a warm,
// glowing rim; outside the arch stays clear for the page behind.
// inset     side margin (fraction of the width)
// top       the arch's tip; below 0 puts it above the canvas
// shoulder  where the sides turn into the arch (fraction of the height)
// scene     paintNightScene() options for the view inside
export function paintArchWindow(ctx, w, h, p, { inset = 0.04, top = 0.02, shoulder = 0.32, scene = {} } = {}) {
  const left = w * inset
  const right = w - w * inset
  const tip = h * top
  const turn = h * shoulder
  ctx.save()
  ctx.clip(pointedArch(left, tip, right, h + 2, turn))
  paintNightScene(ctx, w, h, p, scene)
  ctx.restore()

  const edge = pointedArch(left, tip, right, h + 2, turn, false)
  ctx.strokeStyle = p.archFrame
  ctx.lineWidth = Math.max(8, w * 0.022)
  ctx.stroke(edge)
  blurred(ctx, 8, () => {
    ctx.strokeStyle = withAlpha(p.archEdge, 0.6)
    ctx.lineWidth = 4
    ctx.stroke(edge)
  })
  ctx.strokeStyle = withAlpha(p.archEdge, 0.9)
  ctx.lineWidth = 1.3
  ctx.stroke(edge)
}
