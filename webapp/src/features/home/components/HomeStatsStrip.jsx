import { Award, CircleCheck, Target } from 'lucide-react'
import Entrance from '../../../components/common/Entrance'
import StatTile from '../../../components/common/StatTile'

// Quizzes done, average score and certificates, side by side.
export default function HomeStatsStrip({ taken, average, certificates }) {
  const tiles = [
    { icon: CircleCheck, tone: 'teal', value: taken, label: 'Quizzes Done' },
    { icon: Target, tone: 'amber', value: average == null ? '–' : `${average}%`, label: 'Average Score' },
    { icon: Award, tone: 'rose', value: certificates, label: certificates === 1 ? 'Certificate' : 'Certificates' },
  ]
  return (
    <div className="grid grid-cols-3 gap-2.5">
      {tiles.map((tile, index) => (
        <Entrance key={tile.label} index={index + 1}>
          <StatTile {...tile} />
        </Entrance>
      ))}
    </div>
  )
}
