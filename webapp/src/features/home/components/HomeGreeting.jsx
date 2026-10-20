import { firstName } from '../../../utils/firstName'

// "Hey Name 👋" and a short learning prompt (TodayGreeting in the app).
export default function HomeGreeting({ name }) {
  const first = firstName(name)
  return (
    <div className="pb-5 pt-2 sm:pb-6 sm:pt-4">
      <h1 className="text-[26px] font-extrabold leading-tight text-ink sm:text-[34px] lg:text-[40px]">
        Hey {first || 'There'} <span aria-hidden="true">👋</span>
      </h1>
      <p className="mt-1 text-[15px] text-muted sm:text-lg">Continue your Quran learning journey today.</p>
    </div>
  )
}
