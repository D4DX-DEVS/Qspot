import { RefreshCw } from 'lucide-react'
import AppLogo from '../../../components/common/AppLogo'
import IconButton from '../../../components/common/IconButton'
import InitialsAvatar from '../../../components/common/InitialsAvatar'

// Logo on the left; refresh and the student's avatar (opens their account)
// on the right. Sits on the sky, so it has no fill of its own.
export default function HomeTopBar({ name, refreshing, onRefresh, onAccount }) {
  return (
    <header className="relative mx-auto flex w-full max-w-4xl items-center gap-1 px-4 pb-2 pt-[calc(12px+env(safe-area-inset-top))]">
      <div className="min-w-0 flex-1">
        <AppLogo width={124} />
      </div>
      <IconButton icon={RefreshCw} label="Refresh" onClick={onRefresh} className={refreshing ? 'qs-spin opacity-60' : ''} />
      <button type="button" onClick={onAccount} aria-label="Open your account" className="qs-press ml-1 rounded-full">
        <InitialsAvatar name={name || 'Learner'} size={44} />
      </button>
    </header>
  )
}
