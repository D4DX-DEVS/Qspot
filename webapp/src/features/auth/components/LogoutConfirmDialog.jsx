import AlertDialog from '../../../components/common/AlertDialog'
import TextButton from '../../../components/common/TextButton'

// "Are you sure you want to logout?" Closes with true only on Logout.
export default function LogoutConfirmDialog({ onClose }) {
  return (
    <AlertDialog
      title="Logout"
      actions={
        <>
          <TextButton onClick={() => onClose(false)}>Cancel</TextButton>
          <TextButton danger onClick={() => onClose(true)}>
            Logout
          </TextButton>
        </>
      }
    >
      <p className="text-base text-muted">Are you sure you want to logout?</p>
    </AlertDialog>
  )
}
