// Bottom sheet frame: card colour, rounded top, drag handle; phone-width on
// big screens.
export default function BottomSheet({ label, children }) {
  return (
    <div role="dialog" aria-modal="true" aria-label={label} className="qs-sheet max-h-[90dvh] w-full max-w-[560px] overflow-y-auto rounded-t-[28px] bg-card pb-[env(safe-area-inset-bottom)] shadow-2xl">
      <div className="flex justify-center pt-3">
        <span className="h-1 w-8 rounded-full bg-line" aria-hidden="true" />
      </div>
      {children}
    </div>
  )
}
