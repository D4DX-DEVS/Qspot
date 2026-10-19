import AlertDialog from '../../../components/common/AlertDialog'
import ElevatedButton from '../../../components/common/ElevatedButton'
import TextButton from '../../../components/common/TextButton'

// "Submit Quiz?" with how many questions are answered; closes with true to submit.
export default function QuizSubmitDialog({ answered, total, onClose }) {
  return (
    <AlertDialog
      title="Submit Quiz?"
      actions={
        <>
          <TextButton muted onClick={() => onClose(false)}>
            Cancel
          </TextButton>
          <ElevatedButton onClick={() => onClose(true)}>Submit</ElevatedButton>
        </>
      }
    >
      <p className="text-sm leading-normal text-muted">
        You have answered {answered} out of {total} questions.
      </p>
      <p className="mt-4 text-sm leading-normal text-muted">Do you want to submit the quiz?</p>
    </AlertDialog>
  )
}
