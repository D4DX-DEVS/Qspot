// Shimmering placeholder block.
export default function LoadingSkeleton({ className = 'h-16 w-full', radius = 12 }) {
  return <div aria-hidden="true" className={`qs-skeleton ${className}`} style={{ borderRadius: radius }} />
}
