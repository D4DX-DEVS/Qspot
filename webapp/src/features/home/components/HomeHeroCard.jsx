import { CalendarClock, Play } from 'lucide-react'
import GoldPillButton from '../../../components/common/GoldPillButton'
import GradientCard from '../../../components/common/GradientCard'
import SparkleAccent from '../../../components/common/SparkleAccent'
import HeroLantern from './HeroLantern'

const RESTING = {
  caughtUp: { title: "You're All Caught Up!", detail: 'Great work. New quizzes will show up here as soon as they open.' },
  empty: { title: 'Your First Quiz Is On Its Way', detail: 'Quizzes from your teacher will show up here.' },
}

// Burgundy card at the top of home: the quiz to take next with a gold
// button, the next one to open, or a cheer when there is nothing to do
// (TodayHeroCard in the app). [hero] comes from featuredQuiz().
export default function HomeHeroCard({ hero, onAction }) {
  const resting = RESTING[hero.kind]
  const title = resting ? resting.title : hero.quiz.title
  return (
    <GradientCard className="relative">
      <HeroLantern />
      <div className="flex min-h-[158px] flex-col justify-center px-5 pb-5 pt-[22px] pr-14 text-white">
        {hero.eyebrow ? (
          <div className="flex flex-wrap items-baseline gap-x-3 gap-y-1">
            <p className="flex items-center gap-1.5 text-[11.5px] font-bold tracking-[0.6px] text-white/70">
              {hero.kind === 'live' ? <span className="size-2 animate-pulse rounded-full bg-[#fbd495]" aria-hidden="true" /> : null}
              {hero.eyebrow}
            </p>
            {hero.meta ? <p className="text-xs text-white/70">{hero.meta}</p> : null}
          </div>
        ) : null}
        <div className="mt-2.5 flex items-start gap-2">
          <h2 className="min-w-0 text-xl font-bold leading-[1.2] md:text-2xl">{title}</h2>
          {resting ? <SparkleAccent /> : null}
        </div>
        <p className="mt-1.5 text-xs text-white/70 md:text-[13px]">{resting ? resting.detail : hero.detail}</p>
        {hero.more > 0 ? (
          <p className="mt-1 text-xs text-white/70">
            +{hero.more} more live quiz{hero.more === 1 ? '' : 'zes'} below
          </p>
        ) : null}
        {hero.action ? (
          <div className="mt-4">
            <GoldPillButton label={hero.action} icon={hero.kind === 'live' ? Play : CalendarClock} onClick={onAction} breathe={hero.kind === 'live'} />
          </div>
        ) : null}
      </div>
    </GradientCard>
  )
}
