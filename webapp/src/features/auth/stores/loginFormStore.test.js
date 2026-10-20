import { describe, expect, it } from 'vitest'
import { phoneCountries } from '../models/phoneCountry'
import { LoginFormStore } from './loginFormStore'

describe('LoginFormStore', () => {
  it('is incomplete without a name, even with a full phone number', () => {
    const form = new LoginFormStore()
    form.setPhone('8888888888')
    form.setName('   ')
    expect(form.isComplete).toBe(false)
    expect(form.validate()).toBe(false)
    expect(form.nameError).toBe('Please enter your name')
  })

  it('is incomplete without a full phone number, even with a name', () => {
    const form = new LoginFormStore()
    form.setPhone('88888')
    form.setName('Test Student 2')
    expect(form.isComplete).toBe(false)
    expect(form.validate()).toBe(false)
    expect(form.phoneError).toBe('Please enter a valid 10-digit phone number')
  })

  it('is complete and valid with a name and a 10-digit phone', () => {
    const form = new LoginFormStore()
    form.setPhone('8888888888')
    form.setName('Test Student 2')
    expect(form.isComplete).toBe(true)
    expect(form.validate()).toBe(true)
    expect(form.nameError).toBeNull()
  })

  it('shows errors only after a submit attempt', () => {
    const form = new LoginFormStore()
    expect(form.nameError).toBeNull()
    expect(form.phoneError).toBeNull()
    form.validate()
    expect(form.nameError).toBe('Please enter your name')
    expect(form.phoneError).toBe('Please enter your phone number')
  })

  it('the chosen country decides how many digits the phone needs', () => {
    const form = new LoginFormStore()
    form.setPhone('8888888888')
    form.setName('Test Student 2')
    form.setCountry(phoneCountries.find((c) => c.iso === 'AE'))
    expect(form.phone).toBe('888888888')
    expect(form.isComplete).toBe(true)
    expect(form.phoneForApi).toBe('+971888888888')

    form.setPhone('88888')
    expect(form.validate()).toBe(false)
    expect(form.phoneError).toBe('Please enter a valid 9-digit phone number')
  })
})
