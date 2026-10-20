import { blurred } from '../features/auth/art/canvasTools'
import { bookStand, dome, minaret, mosque, palm } from '../features/auth/art/mosqueSkyline'
import { withAlpha } from '../theme/authPalette'
import { seeded } from './seeded'

// The layers of a night scene, back to front: sky, city, water, floor and
// the open Qur'ān on its stand. Each takes the canvas size and the palette
// (theme/scenePalette.js).

const TAU = Math.PI * 2

// Indigo-to-ember sky with a warm glow rising from the horizon and stars.
export function paintSky(ctx, w, horizonY, p, withStars) {
  const sky = ctx.createLinearGradient(0, 0, 0, horizonY)
  sky.addColorStop(0, p.skyTop)
  sky.addColorStop(0.45, p.skyMid)
  sky.addColorStop(0.82, p.skyLow)
  sky.addColorStop(1, p.horizon)
  ctx.fillStyle = sky
  ctx.fillRect(0, 0, w, horizonY)

  ctx.save()
  ctx.beginPath()
  ctx.rect(0, 0, w, horizonY)
  ctx.clip()
  ctx.translate(w / 2, horizonY)
  ctx.scale(1, 0.4)
  const glow = ctx.createRadialGradient(0, 0, 0, 0, 0, w * 0.6)
  glow.addColorStop(0, withAlpha(p.horizonGlow, 0.6))
  glow.addColorStop(1, withAlpha(p.horizonGlow, 0))
  ctx.fillStyle = glow
  ctx.beginPath()
  ctx.arc(0, 0, w * 0.6, 0, TAU)
  ctx.fill()
  ctx.restore()

  if (!withStars) return
  const rand = seeded(7)
  const count = Math.min(140, Math.round((w * horizonY) / 4500))
  for (let i = 0; i < count; i += 1) {
    const x = rand() * w
    const y = rand() * horizonY * 0.62
    const r = 0.4 + rand() * 0.9
    ctx.fillStyle = withAlpha(p.star, 0.2 + rand() * 0.6)
    ctx.beginPath()
    ctx.arc(x, y, r, 0, TAU)
    ctx.fill()
  }
}

// Low, hazy buildings along the whole horizon, some lit.
function distantCity(ctx, w, horizonY, height, p) {
  const rand = seeded(11)
  const lit = []
  ctx.fillStyle = p.skylineBack
  for (let x = -height * 0.3; x < w; ) {
    const bw = height * (0.35 + rand() * 0.6)
    const bh = height * (0.25 + rand() * 0.6)
    ctx.fillRect(x, horizonY - bh, bw, bh + 1)
    const kind = rand()
    if (kind < 0.3) dome(ctx, x + bw / 2, horizonY - bh + 1, bw * 0.42, bh * 0.55)
    else if (kind < 0.5) minaret(ctx, x + bw / 2, horizonY - bh + 1, bh * 1.3, bw * 0.16)
    if (rand() < 0.55) lit.push([x + bw * (0.2 + rand() * 0.6), horizonY - bh * (0.2 + rand() * 0.5)])
    x += bw * (0.7 + rand() * 0.5)
  }
  ctx.fillStyle = withAlpha(p.window, 0.7)
  const size = Math.max(1, height * 0.06)
  for (const [x, y] of lit) ctx.fillRect(x, y, size, size * 1.4)
}

// Distant city, the mosque and two palms, standing on [horizonY].
// [city] is { x, width, height } in fractions of the canvas.
export function paintCity(ctx, w, h, horizonY, p, city, withPalms) {
  const cx = w * city.x
  const height = h * city.height
  distantCity(ctx, w, horizonY, height * 0.32, p)
  // mosque() sizes itself from its ground line (its tallest point is about
  // 0.9 of it), so draw it on a taller ground moved down to the horizon.
  // Its width is capped so wide, short canvases don't flatten the domes.
  const g = height / 0.9
  const sw = Math.min(w * city.width, g * 3.4)
  ctx.save()
  ctx.translate(0, horizonY - g)
  mosque(ctx, sw, g, cx, p)
  ctx.restore()
  if (!withPalms) return
  for (const side of [-1, 1]) palm(ctx, cx + side * sw * 0.5, horizonY + 1, side, (height * 0.7) / 0.55, p)
}

// Still water mirroring the city, with ripples of window light and the
// moon's path.
export function paintWater(ctx, w, top, bottom, p, drawCity, moonX) {
  const water = ctx.createLinearGradient(0, top, 0, bottom)
  water.addColorStop(0, p.waterTop)
  water.addColorStop(1, p.water)
  ctx.fillStyle = water
  ctx.fillRect(0, top, w, bottom - top)

  ctx.save()
  ctx.beginPath()
  ctx.rect(0, top, w, bottom - top)
  ctx.clip()
  ctx.globalAlpha = 0.3
  ctx.translate(0, 2 * top)
  ctx.scale(1, -1)
  drawCity()
  ctx.restore()

  const rand = seeded(23)
  const depth = bottom - top
  for (let i = 0, n = Math.round(w / 12); i < n; i += 1) {
    const y = top + 2 + rand() * (depth - 2)
    ctx.fillStyle = withAlpha(p.window, 0.06 + rand() * 0.2)
    ctx.fillRect(rand() * w, y, 4 + rand() * w * 0.05, 1)
  }
  if (moonX == null) return
  for (let y = top + 3, i = 0; y < bottom; y += Math.max(3, depth / 12), i += 1) {
    const t = (y - top) / depth
    const len = w * (0.02 + t * 0.06) * (i % 2 ? 0.6 : 1)
    ctx.fillStyle = withAlpha(p.moon, 0.4 * (1 - t))
    ctx.fillRect(moonX - len / 2, y, len, 1.2)
  }
}

// Floor in front of the water with a patterned rug in perspective.
export function paintFloor(ctx, w, top, h, p) {
  const floor = ctx.createLinearGradient(0, top, 0, h)
  floor.addColorStop(0, p.floorTop)
  floor.addColorStop(1, p.floor)
  ctx.fillStyle = floor
  ctx.fillRect(0, top, w, h - top)

  const depth = h - top
  const rugTop = top + depth * 0.35
  const rug = new Path2D()
  rug.moveTo(w * 0.2, rugTop)
  rug.lineTo(w * 0.8, rugTop)
  rug.lineTo(w * 1.05, h)
  rug.lineTo(w * -0.05, h)
  rug.closePath()
  ctx.fillStyle = withAlpha(p.carpet, 0.75)
  ctx.fill(rug)
  ctx.strokeStyle = withAlpha(p.archEdge, 0.35)
  ctx.lineWidth = 1
  ctx.stroke(rug)
  // A row of small diamonds along the rug's far border.
  const y = rugTop + depth * 0.12
  ctx.fillStyle = withAlpha(p.archEdge, 0.3)
  for (let x = w * 0.2; x < w * 0.82; x += w * 0.035) {
    const s = depth * 0.03
    ctx.beginPath()
    ctx.moveTo(x, y - s)
    ctx.lineTo(x + s, y)
    ctx.lineTo(x, y + s)
    ctx.lineTo(x - s, y)
    ctx.closePath()
    ctx.fill()
  }
}

// The open Qur'ān on its cross-legged stand, the book centred at
// ([cx], [bookY]) and [bw] wide, warmly lit from behind.
export function paintBook(ctx, cx, bookY, bw, p) {
  blurred(ctx, bw * 0.1, () => {
    ctx.fillStyle = withAlpha(p.lanternGlow, 0.14)
    ctx.beginPath()
    ctx.ellipse(cx, bookY, bw * 0.6, bw * 0.3, 0, 0, TAU)
    ctx.fill()
  })
  // bookStand() places the book a quarter of the way from [ground] to [h]
  // and the feet at 0.97 of [h]; solve both for the book's centre.
  const bottom = (bookY + bw * 0.5) / 0.97
  const ground = (bookY - 0.25 * bottom) / 0.75
  bookStand(ctx, cx, ground, bw, bottom, p)
}
