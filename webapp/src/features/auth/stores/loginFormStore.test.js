import { describe, expect, it } from 'vitest'
import { LoginFormStore } from './loginFormStore'

describe('LoginFormStore', () => {
  it('is incomplete without a class, even with a full phone number', () => {
    const form = new LoginFormStore()
    form.setPhone('8888888888')
    expect(form.isComplete).toBe(false)
    expect(form.validate()).toBe(false)
    expect(form.classError).toBe('Please choose your class')
  })

  it('is incomplete without a full phone number, even with a class', () => {
    const form = new LoginFormStore()
    form.setPhone('88888')
    form.setClassNumber('9')
    expect(form.isComplete).toBe(false)
    expect(form.validate()).toBe(false)
    expect(form.phoneError).toBe('Please enter a valid 10-digit phone number')
  })

  it('is complete and valid with a 10-digit phone and a class', () => {
    const form = new LoginFormStore()
    form.setPhone('8888888888')
    form.setClassNumber('9')
    expect(form.isComplete).toBe(true)
    expect(form.validate()).toBe(true)
    expect(form.classError).toBeNull()
  })

  it('treats an emptied class choice as no class', () => {
    const form = new LoginFormStore()
    form.setClassNumber('9')
    form.setClassNumber('')
    expect(form.classNumber).toBeNull()
  })
})
