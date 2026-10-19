import { paintMosqueSkyline } from '../../features/auth/art/mosqueSkyline'
import AuthArt from '../../features/auth/components/AuthArt'

const skylineOnly = (ctx, w, h, palette) => paintMosqueSkyline(ctx, w, h, palette, { showBookStand: false, showMoon: false })

// Warm sky fading into the page with a faint mosque skyline, behind the home
// greeting (TodaySkyBackdrop in the app). Fills its positioned parent.
export default function SkyBackdrop() {
  return (
    <div aria-hidden="true" className="absolute inset-0" style={{ background: 'linear-gradient(to bottom, var(--qs-sky-top) 15%, var(--qs-bg) 95%)' }}>
      <div className="absolute inset-0" style={{ opacity: 'var(--qs-skyline-opacity)' }}>
        <AuthArt paint={skylineOnly} />
      </div>
    </div>
  )
}
