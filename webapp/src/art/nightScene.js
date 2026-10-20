import { crescent } from '../features/auth/art/mosqueSkyline'
import { paintHangingLantern } from '../features/auth/art/hangingLantern'
import { paintBook, paintCity, paintFloor, paintSky, paintWater } from './nightLayers'

// A full night scene: starry sky, crescent moon, a mosque over still water,
// a rug, the open Qur'ān on its stand and hanging lanterns. Every position
// is a fraction of the canvas, so one setting fits any size.
//
// horizon   where the city stands (0 top .. 1 bottom)
// water     depth of the water below it (0 for none)
// moon      { x, y, r } (r of the shorter side), or null
// city      { x, width, height }
// palms     palms beside the mosque
// book      { x, y, width }, or null
// lanterns  [{ x, top, length }]: hung from [top], [length] of the height
// stars     a starry sky
const DEFAULTS = {
  horizon: 0.64,
  water: 0.1,
  moon: { x: 0.62, y: 0.3, r: 0.06 },
  city: { x: 0.5, width: 0.9, height: 0.3 },
  palms: true,
  book: null,
  lanterns: [],
  stars: true,
}

export function paintNightScene(ctx, w, h, p, options = {}) {
  const o = { ...DEFAULTS, ...options }
  const horizonY = h * o.horizon
  const waterBottom = Math.min(h, horizonY + h * o.water)
  const drawCity = () => paintCity(ctx, w, h, horizonY, p, o.city, o.palms)

  paintSky(ctx, w, horizonY, p, o.stars)
  if (o.moon) crescent(ctx, w * o.moon.x, h * o.moon.y, Math.min(w, h) * o.moon.r, p)
  drawCity()
  if (o.water > 0) paintWater(ctx, w, horizonY, waterBottom, p, drawCity, o.moon ? w * o.moon.x : null)
  if (waterBottom < h) paintFloor(ctx, w, waterBottom, h, p)
  if (o.book) paintBook(ctx, w * o.book.x, h * o.book.y, w * o.book.width, p)
  paintLanterns(ctx, w, h, p, o.lanterns)
}

// Glowing lanterns, each hung from [top] on a chain, [length] of the height
// long (body included), at [x] across.
export function paintLanterns(ctx, w, h, p, lanterns) {
  for (const lantern of lanterns) {
    const lh = h * lantern.length
    const lw = lh * 0.27
    ctx.save()
    ctx.translate(w * lantern.x - lw / 2, h * lantern.top)
    paintHangingLantern(ctx, lw, lh, p)
    ctx.restore()
  }
}
