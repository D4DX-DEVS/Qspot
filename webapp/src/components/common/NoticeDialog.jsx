import AlertDialog from './AlertDialog'
import DialogIcon from './DialogIcon'
import PillButton from './PillButton'

// Short message or warning in a centred dialog: tinted icon, bold title, a
// friendly line and one dismiss button.
export default function NoticeDialog({ icon, tone = 'slate', title, message, buttonLabel = 'Got It', onClose }) {
  return (
    <AlertDialog centered icon={<DialogIcon icon={icon} tone={tone} />} title={title} actions={<PillButton size="lg" full label={buttonLabel} onClick={onClose} />}>
      <p className="text-[15px] leading-normal text-muted">{message}</p>
    </AlertDialog>
  )
}
