import { beforeEach, describe, expect, it, vi } from 'vitest'
import { dialogStore } from '../../../stores/dialogStore'
import { toastStore } from '../../../stores/toastStore'
import { fakeServer } from '../../../test/fakeServer'
import { phoneCountries } from '../models/phoneCountry'
import { LoginFormStore } from '../stores/loginFormStore'
import { RegistrationFormStore } from '../stores/registrationFormStore'
import { register, signIn } from './authActions'

const reply = { message: 'Login successful', token: 'not-a-jwt', user: { _id: 'u1', phone: '8888888888', name: 'Test Student 2', class: '9' } }

const filledLogin = () => {
  const form = new LoginFormStore()
  form.setName('Test Student 2')
  form.setPhone('8888888888')
  return form
}

beforeEach(() => {
  vi.spyOn(toastStore, 'show').mockImplementation(() => {})
})

describe('signIn', () => {
  it('sends the name and phone, and no class or date of birth', async () => {
    const calls = fakeServer(() => ({ status: 200, body: reply }))
    const navigate = vi.fn()
    await signIn(filledLogin(), navigate)

    expect(calls).toHaveLength(1)
    expect(calls[0].path).toBe('/api/user/login')
    expect(calls[0].body).toEqual({ phone: '8888888888', name: 'Test Student 2' })
    expect(navigate).toHaveBeenCalledWith('/quizzes', { replace: true })
  })

  it('sends nothing while the name is empty', async () => {
    const calls = fakeServer(() => ({ status: 200, body: reply }))
    const form = new LoginFormStore()
    form.setPhone('8888888888')
    const navigate = vi.fn()
    await signIn(form, navigate)

    expect(calls).toHaveLength(0)
    expect(navigate).not.toHaveBeenCalled()
  })

  it('shows the server message under the fields and stays put when the name or phone is wrong', async () => {
    fakeServer(() => ({ status: 404, body: { message: 'No student account matches this name and phone number.' } }))
    const navigate = vi.fn()
    const form = filledLogin()
    await signIn(form, navigate)

    expect(navigate).not.toHaveBeenCalled()
    expect(form.serverError).toBe('No student account matches this name and phone number.')
    expect(toastStore.show).not.toHaveBeenCalled()
    // Editing a field clears it.
    form.setPhone('888888888')
    expect(form.serverError).toBe(null)
  })

  it('sends a number from another country with its calling code', async () => {
    const calls = fakeServer(() => ({ status: 200, body: reply }))
    const form = new LoginFormStore()
    form.setCountry(phoneCountries.find((c) => c.iso === 'AE'))
    form.setPhone('501234567')
    form.setName('Test Student 2')
    await signIn(form, vi.fn())

    expect(calls[0].body).toEqual({ phone: '+971501234567', name: 'Test Student 2' })
  })

  it('shows the too-many-tries message', async () => {
    fakeServer(() => ({ status: 429, body: { message: 'Too many attempts. Try again later.' } }))
    const form = filledLogin()
    await signIn(form, vi.fn())

    expect(form.serverError).toBe('Too many attempts. Try again later.')
  })
})

describe('register', () => {
  it('registers without a date of birth, then signs in with the same name and phone', async () => {
    vi.spyOn(dialogStore, 'show').mockResolvedValue(true)
    const calls = fakeServer((method, path) =>
      path === '/api/user/register' ? { status: 201, body: { message: 'Registered', user: reply.user } } : { status: 200, body: reply },
    )
    const form = new RegistrationFormStore()
    form.setPhone('8888888888')
    form.setName('Test Student 2')
    form.setClassNumber('9')
    const navigate = vi.fn()
    await register(form, navigate)

    expect(form.isComplete).toBe(true)
    expect(calls.map((c) => c.path)).toEqual(['/api/user/register', '/api/user/login'])
    expect(calls[0].body).toEqual({ name: 'Test Student 2', phone: '8888888888', class: '9' })
    expect(calls[1].body).toEqual({ phone: '8888888888', name: 'Test Student 2' })
    expect(navigate).toHaveBeenCalledWith('/quizzes', { replace: true })
  })

  it('a UK number is shown with +44 in the check and sent with its code', async () => {
    const show = vi.spyOn(dialogStore, 'show').mockResolvedValue(true)
    const calls = fakeServer((method, path) =>
      path === '/api/user/register' ? { status: 201, body: { message: 'Registered', user: reply.user } } : { status: 200, body: reply },
    )
    const form = new RegistrationFormStore()
    form.setCountry(phoneCountries.find((c) => c.iso === 'GB'))
    form.setPhone('07400 123456')
    form.setName('Test Student 2')
    form.setClassNumber('9')
    await register(form, vi.fn())

    expect(form.phone).toBe('7400123456')
    expect(show.mock.calls[0][0](() => {}).props).toMatchObject({ phone: '7400123456', dialCode: '44' })
    expect(calls[0].body.phone).toBe('+447400123456')
    expect(calls[1].body).toEqual({ phone: '+447400123456', name: 'Test Student 2' })
  })
})
