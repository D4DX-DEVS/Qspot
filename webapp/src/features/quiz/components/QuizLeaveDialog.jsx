import { DoorOpen } from 'lucide-react'
import AlertDialog from '../../../components/common/AlertDialog'
import DialogIcon from '../../../components/common/DialogIcon'
import DialogPillActions from '../../../components/common/DialogPillActions'

// Asked before leaving a timed quiz. Closes with true for "Leave".
export default function QuizLeaveDialog({ onClose }) {
  return (
    <AlertDialog
      centered
      onClose={() => onClose(false)}
      icon={<DialogIcon icon={DoorOpen} tone="amber" />}
      title="Leave This Quiz?"
      actions={<DialogPillActions quiet="Leave" main="Stay" onQuiet={() => onClose(true)} onMain={() => onClose(false)} />}
    >
      <p className="text-[15px] leading-normal text-muted">Your answers are saved on this device, but the timer keeps running while you are away.</p>
    </AlertDialog>
  )
}
