import BottomSheet from './BottomSheet'
import ElevatedButton from './ElevatedButton'
import SoftIconTile from './SoftIconTile'

// Short sheet explaining why something can't be opened: tinted icon circle,
// bold title, a friendly line and one dismiss button.
export default function NoticeSheet({ icon, tone = 'slate', title, message, buttonLabel = 'Got It', onClose }) {
  return (
    <BottomSheet label={title}>
      <div className="flex flex-col items-center px-6 pb-5 pt-7 text-center">
        <SoftIconTile icon={icon} tone={tone} size={72} circle />
        <h2 className="mt-4 text-[19px] font-bold text-ink">{title}</h2>
        <p className="mt-2 text-sm leading-normal text-muted">{message}</p>
        <div className="mt-6 w-full">
          <ElevatedButton full tall onClick={onClose}>
            {buttonLabel}
          </ElevatedButton>
        </div>
      </div>
    </BottomSheet>
  )
}
