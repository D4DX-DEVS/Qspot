import { paintNightScene } from '../../../art/nightScene'
import ArtBadge from '../../../components/scene/ArtBadge'
import SceneArt from '../../../components/scene/SceneArt'

// The open Qur'ān before a moonlit mosque, with a lantern.
const paintThumb = (ctx, w, h, p) =>
  paintNightScene(ctx, w, h, p, {
    horizon: 0.58,
    water: 0.1,
    moon: { x: 0.26, y: 0.24, r: 0.09 },
    city: { x: 0.5, width: 0.62, height: 0.36 },
    book: { x: 0.5, y: 0.74, width: 0.5 },
    lanterns: [{ x: 0.88, top: 0, length: 0.46 }],
    stars: false,
  })

// A quiz card's picture with its status badge in the corner: a small square
// beside the words on phones, wider on bigger screens; it zooms in a little
// while its card is hovered. [faded] for quizzes that are over.
export default function QuizThumb({ badge, dot, pulse = false, faded = false }) {
  return (
    <div className="relative size-[96px] shrink-0 overflow-hidden rounded-xl border border-[rgb(228_88_154/0.45)] sm:h-[132px] sm:w-[220px] sm:rounded-2xl lg:h-[150px] lg:w-[260px]">
      <div className={`absolute inset-0 transition-transform duration-500 ease-out motion-safe:group-hover:scale-[1.06] ${faded ? 'opacity-60 saturate-[0.6]' : ''}`}>
        <SceneArt paint={paintThumb} />
      </div>
      <ArtBadge compact label={badge} dot={dot} pulse={pulse} className="absolute left-1.5 top-1.5 sm:left-2.5 sm:top-2.5" />
    </div>
  )
}
