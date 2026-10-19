import { LogOut } from 'lucide-react'
import BottomSheet from '../../../components/common/BottomSheet'
import InitialsAvatar from '../../../components/common/InitialsAvatar'
import SoftOutlineButton from '../../../components/common/SoftOutlineButton'

// The signed-in student's name, class and number, with Log Out.
export default function AccountSheet({ user, onLogout }) {
  const facts = [user?.classNumber ? `Class ${user.classNumber}` : null, user?.phone ? `+91 ${user.phone}` : null].filter(Boolean)
  return (
    <BottomSheet label="Your account">
      <div className="flex flex-col items-center px-6 pb-6 pt-6 text-center">
        <InitialsAvatar name={user?.name || 'Learner'} size={72} />
        <h2 className="mt-4 text-[19px] font-bold text-ink">{user?.name || 'Learner'}</h2>
        {facts.length ? <p className="mt-1 text-sm text-muted">{facts.join(' · ')}</p> : null}
        <div className="mt-6 w-full [&>button]:w-full">
          <SoftOutlineButton icon={LogOut} label="Log Out" onClick={onLogout} />
        </div>
      </div>
    </BottomSheet>
  )
}
