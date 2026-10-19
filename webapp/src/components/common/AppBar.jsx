import { ArrowLeft } from 'lucide-react'
import IconButton from './IconButton'

// Top bar (CommonAppBar in the app): page colour with a soft shadow, a bold
// title and optional back button and actions. The title wraps instead of
// being cut off. [width] matches the page column on wide screens. [flat]
// drops the stickiness and shadow, for a page that pins a taller header.
export default function AppBar({ title, onBack, leading, actions, width = 'max-w-2xl', flat = false }) {
  return (
    <header className={`bg-bg pt-[env(safe-area-inset-top)] ${flat ? '' : 'sticky top-0 z-20 shadow-[0_2px_4px_var(--qs-appbar-shadow)]'}`}>
      <div className={`mx-auto flex min-h-14 ${width} items-center gap-1 px-1 pb-2 pt-1`}>
        {leading ?? (onBack ? <IconButton label="Back" icon={ArrowLeft} onClick={onBack} /> : <span className="w-3" />)}
        <h1 className="line-clamp-2 min-w-0 flex-1 px-1 text-[21px] font-extrabold leading-tight text-ink">{title}</h1>
        {actions ? <div className="flex items-center gap-1">{actions}</div> : null}
      </div>
    </header>
  )
}
