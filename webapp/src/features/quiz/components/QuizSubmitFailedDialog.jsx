import AlertDialog from '../../../components/common/AlertDialog'
import ElevatedButton from '../../../components/common/ElevatedButton'
import TextButton from '../../../components/common/TextButton'

// Submit could not reach the server: the answers are safe on this device.
// Closes with true for "Try Again", false for "Later".
export default function QuizSubmitFailedDialog({ onClose }) {
  return (
    <AlertDialog
      title="Couldn't Submit Yet"
      actions={
        <>
          <TextButton muted onClick={() => onClose(false)}>
            Later
          </TextButton>
          <ElevatedButton onClick={() => onClose(true)}>Try Again</ElevatedButton>
        </>
      }
    >
      <p className="text-sm leading-normal text-muted">Your answers are saved on this device, so nothing is lost.</p>
      <p className="mt-4 text-sm leading-normal text-muted">
        Check your connection and try again. If you leave now, they will be sent automatically the next time you open
        Quiz with a connection.
      </p>
    </AlertDialog>
  )
}
