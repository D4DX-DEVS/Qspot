// Section title with an optional emoji that pops in, e.g. "⚡ Live Now", or
// a coloured [icon], an optional intro line (SectionHeader in the app) and
// an optional [action] on the right, such as "View All".
export default function SectionHeader({ title, emoji, icon: Icon, iconClass = 'text-amber', subtitle, action }) {
  return (
    <div>
      <div className="flex items-center gap-3">
        <h2 className="flex min-h-10 min-w-0 flex-1 items-center gap-2 text-lg font-bold text-ink sm:text-2xl">
          {emoji ? (
            <span aria-hidden="true" className="qs-sparkle text-xl">
              {emoji}
            </span>
          ) : null}
          {Icon ? <Icon size={24} aria-hidden="true" className={`qs-sparkle shrink-0 ${iconClass}`} /> : null}
          {title}
        </h2>
        {action}
      </div>
      {subtitle ? <p className="text-[13px] leading-[1.45] text-muted">{subtitle}</p> : null}
    </div>
  )
}
