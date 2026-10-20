import { withAlpha } from '../../../theme/authPalette'
import { blurred } from './canvasTools'

// Flat mosque skyline (domes, minarets, palms, crescent) for the bottom of the
// sign-in screens, optionally with an open Qur'ān on a stand in front
// (mosque_skyline_painter.dart).

export function dome(ctx, x, baseY, halfWidth, height) {
  ctx.beginPath()
  ctx.moveTo(x - halfWidth, baseY)
  ctx.bezierCurveTo(x - halfWidth * 1.2, baseY - height * 0.6, x - halfWidth * 0.25, baseY - height * 0.75, x, baseY - height)
  ctx.bezierCurveTo(x + halfWidth * 0.25, baseY - height * 0.75, x + halfWidth * 1.2, baseY - height * 0.6, x + halfWidth, baseY)
  ctx.closePath()
  ctx.fill()
}

const rect = (ctx, l, t, r, b) => ctx.fillRect(l, t, r - l, b - t)

export function minaret(ctx, x, ground, height, width) {
  const top = ground - height
  rect(ctx, x - width / 2, top, x + width / 2, ground)
  rect(ctx, x - width * 0.85, top + height * 0.28, x + width * 0.85, top + height * 0.32)
  ctx.beginPath()
  ctx.moveTo(x - width * 0.65, top)
  ctx.lineTo(x, top - height * 0.16)
  ctx.lineTo(x + width * 0.65, top)
  ctx.closePath()
  ctx.fill()
}

function archWindow(ctx, x, bottom, halfWidth, height) {
  ctx.beginPath()
  ctx.moveTo(x - halfWidth, bottom)
  ctx.lineTo(x - halfWidth, bottom - height + halfWidth)
  ctx.quadraticCurveTo(x - halfWidth, bottom - height, x, bottom - height)
  ctx.quadraticCurveTo(x + halfWidth, bottom - height, x + halfWidth, bottom - height + halfWidth)
  ctx.lineTo(x + halfWidth, bottom)
  ctx.closePath()
  ctx.fill()
}

export function mosque(ctx, w, g, cx, palette) {
  ctx.fillStyle = palette.skylineFar
  for (const side of [-1, 1]) {
    minaret(ctx, cx + side * w * 0.36, g, g * 0.55, w * 0.026)
    minaret(ctx, cx + side * w * 0.24, g, g * 0.78, w * 0.032)
    dome(ctx, cx + side * w * 0.15, g - g * 0.18, w * 0.055, g * 0.16)
    rect(ctx, cx + side * w * 0.15 - w * 0.05, g - g * 0.19, cx + side * w * 0.15 + w * 0.05, g)
  }
  rect(ctx, cx - w * 0.33, g - g * 0.14, cx + w * 0.33, g)
  rect(ctx, cx - w * 0.12, g - g * 0.32, cx + w * 0.12, g)
  dome(ctx, cx, g - g * 0.31, w * 0.13, g * 0.32)
  rect(ctx, cx - 1, g - g * 0.7, cx + 1, g - g * 0.62)

  // Arched windows on the prayer hall and side wings.
  ctx.fillStyle = palette.window
  for (const dx of [-0.07, 0, 0.07]) archWindow(ctx, cx + dx * w, g - g * 0.06, w * 0.022, g * 0.15)
  for (const dx of [-0.27, -0.21, 0.21, 0.27]) archWindow(ctx, cx + dx * w, g - g * 0.03, w * 0.014, g * 0.07)
}

// Palm leaning away from the centre ([side] -1 left, 1 right).
export function palm(ctx, baseX, baseY, side, ground, palette) {
  const height = ground * 0.55
  const top = { x: baseX + side * height * 0.1, y: baseY - height }

  ctx.strokeStyle = palette.skylineNear
  ctx.lineWidth = height * 0.06
  ctx.lineCap = 'round'
  ctx.beginPath()
  ctx.moveTo(baseX, baseY)
  ctx.quadraticCurveTo(baseX - side * height * 0.05, baseY - height * 0.55, top.x, top.y)
  ctx.stroke()

  // Filled, drooping fronds fanned from straight left to straight right.
  ctx.fillStyle = palette.skylineNear
  const reach = height * 0.5
  for (const degrees of [-175, -150, -120, -90, -60, -30, -5]) {
    const angle = (degrees * Math.PI) / 180
    const dir = { x: Math.cos(angle), y: Math.sin(angle) }
    const normal = { x: -dir.y, y: dir.x }
    const tip = { x: top.x + dir.x * reach, y: top.y + dir.y * reach + reach * 0.4 * Math.abs(dir.x) }
    const mid = { x: top.x + dir.x * reach * 0.55, y: top.y + dir.y * reach * 0.55 - reach * 0.1 }
    const upper = { x: mid.x + normal.x * reach * 0.12, y: mid.y + normal.y * reach * 0.12 }
    const lower = { x: mid.x - normal.x * reach * 0.12, y: mid.y - normal.y * reach * 0.12 }
    ctx.beginPath()
    ctx.moveTo(top.x, top.y)
    ctx.quadraticCurveTo(upper.x, upper.y, tip.x, tip.y)
    ctx.quadraticCurveTo(lower.x, lower.y, top.x, top.y)
    ctx.fill()
  }
}

export function crescent(ctx, cx, cy, radius, palette) {
  blurred(ctx, radius, () => {
    ctx.fillStyle = withAlpha(palette.moon, 0.25)
    ctx.beginPath()
    ctx.arc(cx, cy, radius * 1.8, 0, Math.PI * 2)
    ctx.fill()
  })
  // The moon minus an offset circle, drawn apart so the cut-out never erases
  // the sky behind it.
  const size = Math.ceil(radius * 2 + 4)
  const off = document.createElement('canvas')
  const ratio = ctx.getTransform().a || 1
  off.width = size * ratio
  off.height = size * ratio
  const o = off.getContext('2d')
  o.scale(ratio, ratio)
  const c = size / 2
  o.fillStyle = palette.moon
  o.beginPath()
  o.arc(c, c, radius, 0, Math.PI * 2)
  o.fill()
  o.globalCompositeOperation = 'destination-out'
  o.beginPath()
  o.arc(c + radius * 0.45, c - radius * 0.25, radius * 0.85, 0, Math.PI * 2)
  o.fill()
  ctx.drawImage(off, cx - c, cy - c, size, size)
}

// Open book on a cross-legged wooden stand, centred on [cx].
export function bookStand(ctx, cx, ground, bw, h, palette) {
  const bh = bw * 0.22
  const y = ground + (h - ground) * 0.25

  blurred(ctx, 4, () => {
    ctx.fillStyle = 'rgba(0, 0, 0, 0.12)'
    ctx.beginPath()
    ctx.ellipse(cx, h * 0.96, (bw * 0.9) / 2, (bh * 0.35) / 2, 0, 0, Math.PI * 2)
    ctx.fill()
  })

  ctx.strokeStyle = palette.wood
  ctx.lineWidth = bw * 0.05
  ctx.lineCap = 'round'
  for (const [from, to] of [
    [cx - bw * 0.3, cx + bw * 0.2],
    [cx + bw * 0.3, cx - bw * 0.2],
  ]) {
    ctx.beginPath()
    ctx.moveTo(from, h * 0.97)
    ctx.lineTo(to, y)
    ctx.stroke()
  }
  ctx.fillStyle = palette.wood
  ctx.beginPath()
  ctx.moveTo(cx - bw * 0.5, y - bh * 0.32)
  ctx.lineTo(cx, y + bh * 0.3)
  ctx.lineTo(cx + bw * 0.5, y - bh * 0.32)
  ctx.lineTo(cx + bw * 0.5, y - bh * 0.05)
  ctx.lineTo(cx, y + bh * 0.62)
  ctx.lineTo(cx - bw * 0.5, y - bh * 0.05)
  ctx.closePath()
  ctx.fill()

  const lerp = (a, b, t) => ({ x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t })
  for (const side of [-1, 1]) {
    const topOuter = { x: cx + side * bw * 0.45, y: y - bh * 0.75 }
    const bottomOuter = { x: cx + side * bw * 0.47, y: y - bh * 0.25 }
    ctx.fillStyle = palette.pages
    ctx.beginPath()
    ctx.moveTo(cx, y + bh * 0.35)
    ctx.quadraticCurveTo(cx + side * bw * 0.25, y + bh * 0.05, bottomOuter.x, bottomOuter.y)
    ctx.lineTo(topOuter.x, topOuter.y)
    ctx.quadraticCurveTo(cx + side * bw * 0.22, y - bh * 0.55, cx, y - bh * 0.15)
    ctx.closePath()
    ctx.fill()
    // A few lines of text on each page.
    ctx.strokeStyle = withAlpha(palette.wood, 0.3)
    ctx.lineWidth = 1
    ctx.lineCap = 'butt'
    for (const t of [0.3, 0.5, 0.7]) {
      const outer = lerp(topOuter, bottomOuter, t)
      const inner = lerp({ x: cx, y: y - bh * 0.15 }, { x: cx, y: y + bh * 0.35 }, t)
      const a = lerp(outer, inner, 0.12)
      const b = lerp(outer, inner, 0.85)
      ctx.beginPath()
      ctx.moveTo(a.x, a.y)
      ctx.lineTo(b.x, b.y)
      ctx.stroke()
    }
  }
}

// The scene is sized from the screen width, as in the app, but never wider
// than [maxSceneWidth], so on a desktop the book stand does not grow into the
// form; the floor and fade still span the whole width.
export function paintMosqueSkyline(ctx, w, h, palette, { showBookStand = true, showMoon = true, maxSceneWidth = 600 } = {}) {
  const ground = h * (showBookStand ? 0.72 : 0.9)
  const cx = w / 2
  const sw = Math.min(w, maxSceneWidth)
  ctx.fillStyle = palette.floor
  rect(ctx, 0, ground, w, h)
  mosque(ctx, sw, ground, cx, palette)
  for (const side of [-1, 1]) palm(ctx, cx + side * sw * 0.43, ground, side, ground, palette)

  // Fade the tops of the buildings into the page.
  const fade = ctx.createLinearGradient(0, 0, 0, ground)
  fade.addColorStop(0, withAlpha(palette.background, 0.7))
  fade.addColorStop(0.4, withAlpha(palette.background, 0))
  ctx.fillStyle = fade
  rect(ctx, 0, 0, w, ground)

  if (showMoon) crescent(ctx, cx - sw * 0.08, ground * 0.2, ground * 0.09, palette)
  if (showBookStand) bookStand(ctx, cx, ground, sw * 0.42, h, palette)
}
