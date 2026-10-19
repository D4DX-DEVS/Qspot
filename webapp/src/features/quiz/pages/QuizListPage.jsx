import { useEffect } from 'react'
import { CircleAlert, LogOut, RefreshCw } from 'lucide-react'
import { useNavigate } from 'react-router-dom'
import AppBar from '../../../components/common/AppBar'
import IconButton from '../../../components/common/IconButton'
import PageShell from '../../../components/common/PageShell'
import StateMessageView from '../../../components/common/StateMessageView'
import { useNotifier } from '../../../lib/useNotifier'
import { logout } from '../../auth/actions/authActions'
import { continueQuiz, openQuizFromList } from '../actions/quizListActions'
import QuizListContent from '../components/QuizListContent'
import QuizListSkeleton from '../components/QuizListSkeleton'
import QuizOfflineContinueList from '../components/QuizOfflineContinueList'
import { quizStore } from '../stores/quizStore'

// The student's quizzes (quiz_list_screen.dart): always shows something
// sensible, from "no live quiz" to past scores. Answers that could not be
// sent go out whenever this loads or the connection comes back.
export default function QuizListPage() {
  const quiz = useNotifier(quizStore)
  const navigate = useNavigate()

  useEffect(() => {
    quizStore.fetchQuizList()
    const onOnline = () => quizStore.fetchQuizList()
    window.addEventListener('online', onOnline)
    return () => window.removeEventListener('online', onOnline)
  }, [])

  const reload = () => quizStore.fetchQuizList()
  let body
  if (quiz.isListLoading && quiz.quizList.length === 0) body = <QuizListSkeleton />
  else if (quiz.hasListError && quiz.inProgressQuizzes.length) {
    body = <QuizOfflineContinueList quizzes={quiz.inProgressQuizzes} onContinue={(r) => continueQuiz(r, navigate)} onRetry={reload} />
  } else if (quiz.hasListError) {
    body = <StateMessageView icon={CircleAlert} title="Error Loading Quizzes" message={quiz.listError} onRetry={reload} />
  } else {
    body = <QuizListContent quiz={quiz} navigate={navigate} onOpen={(q) => openQuizFromList(q, navigate)} />
  }

  return (
    <div className="min-h-dvh bg-bg">
      <AppBar
        title="Quiz"
        width="max-w-4xl"
        actions={
          <>
            <IconButton icon={RefreshCw} label="Refresh" onClick={reload} className={quiz.isListLoading ? 'opacity-50' : ''} />
            <IconButton icon={LogOut} label="Log out" onClick={() => logout(navigate)} />
          </>
        }
      />
      <PageShell width="max-w-4xl">{body}</PageShell>
    </div>
  )
}
