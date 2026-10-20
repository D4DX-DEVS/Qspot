const DOTS = {
  live: 'bg-[#4ade80]',
  hot: 'bg-[#fb5a7a]',
  upcoming: 'bg-[#fbbf5a]',
  done: 'bg-[#f0609c]',
  ended: 'bg-[#a3aec2]',
}

// Small pill over a night picture or the hero card: a coloured dot and a
// label ("Live", "LIVE NOW"). Light text on dark glass in both themes.
// [pulse] sends a ring out from the dot, for something happening now. [compact] makes
// it smaller on phones (small pictures).
export default function ArtBadge({ label, dot = 'live', pulse = false, compact = false, className = '' }) {
  const size = compact ? 'gap-1.5 px-2 py-0.5 text-[10.5px] sm:gap-2 sm:px-3 sm:py-1 sm:text-[13px]' : 'gap-2 px-3 py-1 text-[13px]'
  return (
    <span className={`inline-flex items-center whitespace-nowrap rounded-full border border-white/15 bg-black/45 font-semibold text-white backdrop-blur-sm ${size} ${className}`}>
      <span aria-hidden="true" className={`relative rounded-full ${compact ? 'size-1.5 sm:size-2' : 'size-2'} ${DOTS[dot]}`}>
        {pulse ? <span className={`absolute inset-0 rounded-full opacity-75 motion-safe:animate-ping ${DOTS[dot]}`} /> : null}
      </span>
      {label}
    </span>
  )
}
