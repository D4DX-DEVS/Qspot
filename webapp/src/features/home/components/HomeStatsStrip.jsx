import { Award, CircleCheck, Target } from 'lucide-react'
import Entrance from '../../../components/common/Entrance'
import StatTile from '../../../components/common/StatTile'

// Quizzes done, average score and certificates, side by side. [onOpen],
// when set, makes them buttons that lead to the finished quizzes.
export default function HomeStatsStrip({ taken, average, certificates, onOpen }) {
  const tiles = [
    { icon: CircleCheck, tone: 'mint', value: taken, label: 'Quizzes Done' },
    { icon: Target, tone: 'amber', value: average == null ? '–' : `${average}%`, label: 'Average Score' },
    { icon: Award, tone: 'rose', value: certificates, label: certificates === 1 ? 'Certificate' : 'Certificates' },
  ]
  return (
    <div className="grid grid-cols-3 gap-2.5 sm:gap-4 lg:gap-6">
      {tiles.map((tile, index) => (
        <Entrance key={tile.label} index={index + 1}>
          <StatTile {...tile} onClick={onOpen} />
        </Entrance>
      ))}
    </div>
  )
}
