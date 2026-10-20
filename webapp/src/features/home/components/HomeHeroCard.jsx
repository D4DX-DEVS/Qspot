import { CalendarClock, ChevronRight, Play } from 'lucide-react'
import PillButton from '../../../components/common/PillButton'
import SparkleAccent from '../../../components/common/SparkleAccent'
import ArtBadge from '../../../components/scene/ArtBadge'
import QuizFactsRow from '../../quiz/components/QuizFactsRow'
import HomeHeroArt from './HomeHeroArt'

const RESTING = {
  caughtUp: { title: "You're All Caught Up!", detail: 'Great work. New quizzes will show up here as soon as they open.' },
  empty: { title: 'Your First Quiz Is On Its Way', detail: 'Quizzes from your teacher will show up here.' },
}

// Burgundy card at the top of home with the night picture: the quiz to take
// next with its facts and button, the next one to open, or a cheer when
// there is nothing to do (TodayHeroCard in the app). [hero] comes from
// featuredQuiz(). Burgundy in light and dark mode alike.
export default function HomeHeroCard({ hero, onAction }) {
  const resting = RESTING[hero.kind]
  const title = resting ? resting.title : hero.quiz.title
  const live = hero.kind === 'live'
  return (
    <div className="relative overflow-hidden rounded-[24px] border border-[rgb(228_88_154/0.4)] bg-[#430a28] sm:bg-[radial-gradient(ellipse_at_0%_0%,rgb(170_32_96/0.5),transparent_65%)] shadow-[0_14px_34px_var(--qs-hero-shadow)]">
      <HomeHeroArt />
      <div className="relative flex flex-col justify-center px-5 pb-6 pt-[132px] text-white sm:min-h-[230px] sm:max-w-[62%] sm:px-9 sm:py-8 lg:min-h-[270px]">
        {hero.eyebrow ? (
          <div className="flex flex-wrap items-center gap-x-4 gap-y-2">
            <ArtBadge label={hero.eyebrow} dot={live ? 'hot' : 'upcoming'} pulse={live} className="tracking-[0.04em]" />
            {hero.meta ? <p className="text-sm text-white/85 sm:text-[15px]">{hero.meta}</p> : null}
          </div>
        ) : null}
        <div className="mt-4 flex items-start gap-2">
          <h2 className="min-w-0 text-[22px] font-extrabold leading-[1.2] sm:text-[28px] lg:text-[32px]">{title}</h2>
          {resting ? <SparkleAccent /> : null}
        </div>
        {resting ? (
          <p className="mt-2 text-sm text-white/85 sm:text-[15px]">{resting.detail}</p>
        ) : (
          <div className="mt-3">
            {hero.record ? <p className="mb-2 text-sm font-semibold">{hero.detail}</p> : null}
            <QuizFactsRow quiz={hero.quiz} onArt />
          </div>
        )}
        {hero.more > 0 ? (
          <p className="mt-2 text-[13px] text-white/80">
            +{hero.more} more live quiz{hero.more === 1 ? '' : 'zes'} below
          </p>
        ) : null}
        {hero.action ? (
          <div className="mt-5">
            <span className={`inline-block ${live ? 'qs-breathe' : ''}`}>
              <PillButton label={hero.action} icon={live ? Play : CalendarClock} fillIcon={live} trailing={ChevronRight} size="lg" onClick={onAction} />
            </span>
          </div>
        ) : null}
      </div>
    </div>
  )
}
