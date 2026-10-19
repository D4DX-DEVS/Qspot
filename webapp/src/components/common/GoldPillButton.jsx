import { ArrowRight } from 'lucide-react'

// Compact gold pill (icon, label, arrow) for the main action on a burgundy
// card. The deep burgundy ink stays readable in light and dark mode.
// [breathe] makes it pulse gently to invite a tap.
export default function GoldPillButton({ label, icon: Icon, onClick, breathe = false }) {
  return (
    <span className={`inline-block ${breathe ? 'qs-breathe' : ''}`}>
      <button
        type="button"
        onClick={onClick}
        className="qs-press inline-flex min-h-11 items-center gap-2 rounded-[26px] px-4 text-sm font-semibold text-[#6a0f35] shadow-[0_5px_12px_rgb(0_0_0/0.18)]"
        style={{ backgroundImage: 'linear-gradient(to right, #fbd495, #f3ac66)' }}
      >
        {Icon ? <Icon size={18} aria-hidden="true" /> : null}
        <span>{label}</span>
        <ArrowRight size={17} aria-hidden="true" />
      </button>
    </span>
  )
}
