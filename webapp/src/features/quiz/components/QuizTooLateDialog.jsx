import AlertDialog from '../../../components/common/AlertDialog'
import ElevatedButton from '../../../components/common/ElevatedButton'
import { clockTimeUpper } from '../../../utils/formatDate'

// The answers reached the server after the quiz closed, so they could not be marked.
export default function QuizTooLateDialog({ endsAt, onClose }) {
  const closed = endsAt == null ? 'This quiz has closed' : `This quiz closed at ${clockTimeUpper(new Date(endsAt))}`
  return (
    <AlertDialog title="Submitted Too Late" actions={<ElevatedButton onClick={() => onClose()}>OK</ElevatedButton>}>
      <p className="text-sm leading-normal text-muted">
        {closed}, and your answers reached us after that, so they could not be marked. Please speak to your teacher.
      </p>
    </AlertDialog>
  )
}
