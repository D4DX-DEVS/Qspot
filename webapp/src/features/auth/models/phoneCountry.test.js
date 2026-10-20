import { describe, expect, it } from 'vitest'
import { cleanNumber, findCountries, flagOf, INDIA, lengthLabel, phoneCountries, phoneForApi } from './phoneCountry'

const country = (iso) => phoneCountries.find((c) => c.iso === iso)

describe('phoneCountry', () => {
  it('India is the default, with 10 digits and the 🇮🇳 flag', () => {
    expect(INDIA.dial).toBe('91')
    expect(INDIA.lengths).toEqual([10])
    expect(flagOf(INDIA)).toBe('🇮🇳')
  })

  it('each country has its own number of digits', () => {
    expect(country('AE').lengths).toEqual([9])
    expect(country('US').lengths).toEqual([10])
    expect(lengthLabel(country('DE'))).toBe('10 or 11')
    expect(lengthLabel(country('AT'))).toBe('7 to 13')
  })

  it('drops a leading 0 only where it is not part of the number', () => {
    expect(cleanNumber(country('GB'), '07400 123456')).toBe('7400123456')
    expect(cleanNumber(country('CI'), '0712345678')).toBe('0712345678')
    expect(cleanNumber(country('AE'), '9876543210')).toBe('987654321')
  })

  it('sends an Indian number as before and others with +code', () => {
    expect(phoneForApi(INDIA, '8888888888')).toBe('8888888888')
    expect(phoneForApi(country('AE'), '501234567')).toBe('+971501234567')
  })

  it('finds a country by name, code or calling code', () => {
    expect(findCountries('').length).toBe(phoneCountries.length)
    expect(findCountries('emirates').map((c) => c.iso)).toEqual(['AE'])
    expect(findCountries('+971').map((c) => c.iso)).toEqual(['AE'])
    expect(findCountries('gb').map((c) => c.iso)).toContain('GB')
    expect(findCountries('zzz')).toEqual([])
  })
})
