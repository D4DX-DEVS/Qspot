import { RefreshCw } from 'lucide-react'
import OfflineNotice from '../../../components/common/OfflineNotice'
import SectionHeader from '../../../components/common/SectionHeader'
import SoftOutlineButton from '../../../components/common/SoftOutlineButton'
import QuizContinueCard from './QuizContinueCard'

// Shown instead of the list when it cannot load but quizzes started here are
// saved: they can be continued offline.
export default function QuizOfflineContinueList({ quizzes, onContinue, onRetry }) {
  return (
    <div className="flex flex-col gap-3">
      <OfflineNotice message="Can't load quizzes right now. You can carry on with a quiz you started; your answers are saved on this device." />
      <SectionHeader title="Continue Your Quiz" />
      {quizzes.map((record) => (
        <QuizContinueCard key={record.quizId} record={record} onContinue={onContinue} />
      ))}
      <div className="mt-2 flex justify-center">
        <SoftOutlineButton icon={RefreshCw} label="Try Again" onClick={onRetry} />
      </div>
    </div>
  )
}
