import { ChangeNotifier } from '../../../lib/ChangeNotifier'
import { userFriendlyError } from '../../../utils/userFriendlyError'
import { AuthService } from '../services/authService'

// Who is signed in (mobile-app/lib/screens/auth/provider/auth_provider.dart).
// Reads the saved session straight away, so a page refresh stays signed in.
class AuthStore extends ChangeNotifier {
  #user = AuthService.isLoggedIn() ? AuthService.savedUser() : null
  #isLoading = false

  get user() {
    return this.#user
  }

  get isLoading() {
    return this.#isLoading
  }

  get isAuthenticated() {
    return this.#user != null && AuthService.isLoggedIn()
  }

  // Sign in with name and phone number.
  async login(phone, name) {
    this.#setLoading(true)
    try {
      const result = await AuthService.login(phone, name)
      if (result.success) this.#user = result.user
      return result
    } catch (e) {
      return { success: false, message: `We couldn’t sign you in. ${userFriendlyError(e)}` }
    } finally {
      this.#setLoading(false)
    }
  }

  // Registration never signs in (the API returns no token); the caller signs
  // the new account in with the same name and phone number.
  async register(details) {
    this.#setLoading(true)
    try {
      return await AuthService.register(details)
    } catch (e) {
      return { success: false, message: `We couldn’t create your account. ${userFriendlyError(e)}` }
    } finally {
      this.#setLoading(false)
    }
  }

  logout() {
    AuthService.logout()
    this.#user = null
    this.notifyListeners()
  }

  // The server said the sign-in ran out; the API client already cleared it.
  markSignedOut() {
    this.#user = null
    this.notifyListeners()
  }

  #setLoading(value) {
    this.#isLoading = value
    this.notifyListeners()
  }
}

export const authStore = new AuthStore()
