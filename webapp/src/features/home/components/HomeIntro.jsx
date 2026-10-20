import Entrance from '../../../components/common/Entrance'
import LoadingSkeleton from '../../../components/common/LoadingSkeleton'
import HomeGreeting from './HomeGreeting'
import HomeHeroCard from './HomeHeroCard'
import HomeStatsStrip from './HomeStatsStrip'

// Top of home: greeting, the hero card and the student's numbers. Shows
// placeholders until the first list arrives. [onStatsOpen] makes the
// numbers lead to the finished quizzes.
export default function HomeIntro({ name, hero, stats, certificates, loading, onHeroAction, onStatsOpen }) {
  return (
    <div>
      <Entrance>
        <HomeGreeting name={name} />
        {loading ? <LoadingSkeleton className="h-[230px] w-full lg:h-[270px]" radius={24} /> : <HomeHeroCard hero={hero} onAction={onHeroAction} />}
      </Entrance>
      <div className="mt-4 sm:mt-6">
        {loading ? (
          <div className="grid grid-cols-3 gap-2.5 sm:gap-4 lg:gap-6" role="status" aria-label="Loading">
            {[0, 1, 2].map((i) => (
              <LoadingSkeleton key={i} className="h-[110px] w-full" radius={22} />
            ))}
          </div>
        ) : (
          <HomeStatsStrip taken={stats.taken} average={stats.average} certificates={certificates} onOpen={onStatsOpen} />
        )}
      </div>
    </div>
  )
}
