import { WifiOff } from 'lucide-react'
import TintedPillLink from '../../../components/common/TintedPillLink'

// The list could not be refreshed: the last one stays below this note.
export default function RefreshFailedNotice({ message, onRetry }) {
  return (
    <div role="status" className="flex flex-wrap items-center gap-x-3 gap-y-2 rounded-[14px] bg-amber-soft px-3 py-2.5">
      <WifiOff size={18} className="shrink-0 text-amber" aria-hidden="true" />
      <p className="min-w-0 flex-1 text-xs text-ink">Couldn't refresh, so this is your last list. {message}</p>
      <TintedPillLink label="Try Again" tone="amber" onClick={onRetry} />
    </div>
  )
}
