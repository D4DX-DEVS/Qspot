import { CloudUpload } from 'lucide-react'
import TintedPillLink from '../../../components/common/TintedPillLink'
import QuizNoticeBanner from './QuizNoticeBanner'

// Finished answers are still on this device, not yet accepted by the server,
// with a button to send them now.
export default function QuizPendingBanner({ message, sending, onSend }) {
  return (
    <QuizNoticeBanner icon={CloudUpload} tone="amber" message={message}>
      <TintedPillLink label={sending ? 'Sending…' : 'Send Now'} tone="amber" onClick={onSend} disabled={sending} />
    </QuizNoticeBanner>
  )
}
