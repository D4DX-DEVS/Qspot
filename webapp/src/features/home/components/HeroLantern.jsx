import { paintHangingLantern } from '../../auth/art/hangingLantern'
import AuthArt from '../../auth/components/AuthArt'

// The splash screen's warm lantern colours: it hangs on the burgundy card in
// light and dark mode alike.
const LANTERN = { lanternFrame: '#E7B07A', lanternGlow: '#FFD08A' }

// A small glowing lantern hung from the top-right of the hero card.
export default function HeroLantern() {
  return (
    <div aria-hidden="true" className="pointer-events-none absolute right-5 top-0 h-[110px] w-[30px]">
      <AuthArt paint={paintHangingLantern} palette={LANTERN} />
    </div>
  )
}
