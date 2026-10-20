import PillButton from './PillButton'

// The two buttons of a centred dialog, side by side and equally wide: the
// quiet choice outlined, the main one in the action colours.
export default function DialogPillActions({ quiet, main, mainIcon, onQuiet, onMain }) {
  return (
    <div className="flex w-full gap-3">
      <PillButton look="outline" size="lg" label={quiet} onClick={onQuiet} className="flex-1" />
      <PillButton size="lg" label={main} trailing={mainIcon} onClick={onMain} className="flex-1" />
    </div>
  )
}
