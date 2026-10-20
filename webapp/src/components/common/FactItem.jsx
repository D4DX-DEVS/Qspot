// One small fact with its icon, e.g. a clock and "5 min". [onArt] keeps it
// light over the night pictures.
export default function FactItem({ icon: Icon, label, onArt = false }) {
  return (
    <span className={`inline-flex items-center gap-1.5 text-[13px] sm:gap-2 sm:text-[15px] ${onArt ? 'text-white/85' : 'text-muted'}`}>
      <Icon aria-hidden="true" className="size-4 shrink-0 sm:size-[18px]" />
      {label}
    </span>
  )
}
