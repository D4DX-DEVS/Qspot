import { Sparkles } from 'lucide-react'

// A large and a small gold sparkle after a hero title; pops in once.
export default function SparkleAccent({ size = 24 }) {
  return (
    <span aria-hidden="true" className="qs-sparkle inline-flex shrink-0 items-start text-[#fbd495]">
      <Sparkles size={size} />
      <Sparkles size={size * 0.55} className="opacity-70" style={{ marginTop: size * 0.1 }} />
    </span>
  )
}
