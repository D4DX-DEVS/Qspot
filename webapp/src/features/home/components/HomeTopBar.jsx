import { LogOut } from 'lucide-react'
import BrandLockup from '../../../components/brand/BrandLockup'
import IconButton from '../../../components/common/IconButton'
import UserChip from './UserChip'

// QSPOT on the left; the student and Log Out on the right, over a hairline.
// Full width: at the screen's edges on wide screens too, while the page
// below stays in its centred column.
export default function HomeTopBar({ name, onLogout }) {
  return (
    <header className="relative border-b border-glass-line pt-[env(safe-area-inset-top)]">
      <div className="flex w-full items-center gap-2 px-4 py-2.5 sm:px-6 lg:px-10">
        <div className="min-w-0 flex-1">
          <BrandLockup mark={50} />
        </div>
        <UserChip name={name} />
        <IconButton icon={LogOut} label="Log out" onClick={onLogout} />
      </div>
    </header>
  )
}
