import { ChevronRight } from 'lucide-react'

// Small outlined pill beside a section title: "View All" while the list is
// cut short, "Show Less" once it is open (the arrow turns to point up).
export default function ViewAllButton({ open, onClick, controls }) {
  return (
    <button
      type="button"
      onClick={onClick}
      aria-expanded={open}
      aria-controls={controls}
      className="qs-press inline-flex min-h-10 shrink-0 items-center gap-1.5 rounded-full border border-glass-line bg-glass px-4 text-sm font-semibold text-ink hover:border-brand/40"
    >
      {open ? 'Show Less' : 'View All'}
      <ChevronRight size={18} aria-hidden="true" className={`transition-transform duration-300 ${open ? '-rotate-90' : ''}`} />
    </button>
  )
}
