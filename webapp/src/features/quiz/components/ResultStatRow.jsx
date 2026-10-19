import { CircleCheck, CircleQuestionMark, RotateCcw } from 'lucide-react'
import Entrance from '../../../components/common/Entrance'
import ResultStatCard from './ResultStatCard'

// Total, Correct and To Revisit side by side, one height.
export default function ResultStatRow({ total, correct, wrong }) {
  return (
    <div className="grid grid-cols-3 gap-4">
      <Entrance index={1}>
        <ResultStatCard icon={CircleQuestionMark} tone="rose" value={total} label="Total" />
      </Entrance>
      <Entrance index={2}>
        <ResultStatCard icon={CircleCheck} tone="mint" value={correct} label="Correct" />
      </Entrance>
      <Entrance index={3}>
        <ResultStatCard icon={RotateCcw} tone="amber" value={wrong} label="To Revisit" />
      </Entrance>
    </div>
  )
}
