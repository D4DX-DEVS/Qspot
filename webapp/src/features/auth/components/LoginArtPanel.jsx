import { paintArchWindow } from '../../../art/archWindow'
import { paintNightScene } from '../../../art/nightScene'
import BrandLockup from '../../../components/brand/BrandLockup'
import Entrance from '../../../components/common/Entrance'
import SceneArt from '../../../components/scene/SceneArt'
import SwayingLantern from '../../../components/scene/SwayingLantern'
import TwinkleStars from '../../../components/scene/TwinkleStars'
import AuthHeadline from './AuthHeadline'

// Wide screens: a tall arch onto the mosque over the water and the open
// Qur'ān on its stand (the swaying lanterns hang in front of it).
const paintWide = (ctx, w, h, p) =>
  paintArchWindow(ctx, w, h, p, {
    inset: 0.05,
    top: 0.015,
    shoulder: 0.3,
    scene: {
      horizon: 0.68,
      water: 0.09,
      moon: { x: 0.64, y: 0.535, r: 0.038 },
      city: { x: 0.5, width: 0.82, height: 0.19 },
      book: { x: 0.5, y: 0.82, width: 0.36 },
    },
  })

// Phones: the night sky edge to edge, the moon on the right and the skyline
// just above the sign-in sheet (the lanterns sway on the left).
const paintNarrow = (ctx, w, h, p) =>
  paintNightScene(ctx, w, h, p, {
    horizon: 0.9,
    water: 0,
    moon: { x: 0.83, y: 0.19, r: 0.07 },
    city: { x: 0.5, width: 0.95, height: 0.21 },
  })

const HEADLINE = {
  title: 'Learn the ',
  accent: 'Qur’an,',
  trailing: '\none episode at a time.',
  subtitle: 'Sign in with your details to continue your learning journey.',
}

// The sign-in picture: QSPOT and the welcome words in a night sky. Beside
// the form inside an arch on wide screens (pinned while it scrolls); on
// phones a shorter sky above the sign-in sheet, which overlaps its foot.
export default function LoginArtPanel() {
  return (
    <section className="relative min-h-[clamp(300px,45dvh,390px)] overflow-hidden px-6 pb-16 pt-[calc(24px+env(safe-area-inset-top))] sm:px-10 lg:sticky lg:top-0 lg:h-dvh lg:min-h-0 lg:px-[11%] lg:pb-0 lg:pt-[max(40px,7dvh)]">
      <div className="absolute inset-0 lg:hidden">
        <SceneArt paint={paintNarrow} />
        <TwinkleStars count={10} area={{ left: 0.04, right: 0.96, top: 0.04, bottom: 0.6 }} seed={5} />
        <SwayingLantern x={0.07} length={0.3} />
        <SwayingLantern x={0.16} length={0.2} delay={900} time={4.1} />
      </div>
      <div className="absolute inset-0 hidden lg:block">
        <SceneArt paint={paintWide} />
        <TwinkleStars count={14} area={{ left: 0.15, right: 0.85, top: 0.2, bottom: 0.52 }} seed={9} />
        <SwayingLantern x={0.13} length={0.3} />
        <SwayingLantern x={0.22} length={0.21} delay={700} time={4.2} />
        <SwayingLantern x={0.87} length={0.25} delay={1500} time={5.2} />
      </div>
      <Entrance className="relative">
        <div className="flex justify-center lg:hidden">
          <BrandLockup onArt mark={52} />
        </div>
        <div className="hidden lg:block">
          <BrandLockup stacked onArt mark={124} />
        </div>
        <div className="mt-4 lg:mt-7">
          <AuthHeadline center onArt {...HEADLINE} fontSize="clamp(25px, 2.6vw, 40px)" subtitleFontSize="clamp(14px, 1.25vw, 19px)" />
        </div>
      </Entrance>
    </section>
  )
}
