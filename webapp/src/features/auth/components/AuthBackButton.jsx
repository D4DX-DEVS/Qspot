import { ArrowLeft } from 'lucide-react'

// Round, softly tinted back arrow.
export default function AuthBackButton({ onClick }) {
  return (
    <button type="button" onClick={onClick} aria-label="Back" title="Back" className="qs-press grid size-12 place-items-center rounded-full bg-soft-fill text-ink">
      <ArrowLeft size={22} aria-hidden="true" />
    </button>
  )
}
