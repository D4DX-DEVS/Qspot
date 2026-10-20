import countries from '../data/phoneCountries.json'

// Countries a phone number can be from, with how many digits a mobile number
// has there, generated from Google's libphonenumber data by
// tools/phone-countries/generate.mjs: the same list the API and the app use
// (mobile-app/lib/screens/auth/model/phone_country.dart).
// Each is { iso: 'IN', name: 'India', dial: '91', lengths: [10], trunkZero }.
export const phoneCountries = countries

// The default: most learners are in India.
export const INDIA = countries.find((country) => country.iso === 'IN')

// The flag emoji, built from the two letters of the country code.
export const flagOf = (country) => String.fromCodePoint(...[...country.iso].map((letter) => 0x1f1e6 + letter.charCodeAt(0) - 65))

export const acceptsLength = (country, length) => country.lengths.includes(length)

const maxLength = (country) => country.lengths.at(-1)

// "10", "9 or 10", "7 to 13".
export function lengthLabel({ lengths }) {
  if (lengths.length === 1) return String(lengths[0])
  if (lengths.length === 2) return `${lengths[0]} or ${lengths[1]}`
  const last = lengths.at(-1)
  if (last - lengths[0] === lengths.length - 1) return `${lengths[0]} to ${last}`
  return `${lengths.slice(0, -1).join(', ')} or ${last}`
}

// [typed] as a number from [country]: digits only, without a leading "0" that
// is only dialled inside the country (UK 07400…), at most as many digits as a
// number there has.
export function cleanNumber(country, typed) {
  let digits = String(typed || '').replace(/\D/g, '')
  if (country.trunkZero) digits = digits.replace(/^0+/, '')
  return digits.slice(0, maxLength(country))
}

// [number] the way the API saves it: an Indian number as its 10 digits, the
// way every account was saved before other countries were allowed; any other
// as "+<calling code><number>".
export const phoneForApi = (country, number) => (country.iso === 'IN' ? number : `+${country.dial}${number}`)

// Countries matching a search by name, two-letter code or calling code.
export function findCountries(query) {
  const text = String(query || '').trim().toLowerCase()
  if (text === '') return countries
  if (/^\+?\d+$/.test(text)) {
    const digits = text.replace('+', '')
    return countries.filter((country) => country.dial.startsWith(digits))
  }
  return countries.filter((country) => country.name.toLowerCase().includes(text) || country.iso.toLowerCase() === text)
}
