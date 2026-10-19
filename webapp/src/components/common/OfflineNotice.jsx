import { WifiOff } from 'lucide-react'

// Compact note shown when the saved copy is in use because the server cannot
// be reached.
export default function OfflineNotice({ message }) {
  return (
    <div className="flex items-center gap-2.5 rounded-[14px] bg-amber-soft px-3 py-2.5" role="status">
      <WifiOff size={18} className="shrink-0 text-amber" aria-hidden="true" />
      <p className="text-xs text-ink">{message}</p>
    </div>
  )
}
