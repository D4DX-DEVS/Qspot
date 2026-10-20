import { ArrowRight } from 'lucide-react'
import Spinner from '../../../components/common/Spinner'

// Full-width burgundy-to-coral pill with a centred label and a white arrow
// badge on the right; faded until [enabled]. It shines on hover and the
// arrow nudges forward.
export default function GradientPillButton({ label, onClick, enabled, loading = false, type = 'button' }) {
  const active = enabled && !loading
  return (
    <div className="rounded-full bg-bg">
      <button
        type={type}
        onClick={onClick}
        disabled={!active}
        aria-label={label}
        className={`group qs-press qs-shine relative flex h-[58px] w-full items-center justify-center rounded-[32px] text-white shadow-[0_6px_16px_rgb(116_12_59/0.25)] transition-opacity duration-200 ${
          !enabled && !loading ? 'opacity-50' : ''
        }`}
        style={{ backgroundImage: 'linear-gradient(to right, #87174a, #b02c50, #e46c5c)' }}
      >
        {loading ? <Spinner size={22} /> : <span className="truncate px-14 text-[17px] font-semibold">{label}</span>}
        <span
          className="absolute right-2 grid size-[42px] place-items-center rounded-full bg-white text-[#740c3b] transition-transform duration-200 motion-safe:group-hover:translate-x-0.5"
          aria-hidden="true"
        >
          <ArrowRight size={22} />
        </span>
      </button>
    </div>
  )
}
