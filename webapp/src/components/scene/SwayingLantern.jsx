import { paintHangingLantern } from '../../features/auth/art/hangingLantern'
import SceneArt from './SceneArt'

// The lantern takes the middle third of its box's width and the top of its
// height, so its glow fits inside the box instead of being cut off.
const BOX_WIDTH = 3.2
const BOX_HEIGHT = 1.15

const paintLantern = (ctx, w, h, p) => {
  const lw = w / BOX_WIDTH
  ctx.translate((w - lw) / 2, 0)
  paintHangingLantern(ctx, lw, h / BOX_HEIGHT, p)
}

// A glowing lantern hung at [x] across its positioned parent from [top],
// [length] of the parent's height long (fractions, like the painters),
// swaying gently from its chain while its light flickers. [delay] (ms) and
// [time] (s, one full swing) keep several lanterns out of step.
export default function SwayingLantern({ x, top = 0, length, delay = 0, time = 4.8 }) {
  return (
    <div
      aria-hidden="true"
      className="pointer-events-none absolute -translate-x-1/2"
      style={{ left: `${x * 100}%`, top: `${top * 100}%`, height: `${length * BOX_HEIGHT * 100}%`, aspectRatio: (0.27 * BOX_WIDTH) / BOX_HEIGHT }}
    >
      <div className="qs-sway size-full" style={{ '--qs-delay': `${delay}ms`, '--qs-sway-time': `${time}s` }}>
        <div className="qs-flicker size-full" style={{ '--qs-delay': `${delay / 2}ms` }}>
          <SceneArt paint={paintLantern} />
        </div>
      </div>
    </div>
  )
}
