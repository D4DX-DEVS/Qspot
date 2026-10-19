// Section title, e.g. "Live Now".
export default function SectionHeader({ title, subtitle }) {
  return (
    <div>
      <h2 className="flex min-h-10 items-center text-lg font-bold text-ink">{title}</h2>
      {subtitle ? <p className="text-[13px] leading-[1.45] text-muted">{subtitle}</p> : null}
    </div>
  )
}
