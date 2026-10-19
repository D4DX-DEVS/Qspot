import { Check } from 'lucide-react'

// Tick box with a label (CheckboxListTile, leading box in the brand colour).
export default function CheckboxRow({ checked, onChange, title, subtitle, trailing }) {
  return (
    <label className="qs-press flex min-h-14 cursor-pointer items-center gap-3 px-2.5 py-2 [--qs-press:0.98]">
      <input type="checkbox" className="peer sr-only" checked={checked} onChange={(e) => onChange(e.target.checked)} />
      <span
        aria-hidden="true"
        className={`grid size-[18px] shrink-0 place-items-center rounded-[5px] border-[1.6px] border-brand peer-focus-visible:outline-2 peer-focus-visible:outline-brand ${checked ? 'bg-brand text-white' : ''}`}
      >
        {checked ? <Check size={14} strokeWidth={3} /> : null}
      </span>
      <span className="min-w-0 flex-1">
        <span className="block text-sm leading-[1.4] text-ink">{title}</span>
        {subtitle ? <span className="block text-[13px] text-muted">{subtitle}</span> : null}
      </span>
      {trailing}
    </label>
  )
}
