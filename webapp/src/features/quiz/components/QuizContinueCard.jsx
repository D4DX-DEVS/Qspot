import { PencilLine } from 'lucide-react'
import SoftIconTile from '../../../components/common/SoftIconTile'
import SurfaceCard from '../../../components/common/SurfaceCard'
import TintedPillLink from '../../../components/common/TintedPillLink'

// A quiz started on this device that can be continued, even offline.
export default function QuizContinueCard({ record, onContinue }) {
  const title = record.title || 'Your quiz'
  const progress = `In progress · ${record.answeredCount} of ${record.questionIds.length} answered`
  return (
    <SurfaceCard onClick={() => onContinue(record)} padding="p-3.5" label={`${title}. ${progress}. Continue`}>
      <div className="flex items-center gap-3">
        <SoftIconTile icon={PencilLine} tone="mint" size={46} />
        <div className="min-w-0 flex-1">
          <p className="text-[15.5px] font-bold text-ink">{title}</p>
          <p className="mt-1 text-[13px] text-muted">{progress}</p>
        </div>
        <TintedPillLink label="Continue" tone="mint" />
      </div>
    </SurfaceCard>
  )
}
