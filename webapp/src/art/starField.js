import { seeded } from './seeded'

// [count] twinkling stars inside [area] (fractions of their box), each with
// its own size and rhythm; the same on every render for the same [seed].
export function starField(count, { left = 0, right = 1, top = 0, bottom = 0.5 } = {}, seed = 3) {
  const rand = seeded(seed)
  return Array.from({ length: count }, () => ({
    x: left + rand() * (right - left),
    y: top + rand() * (bottom - top),
    size: 1.5 + rand() * 2,
    delay: Math.round(rand() * 3000),
    time: 2.2 + rand() * 2.4,
  }))
}
