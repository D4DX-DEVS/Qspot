import Entrance from '../../../components/common/Entrance'
import LoadingSkeleton from '../../../components/common/LoadingSkeleton'
import HomeGreeting from './HomeGreeting'
import HomeHeroCard from './HomeHeroCard'
import HomeStatsStrip from './HomeStatsStrip'

// Top of home: greeting, the hero card and the student's numbers. Shows
// placeholders until the first list arrives.
export default function HomeIntro({ name, hero, stats, certificates, loading, onHeroAction }) {
  return (
    <div>
      <Entrance>
        <HomeGreeting name={name} />
        {loading ? <LoadingSkeleton className="h-[158px] w-full" radius={22} /> : <HomeHeroCard hero={hero} onAction={onHeroAction} />}
      </Entrance>
      <div className="mt-4">
        {loading ? (
          <div className="grid grid-cols-3 gap-2.5" role="status" aria-label="Loading">
            {[0, 1, 2].map((i) => (
              <LoadingSkeleton key={i} className="h-[94px] w-full" radius={16} />
            ))}
          </div>
        ) : (
          <HomeStatsStrip taken={stats.taken} average={stats.average} certificates={certificates} />
        )}
      </div>
    </div>
  )
}
