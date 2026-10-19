import { tone as toneOf } from '../../theme/tones'

// Icon on a soft tinted square (or circle) in an accent tone.
export default function SoftIconTile({ icon: Icon, tone, size = 44, circle = false }) {
  const t = toneOf(tone)
  return (
    <span
      aria-hidden="true"
      className={`grid shrink-0 place-items-center ${t.soft} ${t.text}`}
      style={{ width: size, height: size, borderRadius: circle ? '50%' : size * 0.3 }}
    >
      <Icon size={size * 0.5} />
    </span>
  )
}
