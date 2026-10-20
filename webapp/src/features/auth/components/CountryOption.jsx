import { Check } from 'lucide-react'
import { flagOf } from '../models/phoneCountry'

// One row of the country picker: flag, name and calling code, with a tick on
// the country already chosen.
export default function CountryOption({ country, selected, onPick }) {
  return (
    <li>
      <button
        type="button"
        onClick={onPick}
        aria-current={selected ? 'true' : undefined}
        className={`flex w-full items-center gap-3 px-5 py-3 text-left outline-none hover:bg-soft-fill focus-visible:bg-soft-fill ${selected ? 'bg-brand-soft' : ''}`}
      >
        <span className="text-2xl leading-none" aria-hidden="true">
          {flagOf(country)}
        </span>
        <span className="min-w-0 flex-1 truncate text-[15.5px] font-medium text-ink">{country.name}</span>
        <span className="shrink-0 text-[15px] text-muted">+{country.dial}</span>
        {selected ? <Check size={20} className="shrink-0 text-brand" aria-hidden="true" /> : null}
      </button>
    </li>
  )
}
