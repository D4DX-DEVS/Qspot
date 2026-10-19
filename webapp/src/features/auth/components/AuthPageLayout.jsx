// Frame for the sign-in screens: page colour, optional fixed top artwork, and
// a phone-width column with artwork at its foot. The bottom art sits at the
// screen bottom when the content is short and below it when long, so it
// never covers a field; [overlap] (0..1 of the art height) lets the content
// run into the empty sky at its top.
export default function AuthPageLayout({ topArt, topArtHeight = 0, bottomArt, artHeight = '0px', overlap = 0, center = false, children }) {
  return (
    <div className="relative min-h-dvh overflow-x-hidden bg-bg" style={{ '--qs-art': artHeight }}>
      {topArt ? (
        <div className="absolute inset-x-0 top-0" style={{ height: topArtHeight }}>
          {topArt}
        </div>
      ) : null}
      <div className={`relative flex min-h-dvh flex-col ${center ? 'justify-center' : ''}`}>
        {bottomArt ? <div className="absolute inset-x-0 bottom-0 h-[var(--qs-art)]">{bottomArt}</div> : null}
        <main
          className="relative mx-auto flex w-full max-w-[468px] flex-col px-6 pt-[calc(12px+env(safe-area-inset-top))]"
          style={{ paddingBottom: `calc(24px + var(--qs-art) * ${1 - overlap})` }}
        >
          {children}
        </main>
      </div>
    </div>
  )
}
