import { paintArchWindow } from '../../../art/archWindow'
import SceneArt from '../../../components/scene/SceneArt'
import SwayingLantern from '../../../components/scene/SwayingLantern'
import TwinkleStars from '../../../components/scene/TwinkleStars'

// A wide arch onto the moonlit mosque and the open Qur'ān (the lanterns
// sway in front).
const paintHero = (ctx, w, h, p) =>
  paintArchWindow(ctx, w, h, p, {
    inset: 0.015,
    top: -0.45,
    shoulder: 0.2,
    scene: {
      horizon: 0.66,
      water: 0.14,
      moon: { x: 0.33, y: 0.24, r: 0.085 },
      city: { x: 0.42, width: 0.5, height: 0.5 },
      book: { x: 0.72, y: 0.64, width: 0.3 },
    },
  })

// The hero card's picture: a banner across the top that fades into the card
// on phones, or the right side fading into the card on its left on wider
// screens, so the words never sit on the busy part.
export default function HomeHeroArt() {
  return (
    <div aria-hidden="true" className="absolute inset-x-0 top-0 h-40 sm:inset-y-0 sm:left-auto sm:h-auto sm:w-[64%]">
      <SceneArt paint={paintHero} />
      <TwinkleStars count={8} area={{ left: 0.08, right: 0.9, top: 0.05, bottom: 0.38 }} seed={13} />
      <SwayingLantern x={0.93} length={0.62} />
      <SwayingLantern x={0.6} length={0.38} delay={800} time={4.3} />
      <div className="absolute inset-0 bg-[linear-gradient(to_bottom,rgb(67_10_40/0)_45%,#430a28)] sm:bg-[linear-gradient(to_right,#430a28,rgb(67_10_40/0)_42%)]" />
    </div>
  )
}
