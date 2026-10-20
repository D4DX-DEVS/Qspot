import { acceptsLength, lengthLabel } from '../models/phoneCountry'

// Phone field rules shared by sign-in and registration
// (mobile-app/lib/screens/auth/widgets/auth_phone_field.dart): the number
// needs as many digits as a mobile number in its country has (India 10,
// UAE 9…).
export function phoneError(value, country) {
  const phone = String(value || '').trim()
  if (phone === '') return 'Please enter your phone number'
  if (!acceptsLength(country, phone.length)) return `Please enter a valid ${lengthLabel(country)}-digit phone number`
  return null
}
