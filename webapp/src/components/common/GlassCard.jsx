// See-through card over the patterned wall: blurred backdrop and a hairline
// border; [rim] swaps the border for the warm glowing one (the sign-in card).
// Becomes a button when [onClick] is set: it lifts on hover, and its parts
// can react to that hover (group-hover).
export default function GlassCard({ onClick, label, rim = false, padding = 'p-5', radius = 'rounded-[22px]', className = '', children }) {
  const edge = rim
    ? 'border-card-rim shadow-[0_0_44px_var(--qs-glass-glow),0_18px_40px_rgb(0_0_0/0.16)]'
    : 'border-glass-line shadow-[0_8px_24px_var(--qs-card-shadow)]'
  const base = `block w-full border bg-glass text-left backdrop-blur-md ${edge} ${radius} ${padding} ${className}`
  if (!onClick) return <div className={base}>{children}</div>
  return (
    <button type="button" onClick={onClick} aria-label={label} className={`group qs-press qs-lift [--qs-press:0.985] hover:border-brand/40 ${base}`}>
      {children}
    </button>
  )
}
