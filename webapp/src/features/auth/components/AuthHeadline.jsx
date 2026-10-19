// Bold headline with one highlighted word ([accent]) and an optional muted
// subtitle. "\n" in the text breaks the line, as in the app.
export default function AuthHeadline({ title, accent = '', trailing = '', subtitle, center = false, fontSize = 28, subtitleFontSize = 15 }) {
  const align = center ? 'text-center' : 'text-left'
  return (
    <div className={align}>
      <h1 className="whitespace-pre-line font-bold leading-[1.22] text-ink" style={{ fontSize }}>
        {title}
        <span className="text-brand">{accent}</span>
        {trailing}
      </h1>
      {subtitle ? (
        <p className="mt-3 leading-normal text-muted" style={{ fontSize: subtitleFontSize }}>
          {subtitle}
        </p>
      ) : null}
    </div>
  )
}
