// Section title with an optional emoji that pops in, e.g. "⚡ Live Now", and
// an optional intro line (SectionHeader in the app).
export default function SectionHeader({ title, emoji, subtitle }) {
  return (
    <div>
      <h2 className="flex min-h-10 items-center gap-2 text-lg font-bold text-ink">
        {emoji ? (
          <span aria-hidden="true" className="qs-sparkle text-xl">
            {emoji}
          </span>
        ) : null}
        {title}
      </h2>
      {subtitle ? <p className="text-[13px] leading-[1.45] text-muted">{subtitle}</p> : null}
    </div>
  )
}
