import { ArrowRight, FileCheck2 } from 'lucide-react'
import AlertDialog from '../../../components/common/AlertDialog'
import DialogIcon from '../../../components/common/DialogIcon'
import DialogPillActions from '../../../components/common/DialogPillActions'

// "Submit Quiz?" with how many questions are answered; closes with true to
// submit, false on Cancel or the close button.
export default function QuizSubmitDialog({ answered, total, onClose }) {
  return (
    <AlertDialog
      centered
      onClose={() => onClose(false)}
      icon={<DialogIcon icon={FileCheck2} />}
      title="Submit Quiz?"
      actions={<DialogPillActions quiet="Cancel" main="Submit" mainIcon={ArrowRight} onQuiet={() => onClose(false)} onMain={() => onClose(true)} />}
    >
      <p className="text-[15px] leading-relaxed text-muted sm:text-base">
        You have answered {answered} out of {total} questions.
        <br />
        Do you want to submit the quiz?
      </p>
    </AlertDialog>
  )
}
