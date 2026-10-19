// Rounded burgundy hero surface with the palette's hero gradient.
export default function GradientCard({ className = '', children }) {
  return (
    <div className={`overflow-hidden rounded-[22px] shadow-[0_10px_22px_var(--qs-hero-shadow)] ${className}`} style={{ background: 'var(--qs-hero)' }}>
      {children}
    </div>
  )
}
