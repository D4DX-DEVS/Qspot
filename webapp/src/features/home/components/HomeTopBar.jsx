import { LogOut } from 'lucide-react'
import AppLogo from '../../../components/common/AppLogo'
import IconButton from '../../../components/common/IconButton'

// Logo on the left and Log Out on the right, at the screen's edges on wide
// screens too. Sits on the sky, so it has no fill of its own.
export default function HomeTopBar({ onLogout }) {
  return (
    <header className="relative flex w-full items-center gap-1 px-4 pb-2 pt-[calc(12px+env(safe-area-inset-top))] sm:px-6 lg:px-8">
      <div className="min-w-0 flex-1">
        <AppLogo width={124} />
      </div>
      <IconButton icon={LogOut} label="Log out" onClick={onLogout} />
    </header>
  )
}
