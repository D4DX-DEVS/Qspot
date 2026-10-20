import { UserRound } from 'lucide-react'
import { firstName } from '../../../utils/firstName'

// The signed-in student: a round avatar with an online dot and their first
// name (the name hides on very narrow screens).
export default function UserChip({ name }) {
  const first = firstName(name)
  return (
    <div className="flex min-w-0 items-center gap-2.5 px-1" aria-label={first ? `Signed in as ${first}` : 'Signed in'}>
      <span className="relative grid size-10 shrink-0 place-items-center rounded-full bg-slate-soft text-slate" aria-hidden="true">
        <UserRound size={22} />
        <span className="absolute bottom-0 right-0 size-3 rounded-full border-2 border-bg bg-[#22c55e]" />
      </span>
      {first ? (
        <span aria-hidden="true" className="hidden max-w-[10rem] truncate text-[15px] font-semibold text-ink min-[400px]:block sm:text-base">
          {first}
        </span>
      ) : null}
    </div>
  )
}
