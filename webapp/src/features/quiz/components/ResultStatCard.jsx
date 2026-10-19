import CountUpText from '../../../components/common/CountUpText'
import SurfaceCard from '../../../components/common/SurfaceCard'
import { tone as toneOf } from '../../../theme/tones'

// One of Total / Correct / To Revisit under the score.
export default function ResultStatCard({ icon: Icon, tone, value, label }) {
  return (
    <SurfaceCard padding="px-2 py-4" className="flex h-full flex-col items-center text-center">
      <Icon size={30} className={toneOf(tone).text} aria-hidden="true" />
      <p className="mt-2 text-2xl font-extrabold text-ink">
        <CountUpText text={String(value)} />
      </p>
      <p className="mt-1 text-[12.5px] text-muted">{label}</p>
    </SurfaceCard>
  )
}
