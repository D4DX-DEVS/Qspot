import { starField } from '../../art/starField'

// A few bright stars twinkling over a night picture, inside [area] of their
// positioned parent (fractions, like the painters).
export default function TwinkleStars({ count = 10, area, seed }) {
  return (
    <div aria-hidden="true" className="pointer-events-none absolute inset-0">
      {starField(count, area, seed).map((star) => (
        <span
          key={`${star.x}-${star.y}`}
          className="qs-twinkle absolute rounded-full bg-[#fff3d6] shadow-[0_0_6px_#fff3d6]"
          style={{
            left: `${star.x * 100}%`,
            top: `${star.y * 100}%`,
            width: star.size,
            height: star.size,
            '--qs-delay': `${star.delay}ms`,
            '--qs-twinkle-time': `${star.time}s`,
          }}
        />
      ))}
    </div>
  )
}
