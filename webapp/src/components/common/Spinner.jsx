// Small circular progress ring in the current text colour.
export default function Spinner({ size = 22, stroke = 2, className = '' }) {
  return (
    <span
      role="progressbar"
      aria-label="Loading"
      className={`qs-spin inline-block rounded-full border-current border-r-transparent ${className}`}
      style={{ width: size, height: size, borderWidth: stroke }}
    />
  )
}
