import { useEffect } from 'react'
import { CircleAlert, ListChecks } from 'lucide-react'
import { useLocation, useNavigate, useParams } from 'react-router-dom'
import AppBar from '../../../components/common/AppBar'
import Entrance from '../../../components/common/Entrance'
import FilterChipBar from '../../../components/common/FilterChipBar'
import PageShell from '../../../components/common/PageShell'
import Spinner from '../../../components/common/Spinner'
import StateMessageView from '../../../components/common/StateMessageView'
import { useLocalNotifier, useNotifier } from '../../../lib/useNotifier'
import { ReviewFilterStore } from '../stores/reviewFilterStore'
import ReviewQuestionCard from '../components/ReviewQuestionCard'
import { QuizReviewStore } from '../stores/quizReviewStore'

// Per-question review, from server-graded results only (quiz_review_screen.dart).
export default function QuizReviewPage() {
  const { attemptId } = useParams()
  const navigate = useNavigate()
  const location = useLocation()
  const store = useLocalNotifier(() => new QuizReviewStore(attemptId, location.state))
  // Reads the filter (or an empty one while loading) so its changes redraw.
  const filter = useNotifier(store.filter ?? EMPTY)
  useEffect(() => {
    store.loadIfNeeded()
  }, [store])

  let body
  if (store.error) body = <StateMessageView icon={CircleAlert} title="Couldn't Load Your Answers" message={store.error} />
  else if (!store.filter) body = <div className="grid min-h-[50dvh] place-items-center text-brand"><Spinner size={36} stroke={3} /></div>
  else if (filter.total === 0) {
    body = <StateMessageView icon={ListChecks} title="No Quiz Results Available" message="This attempt has no per-question breakdown to show yet." />
  } else {
    body = (
      <PageShell>
        <div className="mb-4">
          {filter.showsFilter ? (
            <FilterChipBar options={['all', 'wrong']} selected={filter.filter} onSelect={(f) => filter.select(f)} labelFor={filter.labelFor} />
          ) : (
            <p className="text-sm text-muted">Detailed analysis of each question</p>
          )}
        </div>
        <div className="flex flex-col gap-4">
          {filter.visible.map(({ number, result }, index) => (
            <Entrance key={`${filter.filter}-${number}`} index={index}>
              <ReviewQuestionCard number={number} result={result} locale={store.language} />
            </Entrance>
          ))}
        </div>
      </PageShell>
    )
  }

  return (
    <div className="min-h-dvh bg-bg">
      <AppBar title="Questions & Answers" onBack={() => navigate(-1)} />
      {body}
    </div>
  )
}

const EMPTY = new ReviewFilterStore([])
