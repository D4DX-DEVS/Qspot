// The QSPOT mark with the name and "Your Quran Quiz Spot", side by side or,
// when [stacked], one above the other. [onArt] keeps the words white over the
// night pictures; otherwise they follow the theme. The mark image carries
// ~20% clear margin, so [mark] is its box, not the visible mark.
export default function BrandLockup({ mark = 48, stacked = false, onArt = false, className = '' }) {
  const ink = onArt ? 'text-white' : 'text-ink'
  const sub = onArt ? 'text-white/80' : 'text-muted'
  return (
    <div role="img" aria-label="QSPOT, Your Quran Quiz Spot" className={`flex items-center ${stacked ? 'flex-col text-center' : 'gap-1'} ${className}`}>
      <img
        src="/qspot-mark.png"
        alt=""
        width={mark}
        height={mark}
        draggable="false"
        className="shrink-0 select-none object-contain"
        style={{ width: mark, height: mark, margin: stacked ? `0 0 -${mark * 0.12}px` : `0 -${mark * 0.08}px 0 -${mark * 0.14}px` }}
      />
      <div aria-hidden="true" className="min-w-0">
        <p className={`font-extrabold leading-none tracking-[0.04em] ${ink}`} style={{ fontSize: Math.round(mark * (stacked ? 0.4 : 0.48)) }}>
          QSPOT
        </p>
        <p className={`mt-1 whitespace-nowrap leading-none ${sub}`} style={{ fontSize: Math.max(10, Math.round(mark * (stacked ? 0.13 : 0.2))) }}>
          Your Quran Quiz Spot
        </p>
      </div>
    </div>
  )
}
