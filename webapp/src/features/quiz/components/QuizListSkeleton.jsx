import LoadingSkeleton from '../../../components/common/LoadingSkeleton'

// Placeholder cards while the quiz list loads.
export default function QuizListSkeleton() {
  return (
    <div className="flex flex-col gap-3 pt-2" aria-label="Loading quizzes" role="status">
      <LoadingSkeleton className="h-10 w-40" />
      {[0, 1, 2].map((i) => (
        <LoadingSkeleton key={i} className="h-[92px] w-full" radius={18} />
      ))}
    </div>
  )
}
