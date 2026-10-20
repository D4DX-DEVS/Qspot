import { Search } from 'lucide-react'
import BottomSheet from '../../../components/common/BottomSheet'
import { useLocalNotifier } from '../../../lib/useNotifier'
import { CountryPickerStore } from '../stores/countryPickerStore'
import AuthTextField from './AuthTextField'
import CountryOption from './CountryOption'

// Bottom sheet listing every country, with a search box, so a learner can
// pick where their phone number is from
// (mobile-app/lib/screens/auth/widgets/country_picker_sheet.dart).
export default function CountryPickerSheet({ selected, onClose }) {
  const picker = useLocalNotifier(() => new CountryPickerStore())
  const results = picker.results
  return (
    <BottomSheet label="Choose your country">
      <div className="px-5 pb-2 pt-4">
        <h2 className="mb-3 text-lg font-bold text-ink">Choose your country</h2>
        <AuthTextField label="Search country or code" icon={Search} type="search" value={picker.query} onChange={(v) => picker.setQuery(v)} />
      </div>
      {results.length === 0 ? (
        <p className="px-6 py-6 text-center text-[14.5px] text-muted">No country matches your search.</p>
      ) : (
        <ul className="max-h-[60dvh] overflow-y-auto pb-3">
          {results.map((country) => (
            <CountryOption key={country.iso} country={country} selected={country.iso === selected.iso} onPick={() => onClose(country)} />
          ))}
        </ul>
      )}
    </BottomSheet>
  )
}
