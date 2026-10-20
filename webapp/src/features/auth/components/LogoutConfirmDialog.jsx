import { LogOut } from 'lucide-react'
import AlertDialog from '../../../components/common/AlertDialog'
import DialogIcon from '../../../components/common/DialogIcon'
import DialogPillActions from '../../../components/common/DialogPillActions'

// "Are you sure you want to logout?" Closes with true only on Logout.
export default function LogoutConfirmDialog({ onClose }) {
  return (
    <AlertDialog
      centered
      onClose={() => onClose(false)}
      icon={<DialogIcon icon={LogOut} />}
      title="Logout"
      actions={<DialogPillActions quiet="Cancel" main="Logout" onQuiet={() => onClose(false)} onMain={() => onClose(true)} />}
    >
      <p className="text-[15px] text-muted sm:text-base">Are you sure you want to logout?</p>
    </AlertDialog>
  )
}
