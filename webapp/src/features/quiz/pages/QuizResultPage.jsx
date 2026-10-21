import { useEffect } from 'react'
import { CircleAlert, X } from 'lucide-react'
import { useLocation, useNavigate, useParams } from 'react-router-dom'
import AppBar from '../../../components/common/AppBar'
import ConfettiBurst from '../../../components/common/ConfettiBurst'
import Entrance from '../../../components/common/Entrance'
import IconButton from '../../../components/common/IconButton'
import PageShell from '../../../components/common/PageShell'
import Spinner from '../../../components/common/Spinner'
import StateMessageView from '../../../components/common/StateMessageView'
import { ANSWER_REVIEW_ENABLED } from '../../../config/env'
import { useLocalNotifier } from '../../../lib/useNotifier'
import { toastStore } from '../../../stores/toastStore'
import { dateAtTime } from '../../../utils/formatDate'
import ViewCertificateButton from '../../certificate/components/ViewCertificateButton'
import ResultAnswersRow from '../components/ResultAnswersRow'
import ResultHeroCard from '../components/ResultHeroCard'
import ResultStatRow from '../components/ResultStatRow'
import { QuizResultStore, resultFromAttempt } from '../stores/quizResultStore'

// A quiz outcome (quiz_results_screen.dart), from server fields only.
export default function QuizResultPage() {
  const { quizId } = useParams()
  const navigate = useNavigate()
  const location = useLocation()
  const store = useLocalNotifier(() => new QuizResultStore(quizId, location.state))
  useEffect(() => {
    store.loadIfNeeded()
  }, [store])

  const result = store.result
  const back = () => navigate('/quizzes')
  const review = (r) => navigate(`/attempts/${r.attemptId ?? 'latest'}/review`, { state: { results: r.results, language: r.language } })
  const loadReview = async () => {
    const { attempt, error } = await store.loadReview()
    if (attempt) review(resultFromAttempt(attempt))
    else if (error) toastStore.show(error, 'danger')
  }

  return (
    <div className="min-h-dvh bg-bg">
      <AppBar title="Quiz Results" leading={<IconButton icon={X} label="Close" onClick={back} />} />
      {!result ? (
        store.error ? (
          <StateMessageView icon={CircleAlert} title="Result Not Available" message={store.error} onRetry={back} />
        ) : (
          <div className="grid min-h-[50dvh] place-items-center text-brand">
            <Spinner size={36} stroke={3} />
          </div>
        )
      ) : (
        <PageShell>
          <Entrance>
            <ResultHeroCard title={result.title} percentage={result.percentage} />
          </Entrance>
          <div className="mt-6">
            <ResultStatRow total={result.totalQuestions} correct={store.correctCount} wrong={store.wrongCount} />
          </div>
          <div className="mt-6 flex flex-col gap-4">
            {ANSWER_REVIEW_ENABLED ? (
              <ResultAnswersRow result={result} loading={store.loadingReview} onReview={() => review(result)} onLoadReview={loadReview} />
            ) : null}
            {result.quizId ? <ViewCertificateButton quizId={result.quizId} /> : null}
          </div>
          {result.completedAt ? (
            <Entrance index={5} as="p" className="mt-6 text-center text-[13px] text-muted">
              Completed on {dateAtTime(new Date(result.completedAt))}
            </Entrance>
          ) : null}
          {store.scoredWell ? <ConfettiBurst /> : null}
        </PageShell>
      )}
    </div>
  )
}
