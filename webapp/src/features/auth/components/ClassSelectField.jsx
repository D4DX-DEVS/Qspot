import { ChevronDown, GraduationCap } from 'lucide-react'
import AuthFieldFrame from './AuthFieldFrame'

const CLASSES = ['8', '9', '10', '11', '12']

// Class picker, 8 to 12. Values are the bare numbers the API expects, shown
// as "Class N".
export default function ClassSelectField({ value, onChange, error, label = 'Which Class Are You In?' }) {
  return (
    <AuthFieldFrame error={error} prefix={<GraduationCap size={22} className="ml-[13px] mr-3 shrink-0 text-field-icon" aria-hidden="true" />}>
      <select
        aria-label={label}
        value={value ?? ''}
        onChange={(e) => onChange(e.target.value)}
        className={`h-14 min-w-0 flex-1 cursor-pointer appearance-none bg-transparent pr-12 outline-none ${value ? 'text-base text-ink' : 'text-[15px] text-muted'}`}
      >
        <option value="" disabled>
          {label}
        </option>
        {CLASSES.map((c) => (
          <option key={c} value={c}>
            Class {c}
          </option>
        ))}
      </select>
      <ChevronDown size={22} className="pointer-events-none absolute right-4 text-ink" aria-hidden="true" />
    </AuthFieldFrame>
  )
}
