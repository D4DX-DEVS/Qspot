import { useEffect } from 'react'
import { CircleAlert } from 'lucide-react'
import { useNavigate } from 'react-router-dom'
import PageShell from '../../../components/common/PageShell'
import SkyBackdrop from '../../../components/common/SkyBackdrop'
import StateMessageView from '../../../components/common/StateMessageView'
import { useLocalNotifier, useNotifier } from '../../../lib/useNotifier'
import { authStore } from '../../auth/stores/authStore'
import { CertificatesStore } from '../../certificate/stores/certificatesStore'
import { openAccount, openHeroQuiz } from '../../home/actions/homeActions'
import HomeIntro from '../../home/components/HomeIntro'
import HomeTopBar from '../../home/components/HomeTopBar'
import { featuredQuiz, quizStats } from '../../home/models/homeSummary'
import { continueQuiz, openQuizFromList } from '../actions/quizListActions'
import QuizListContent from '../components/QuizListContent'
import QuizOfflineContinueList from '../components/QuizOfflineContinueList'
import { quizStore } from '../stores/quizStore'

// Home: a greeting over the sky, the quiz to take next, the student's numbers
// and every quiz (quiz_list_screen.dart, dressed like the app's Today tab).
// Answers that could not be sent go out whenever this loads or the
// connection comes back.
export default function QuizListPage() {
  const quiz = useNotifier(quizStore)
  const auth = useNotifier(authStore)
  const certificates = useLocalNotifier(() => new CertificatesStore())
  const navigate = useNavigate()

  useEffect(() => {
    quizStore.fetchQuizList()
    certificates.loadOnce()
    const onOnline = () => quizStore.fetchQuizList()
    window.addEventListener('online', onOnline)
    return () => window.removeEventListener('online', onOnline)
  }, [certificates])

  const reload = () => {
    quizStore.fetchQuizList()
    certificates.load()
  }
  const firstLoad = quiz.isListLoading && quiz.quizList.length === 0
  const hero = featuredQuiz({ quizList: quiz.quizList, inProgress: quiz.inProgressQuizzes, waiting: quiz.pendingSubmissions })

  let body
  if (quiz.hasListError && quiz.inProgressQuizzes.length) {
    body = <QuizOfflineContinueList quizzes={quiz.inProgressQuizzes} onContinue={(r) => continueQuiz(r, navigate)} onRetry={reload} />
  } else if (quiz.hasListError) {
    body = <StateMessageView icon={CircleAlert} title="Error Loading Quizzes" message={quiz.listError} onRetry={reload} />
  } else if (!firstLoad) {
    body = <QuizListContent quiz={quiz} navigate={navigate} onOpen={(q) => openQuizFromList(q, navigate)} />
  }

  return (
    <div className="relative min-h-dvh overflow-x-hidden bg-bg">
      <div className="absolute inset-x-0 top-0 h-[300px] md:h-[340px]">
        <SkyBackdrop />
      </div>
      <div className="relative">
        <HomeTopBar name={auth.user?.name} refreshing={quiz.isListLoading} onRefresh={reload} onAccount={() => openAccount(navigate)} />
        <PageShell width="max-w-4xl">
          {quiz.hasListError ? null : (
            <HomeIntro
              name={auth.user?.name}
              hero={hero}
              stats={quizStats(quiz.quizList)}
              certificates={certificates.items.length}
              loading={firstLoad}
              onHeroAction={() => openHeroQuiz(hero, navigate)}
            />
          )}
          <div className="mt-2">{body}</div>
        </PageShell>
      </div>
    </div>
  )
}
