import Entrance from './Entrance'
import ElevatedButton from './ElevatedButton'
import SoftIconTile from './SoftIconTile'

// Centred empty / error message: big tinted icon circle, bold title, a short
// line and an optional Retry button.
export default function StateMessageView({ icon, title, message, onRetry }) {
  return (
    <div className="grid min-h-[60dvh] place-items-center p-6">
      <Entrance className="flex max-w-md flex-col items-center text-center">
        <SoftIconTile icon={icon} tone="rose" size={84} circle />
        <h2 className="mt-4 text-[19px] font-bold text-ink">{title}</h2>
        {message ? <p className="mt-2 text-sm leading-normal text-muted">{message}</p> : null}
        {onRetry ? (
          <div className="mt-6">
            <ElevatedButton onClick={onRetry}>Retry</ElevatedButton>
          </div>
        ) : null}
      </Entrance>
    </div>
  )
}
