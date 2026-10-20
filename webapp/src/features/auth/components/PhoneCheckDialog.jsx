import { MessageCircleWarning } from 'lucide-react'
import AlertDialog from '../../../components/common/AlertDialog'
import ElevatedButton from '../../../components/common/ElevatedButton'
import TextButton from '../../../components/common/TextButton'

// Asks the student to be sure the typed number is real before the account is
// created: it is verified by a one-time code later, and an account whose
// number cannot be verified loses access to its data.
export default function PhoneCheckDialog({ phone, dialCode, onClose }) {
  return (
    <AlertDialog
      centered
      icon={<MessageCircleWarning size={36} aria-hidden="true" />}
      title="Check your phone number"
      actions={
        <>
          <TextButton onClick={() => onClose(false)}>Edit number</TextButton>
          <ElevatedButton onClick={() => onClose(true)}>Number is correct</ElevatedButton>
        </>
      }
    >
      <p className="text-xl font-bold text-brand">
        +{dialCode} {phone}
      </p>
      <p className="mt-3 text-[14.5px] leading-[1.45] text-muted">
        Please enter a valid number that you can use. We will verify it by sending a one-time code (OTP) later. If the
        number cannot be verified, your data will become inaccessible.
      </p>
    </AlertDialog>
  )
}
