import AlertDialog from '../../../components/common/AlertDialog'
import ElevatedButton from '../../../components/common/ElevatedButton'
import TextButton from '../../../components/common/TextButton'

const logoutWarningMessage = (count) =>
  `You have answers for ${count === 1 ? '1 quiz' : `${count} quizzes`} that have not been sent yet. If you log out now, they will be deleted from this device and cannot be marked.`

// Warns before logging out with quiz answers the server does not have yet.
// Closes with true only for "Log Out and Delete".
export default function QuizLogoutWarningDialog({ count, onClose }) {
  return (
    <AlertDialog
      title="Unsent Quiz Answers"
      actions={
        <>
          <TextButton danger onClick={() => onClose(true)}>
            Log Out and Delete
          </TextButton>
          <ElevatedButton onClick={() => onClose(false)}>Stay Logged In</ElevatedButton>
        </>
      }
    >
      <p className="text-[15px] leading-normal text-muted">{logoutWarningMessage(count)}</p>
      <p className="mt-4 text-[15px] leading-normal text-muted">Stay logged in and open Quiz with an internet connection to send them.</p>
    </AlertDialog>
  )
}
