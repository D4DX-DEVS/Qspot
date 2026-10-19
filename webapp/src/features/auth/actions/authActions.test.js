import { beforeEach, describe, expect, it, vi } from 'vitest'
import { dialogStore } from '../../../stores/dialogStore'
import { toastStore } from '../../../stores/toastStore'
import { fakeServer } from '../../../test/fakeServer'
import { LoginFormStore } from '../stores/loginFormStore'
import { RegistrationFormStore } from '../stores/registrationFormStore'
import { register, signIn } from './authActions'

const reply = { message: 'Login successful', token: 'not-a-jwt', user: { _id: 'u1', phone: '8888888888', name: 'Test Student 2', class: '9' } }

const filledLogin = () => {
  const form = new LoginFormStore()
  form.setPhone('8888888888')
  form.setClassNumber('9')
  return form
}

beforeEach(() => {
  vi.spyOn(toastStore, 'show').mockImplementation(() => {})
})

describe('signIn', () => {
  it('sends the phone and class, and no date of birth', async () => {
    const calls = fakeServer(() => ({ status: 200, body: reply }))
    const navigate = vi.fn()
    await signIn(filledLogin(), navigate)

    expect(calls).toHaveLength(1)
    expect(calls[0].path).toBe('/api/user/login')
    expect(calls[0].body).toEqual({ phone: '8888888888', class: '9' })
    expect(navigate).toHaveBeenCalledWith('/quizzes', { replace: true })
  })

  it('sends nothing while the class is not chosen', async () => {
    const calls = fakeServer(() => ({ status: 200, body: reply }))
    const form = new LoginFormStore()
    form.setPhone('8888888888')
    const navigate = vi.fn()
    await signIn(form, navigate)

    expect(calls).toHaveLength(0)
    expect(navigate).not.toHaveBeenCalled()
  })

  it('shows the server message and stays put when the phone or class is wrong', async () => {
    fakeServer(() => ({ status: 404, body: { message: 'No student found with that phone number and class' } }))
    const navigate = vi.fn()
    await signIn(filledLogin(), navigate)

    expect(navigate).not.toHaveBeenCalled()
    expect(toastStore.show).toHaveBeenCalledWith('No student found with that phone number and class', 'danger')
  })

  it('shows the too-many-tries message', async () => {
    fakeServer(() => ({ status: 429, body: { message: 'Too many attempts. Try again later.' } }))
    await signIn(filledLogin(), vi.fn())

    expect(toastStore.show).toHaveBeenCalledWith('Too many attempts. Try again later.', 'danger')
  })
})

describe('register', () => {
  it('registers without a date of birth, then signs in with the same phone and class', async () => {
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
    expect(calls[1].body).toEqual({ phone: '8888888888', class: '9' })
    expect(navigate).toHaveBeenCalledWith('/quizzes', { replace: true })
  })
})
