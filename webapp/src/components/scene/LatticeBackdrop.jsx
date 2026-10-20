import { useId } from 'react'

const GLOWS = {
  none: [],
  right: ['right'],
  left: ['left'],
  both: ['left', 'right'],
}

// The patterned wall behind the night screens: an eight-point star lattice
// in the theme's faint lattice colour, with warm light glowing through the
// [glow] edges. Fills its positioned parent; [tile] is the pattern size.
export default function LatticeBackdrop({ tile = 64, glow = 'none' }) {
  const id = `lattice${useId().replace(/[^a-zA-Z0-9_-]/g, '')}`
  const c = tile / 2
  const a = tile * 0.25
  const tip = a * Math.SQRT2
  return (
    <div aria-hidden="true" className="pointer-events-none absolute inset-0 overflow-hidden">
      <svg className="absolute inset-0 size-full text-lattice">
        <defs>
          <pattern id={id} width={tile} height={tile} patternUnits="userSpaceOnUse">
            <g fill="none" stroke="currentColor" strokeWidth="1">
              <rect x={c - a} y={c - a} width={a * 2} height={a * 2} />
              <rect x={c - a} y={c - a} width={a * 2} height={a * 2} transform={`rotate(45 ${c} ${c})`} />
              <circle cx={c} cy={c} r={a * 0.38} />
              <path
                d={`M${c} 0V${c - tip}M${tile} ${c}H${c + tip}M${c} ${tile}V${c + tip}M0 ${c}H${c - tip}M0 0L${c - a} ${c - a}M${tile} 0L${c + a} ${c - a}M${tile} ${tile}L${c + a} ${c + a}M0 ${tile}L${c - a} ${c + a}`}
              />
            </g>
          </pattern>
        </defs>
        <rect width="100%" height="100%" fill={`url(#${id})`} />
      </svg>
      {GLOWS[glow].map((side) => (
        <div
          key={side}
          className={`absolute inset-y-0 w-[28%] ${side === 'right' ? 'right-0' : 'left-0'}`}
          style={{ background: `radial-gradient(ellipse at ${side} center, var(--qs-wall-glow), transparent 70%)` }}
        />
      ))}
    </div>
  )
}
