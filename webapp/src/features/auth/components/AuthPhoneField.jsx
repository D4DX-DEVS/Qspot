import { pickCountry } from '../actions/authActions'
import AuthTextField from './AuthTextField'
import CountryCodePrefix from './CountryCodePrefix'

// Mobile number field with the country's flag and calling code always
// visible; clicking them picks another country. The number may have only as
// many digits as a mobile number there (India 10, UAE 9…).
// The label stays short so it is not cut off on 320px-wide phones.
export default function AuthPhoneField({ value, onChange, country, onCountryChange, error, label = 'Phone Number' }) {
  const chooseCountry = async () => {
    const picked = await pickCountry(country)
    if (picked) onCountryChange(picked)
  }
  return (
    <AuthTextField
      label={label}
      value={value}
      onChange={onChange}
      error={error}
      prefix={<CountryCodePrefix country={country} onClick={chooseCountry} />}
      type="tel"
      inputMode="numeric"
      autoComplete="tel-national"
    />
  )
}
