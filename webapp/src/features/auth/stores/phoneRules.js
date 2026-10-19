// Phone field rules shared by sign-in and registration
// (mobile-app/lib/screens/auth/widgets/auth_phone_field.dart): digits only,
// at most 10, India +91 shown as a prefix.
export const digitsOnly = (value) => String(value || '').replace(/\D/g, '').slice(0, 10)

export function phoneError(value) {
  const phone = String(value || '').trim()
  if (phone === '') return 'Please enter your phone number'
  if (phone.length !== 10) return 'Please enter a valid 10-digit phone number'
  return null
}
