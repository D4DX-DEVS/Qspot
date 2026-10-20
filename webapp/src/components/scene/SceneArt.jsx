import AuthArt from '../../features/auth/components/AuthArt'
import { NIGHT_PALETTE } from '../../theme/scenePalette'

// A night painting filling its positioned parent, the same in light and dark
// mode. [paint] is (ctx, width, height, palette); define it outside the
// component so it keeps its identity between renders.
export default function SceneArt({ paint, className }) {
  return <AuthArt paint={paint} palette={NIGHT_PALETTE} className={className} />
}
