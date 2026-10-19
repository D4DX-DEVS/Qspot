import { Phone } from 'lucide-react'
import AuthTextField from './AuthTextField'
import CountryCodePrefix from './CountryCodePrefix'

// 10-digit Indian mobile number field with the +91 prefix always visible.
export default function AuthPhoneField({ value, onChange, error, label = 'Enter Your Phone Number', showPhoneIcon = false }) {
  const prefix = (
    <span className="flex items-center">
      {showPhoneIcon ? <Phone size={22} className="ml-4 text-field-icon" aria-hidden="true" /> : null}
      <CountryCodePrefix leftPadding={showPhoneIcon ? 12 : 18} />
    </span>
  )
  return (
    <AuthTextField
      label={label}
      value={value}
      onChange={onChange}
      error={error}
      prefix={prefix}
      type="tel"
      inputMode="numeric"
      autoComplete="tel-national"
    />
  )
}
