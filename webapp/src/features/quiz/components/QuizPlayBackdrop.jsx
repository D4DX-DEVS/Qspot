import { paintArchWindow } from '../../../art/archWindow'
import { paintBook } from '../../../art/nightLayers'
import LatticeBackdrop from '../../../components/scene/LatticeBackdrop'
import SceneArt from '../../../components/scene/SceneArt'
import SwayingLantern from '../../../components/scene/SwayingLantern'
import TwinkleStars from '../../../components/scene/TwinkleStars'

// Left margin: the open Qur'ān on its stand, under a swaying lantern.
const paintLeft = (ctx, w, h, p) => paintBook(ctx, w * 0.45, h * 0.8, Math.min(w * 0.85, h * 0.4), p)

// Right margin: an arch onto the moonlit mosque.
const paintRight = (ctx, w, h, p) =>
  paintArchWindow(ctx, w, h, p, {
    inset: 0.06,
    top: 0.02,
    shoulder: 0.3,
    scene: {
      horizon: 0.64,
      water: 0.12,
      moon: { x: 0.56, y: 0.26, r: 0.11 },
      city: { x: 0.45, width: 1.1, height: 0.24 },
    },
  })

// Behind the question page: the patterned wall and, on wide screens, night
// pictures in the margins beside the question.
export default function QuizPlayBackdrop() {
  return (
    <div aria-hidden="true" className="pointer-events-none fixed inset-0 overflow-hidden">
      <LatticeBackdrop glow="both" />
      <div className="hidden xl:block">
        <div className="absolute bottom-0 left-0 h-full w-[calc((100vw-1040px)/2)]">
          <SceneArt paint={paintLeft} />
          <SwayingLantern x={0.6} top={0.12} length={0.3} />
        </div>
        <div className="absolute right-0 top-[6%] h-[80%] w-[calc((100vw-1040px)/2)]">
          <SceneArt paint={paintRight} />
          <TwinkleStars count={8} area={{ left: 0.22, right: 0.78, top: 0.14, bottom: 0.48 }} seed={21} />
        </div>
      </div>
    </div>
  )
}
