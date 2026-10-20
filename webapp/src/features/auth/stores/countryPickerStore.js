import { ChangeNotifier } from '../../../lib/ChangeNotifier'
import { findCountries } from '../models/phoneCountry'

// Search state for the country picker
// (mobile-app/lib/screens/auth/provider/country_picker_provider.dart).
export class CountryPickerStore extends ChangeNotifier {
  query = ''

  get results() {
    return findCountries(this.query)
  }

  setQuery(value) {
    this.query = value
    this.notifyListeners()
  }
}
