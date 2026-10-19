import { firstName } from '../../../utils/firstName'

// "Hey Name 👋" and a short learning prompt (TodayGreeting in the app).
export default function HomeGreeting({ name }) {
  const first = firstName(name)
  return (
    <div className="px-2 pb-3.5">
      <h1 className="text-lg font-extrabold text-ink md:text-2xl">
        Hey {first || 'There'} <span aria-hidden="true">👋</span>
      </h1>
      <p className="mt-0.5 text-xs text-muted md:text-sm">Continue your Quran learning journey today.</p>
    </div>
  )
}
