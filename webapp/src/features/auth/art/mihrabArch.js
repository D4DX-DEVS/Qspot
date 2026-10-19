import { blurred, verticalFade } from './canvasTools'

// Pointed (ogee) arch that frames the logo and headline, fading out at the
// bottom; dark mode gets a warm glowing rim (mihrab_arch_painter.dart).
function archPath(left, top, right, bottom) {
  const w = right - left
  const h = bottom - top
  const cx = left + w / 2
  const shoulder = top + h * 0.45
  const p = new Path2D()
  p.moveTo(left, bottom)
  p.lineTo(left, shoulder)
  p.bezierCurveTo(left, top + h * 0.2, cx - w * 0.06, top + h * 0.1, cx, top)
  p.bezierCurveTo(cx + w * 0.06, top + h * 0.1, right, top + h * 0.2, right, shoulder)
  p.lineTo(right, bottom)
  p.closePath()
  return p
}

export function paintMihrabArch(ctx, w, h, palette) {
  const halo = 14
  ctx.fillStyle = verticalFade(ctx, 0, h, palette.archHalo, 0.45)
  ctx.fill(archPath(0, 0, w, h))
  const arch = archPath(halo, halo, w - halo, h)
  ctx.fillStyle = verticalFade(ctx, halo, h, palette.archFill, 0.6)
  ctx.fill(arch)

  const rim = verticalFade(ctx, halo, h, palette.archEdge, 0.35)
  blurred(ctx, 6, () => {
    ctx.strokeStyle = rim
    ctx.lineWidth = 4
    ctx.stroke(arch)
  })
  ctx.strokeStyle = rim
  ctx.lineWidth = 1.2
  ctx.stroke(arch)
}
