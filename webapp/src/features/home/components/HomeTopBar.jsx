import AppLogo from '../../../components/common/AppLogo'
import InitialsAvatar from '../../../components/common/InitialsAvatar'

// Logo on the left and the student's avatar (opens their account) on the
// right, at the screen's edges on wide screens too. Sits on the sky, so it
// has no fill of its own.
export default function HomeTopBar({ name, onAccount }) {
  return (
    <header className="relative flex w-full items-center gap-1 px-4 pb-2 pt-[calc(12px+env(safe-area-inset-top))] sm:px-6 lg:px-8">
      <div className="min-w-0 flex-1">
        <AppLogo width={124} />
      </div>
      <button type="button" onClick={onAccount} aria-label="Open your account" className="qs-press ml-1 rounded-full">
        <InitialsAvatar name={name || 'Learner'} size={44} />
      </button>
    </header>
  )
}
