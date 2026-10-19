import { useIsDark } from '../../lib/colorScheme'

// The full QSPOT logo: colour in light mode, white in dark mode (AppLogo in
// the app).
export default function AppLogo({ width = 120 }) {
  const isDark = useIsDark()
  return (
    <img
      src={isDark ? '/qspot-logo-white.png' : '/qspot-logo.png'}
      alt="QSPOT"
      width={width}
      height={Math.round(width * 0.252)}
      className="block h-auto select-none"
      style={{ width }}
      draggable="false"
    />
  )
}
