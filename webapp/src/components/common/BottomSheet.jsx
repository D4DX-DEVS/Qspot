// Bottom sheet frame: glass with a warm rim, rounded top, drag handle;
// phone-width on big screens.
export default function BottomSheet({ label, children }) {
  return (
    <div role="dialog" aria-modal="true" aria-label={label} className="qs-sheet max-h-[90dvh] w-full max-w-[560px] overflow-y-auto rounded-t-[28px] border border-b-0 border-card-rim bg-glass-strong pb-[env(safe-area-inset-bottom)] shadow-[0_0_44px_var(--qs-glass-glow)] backdrop-blur-md">
      <div className="flex justify-center pt-3">
        <span className="h-1 w-8 rounded-full bg-line" aria-hidden="true" />
      </div>
      {children}
    </div>
  )
}
