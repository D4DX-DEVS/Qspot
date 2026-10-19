import { CircleAlert } from 'lucide-react'
import TintedPillLink from '../../../components/common/TintedPillLink'
import QuizNoticeBanner from './QuizNoticeBanner'

// The answers were not accepted and why, with OK to dismiss and, when the
// quiz can be taken again, "Open Quiz Again".
export default function QuizRefusedBanner({ message, onDismiss, onReopen }) {
  return (
    <QuizNoticeBanner icon={CircleAlert} tone="coral" message={message}>
      {onReopen ? <TintedPillLink label="Open Quiz Again" tone="mint" onClick={onReopen} /> : null}
      <TintedPillLink label="OK" tone="coral" onClick={onDismiss} />
    </QuizNoticeBanner>
  )
}
