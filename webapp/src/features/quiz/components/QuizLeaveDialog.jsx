import AlertDialog from '../../../components/common/AlertDialog'
import ElevatedButton from '../../../components/common/ElevatedButton'
import TextButton from '../../../components/common/TextButton'

// Asked before leaving a timed quiz. Closes with true for "Leave".
export default function QuizLeaveDialog({ onClose }) {
  return (
    <AlertDialog
      title="Leave This Quiz?"
      actions={
        <>
          <TextButton danger onClick={() => onClose(true)}>
            Leave
          </TextButton>
          <ElevatedButton onClick={() => onClose(false)}>Stay</ElevatedButton>
        </>
      }
    >
      <p className="text-sm leading-normal text-muted">
        Your answers are saved on this device, but the timer keeps running while you are away.
      </p>
    </AlertDialog>
  )
}
