import Entrance from '../../../components/common/Entrance'
import LoadingSkeleton from '../../../components/common/LoadingSkeleton'
import CheckboxRow from './CheckboxRow'

// Multi-select course list; placeholder rows while loading and nothing at all
// when there are no courses.
export default function CoursePicker({ courses, selectedIds, loading, onToggle }) {
  if (!loading && courses.length === 0) return null
  return (
    <div>
      <h2 className="text-[15px] font-semibold text-ink">Choose Your Courses</h2>
      <p className="mt-1 text-[12.5px] text-muted">You can choose more than one and change this later.</p>
      <div className="mt-2">
        {loading ? (
          <div className="flex flex-col gap-2" aria-label="Loading courses">
            <LoadingSkeleton className="h-16 w-full" radius={16} />
            <LoadingSkeleton className="h-16 w-full" radius={16} />
          </div>
        ) : (
          <Entrance rise={12} className="divide-y divide-line overflow-hidden rounded-2xl border border-line bg-card">
            {courses.map((course) => (
              <CheckboxRow
                key={course.id}
                checked={selectedIds.has(course.id)}
                onChange={(checked) => onToggle(course.id, checked)}
                title={course.title}
                subtitle={course.subtitle}
              />
            ))}
          </Entrance>
        )}
      </div>
    </div>
  )
}
