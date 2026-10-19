import AuthArt from './AuthArt'
import { paintHangingLantern } from '../art/hangingLantern'
import { paintMihrabArch } from '../art/mihrabArch'

// Header framed by a pointed arch with a hanging lantern, with an optional
// [leading] control (such as a back button) top-left.
export default function ArchHeader({ leading, children }) {
  return (
    <div className="relative">
      <div className="absolute -inset-x-3 inset-y-0">
        <AuthArt paint={paintMihrabArch} />
      </div>
      <div className="absolute right-2 top-0 h-[110px] w-[30px]">
        <AuthArt paint={paintHangingLantern} />
      </div>
      <div className="relative pb-7 pt-10">{children}</div>
      {leading ? <div className="absolute left-0 top-0">{leading}</div> : null}
    </div>
  )
}
