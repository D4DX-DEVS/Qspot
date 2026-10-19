import { ChevronRight } from 'lucide-react'

// Centred "prompt + action" line, e.g. "Don't Have an Account? Register Now".
export default function AuthLinkRow({ prompt, action, onClick }) {
  return (
    <div className="flex flex-wrap items-center justify-center">
      <span className="text-sm text-muted">{prompt}</span>
      <button type="button" onClick={onClick} className="qs-press flex min-h-12 items-center px-1.5 text-sm font-semibold text-brand">
        {action}
        <ChevronRight size={20} aria-hidden="true" />
      </button>
    </div>
  )
}
