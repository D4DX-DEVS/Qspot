import { GraduationCap, Star, ThumbsUp, Trophy } from 'lucide-react'
import CountUpText from '../../../components/common/CountUpText'
import GradientCard from '../../../components/common/GradientCard'

const iconFor = (pct) => (pct >= 90 ? Trophy : pct >= 70 ? Star : pct >= 50 ? ThumbsUp : GraduationCap)
const wordsFor = (pct) => (pct >= 90 ? 'Crushed It!' : pct >= 70 ? 'Nice Work!' : pct >= 50 ? 'Almost There!' : "Good Start, Let's Level Up!")

// Burgundy card with the score icon, quiz title, percentage and a cheer.
export default function ResultHeroCard({ title, percentage }) {
  const Icon = iconFor(percentage)
  const pct = `${percentage % 1 === 0 ? percentage.toFixed(0) : percentage.toFixed(1)}%`
  return (
    <GradientCard className="px-6 py-9 text-center text-white">
      <Icon size={72} className="mx-auto" aria-hidden="true" />
      <p className="mt-4 text-[15px] font-medium text-white/85">{title}</p>
      <p className="mt-2 text-[44px] font-extrabold leading-tight">
        <CountUpText text={pct} />
      </p>
      <p className="mt-1 text-xl font-bold">{wordsFor(percentage)}</p>
    </GradientCard>
  )
}
