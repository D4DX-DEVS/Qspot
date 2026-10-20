import Spinner from './Spinner'

const LOOKS = {
  cta: { className: 'qs-shine text-white', style: { backgroundImage: 'var(--qs-cta)', boxShadow: '0 8px 20px var(--qs-cta-shadow)' } },
  go: { className: 'qs-shine text-white', style: { backgroundImage: 'var(--qs-go)', boxShadow: '0 8px 20px var(--qs-go-shadow)' } },
  outline: { className: 'border-[1.5px] border-field-line text-ink hover:bg-soft-fill', style: undefined },
}

const SIZES = {
  md: 'min-h-11 gap-2 px-5 text-sm',
  lg: 'min-h-[52px] gap-2.5 px-6 text-base',
}

// Rounded action: 'cta' pink-to-coral for the main step, 'go' green to start
// a quiz, 'outline' for the quiet choice. Optional [icon] before (solid with
// [fillIcon], e.g. a play triangle) and [trailing] icon after the label.
// With [as]="span" it is only drawn, inside a card that handles the tap.
// Coloured looks shine on hover and the trailing arrow nudges forward (also
// when the card around it is hovered).
export default function PillButton({ label, icon: Icon, fillIcon = false, trailing: Trailing, look = 'cta', size = 'md', full = false, as = 'button', type = 'button', onClick, disabled = false, loading = false, className = '' }) {
  const { className: lookClass, style } = LOOKS[look]
  const classes = `group/pill inline-flex shrink-0 items-center justify-center rounded-full font-semibold ${SIZES[size]} ${lookClass} ${full ? 'w-full' : ''} ${className}`
  const body = (
    <>
      {loading ? <Spinner size={18} /> : Icon ? <Icon size={size === 'lg' ? 20 : 18} aria-hidden="true" className={`shrink-0 ${fillIcon ? 'fill-current' : ''}`} /> : null}
      <span className="truncate">{label}</span>
      {Trailing ? (
        <Trailing
          size={size === 'lg' ? 20 : 18}
          aria-hidden="true"
          className="shrink-0 transition-transform duration-200 motion-safe:group-hover:translate-x-1 motion-safe:group-hover/pill:translate-x-1"
        />
      ) : null}
    </>
  )
  if (as === 'span') {
    return (
      <span className={classes} style={style}>
        {body}
      </span>
    )
  }
  return (
    <button type={type} onClick={onClick} disabled={disabled || loading} className={`qs-press disabled:opacity-60 ${classes}`} style={style}>
      {body}
    </button>
  )
}
