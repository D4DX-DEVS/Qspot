import { ChevronDown } from 'lucide-react'
import { flagOf } from '../models/phoneCountry'

// Flag + chevron + country code + divider before a phone number. Always visible, so an
// empty field still reads as a phone input; clicking it picks another country.
export default function CountryCodePrefix({ country, onClick, leftPadding = 18 }) {
  return (
    <button
      type="button"
      onClick={onClick}
      aria-label={`Country code +${country.dial} (${country.name}). Change country`}
      className="flex h-14 shrink-0 items-center rounded-xl pr-3 outline-none hover:opacity-80 focus-visible:bg-soft-fill"
      style={{ paddingLeft: leftPadding }}
    >
      <span className="text-lg leading-none" aria-hidden="true">
        {flagOf(country)}
      </span>
      <ChevronDown size={16} className="ml-1 text-muted" aria-hidden="true" />
      <span className="ml-2 text-base font-medium text-muted">+{country.dial}</span>
      <span className="ml-3 h-[22px] w-px bg-line" aria-hidden="true" />
    </button>
  )
}
