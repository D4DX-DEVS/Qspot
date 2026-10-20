import { ApiClient, ApiException } from '../../../services/apiClient'
import { Storage } from '../../../services/storage'
import { userFromJson, userToJson } from '../models/userModel'

// Auth API calls (mobile-app/lib/screens/auth/service/auth_service.dart).
//  - POST /api/user/register  {name, phone, class, email?, consent?, courseIds?}
//        -> 201 {message, user}  (no token: registration does not sign in)
//  - POST /api/user/login     {phone, name} -> {message, token, user}
//        (spaces and capitals in the name are ignored; 404 wrong details, 429 too many tries)
const USER_KEY = 'user_data'
const TOKEN_KEY = 'auth_token'
const USER_ID_KEY = 'userId'

const failure = (e) =>
  e instanceof ApiException
    ? { success: false, message: e.message, status: e.status }
    : { success: false, message: 'Network error. Please try again.' }

export const AuthService = {
  // Sign in with name and phone number; on success the session
  // (token + user + userId) is saved.
  async login(phone, name) {
    try {
      const data = await ApiClient.post('/api/user/login', { body: { phone, name } })
      const user = userFromJson({ ...(data?.user || {}), token: data?.token ?? null })
      this.saveUser(user)
      return { success: true, user, message: data?.message ?? 'Login successful' }
    } catch (e) {
      console.warn('AuthService.login failed:', e)
      return failure(e)
    }
  },

  async register({ phone, name, classNumber, email, consent, courseIds = [] }) {
    try {
      const body = {
        name,
        phone,
        class: classNumber,
        ...(email ? { email } : {}),
        ...(consent ? { consent } : {}),
        ...(courseIds.length ? { courseIds } : {}),
      }
      const data = await ApiClient.post('/api/user/register', { body })
      return { success: true, message: data?.message ?? 'Registration successful' }
    } catch (e) {
      console.warn('AuthService.register failed:', e)
      return failure(e)
    }
  },

  saveUser(user) {
    Storage.setString(USER_KEY, JSON.stringify(userToJson(user)))
    if (user.token) Storage.setString(TOKEN_KEY, user.token)
    if (user.id) Storage.setString(USER_ID_KEY, String(user.id))
  },

  savedUser() {
    try {
      const raw = Storage.getString(USER_KEY)
      const json = raw ? JSON.parse(raw) : null
      return json && typeof json === 'object' ? userFromJson(json) : null
    } catch {
      return null
    }
  },

  // True only when a non-empty session token is stored.
  isLoggedIn: () => Storage.getString(TOKEN_KEY) !== '',

  // Clears auth data only; quiz copies are handled by the logout flow.
  logout() {
    Storage.remove(USER_KEY)
    Storage.remove(TOKEN_KEY)
    Storage.remove(USER_ID_KEY)
  },
}
