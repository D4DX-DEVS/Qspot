import { ChangeNotifier } from '../../../lib/ChangeNotifier'
import { digitsOnly, phoneError } from './phoneRules'

// Screen state for sign-in: the typed phone number and chosen class, which
// together decide whether "Sign In" is ready
// (mobile-app/lib/screens/auth/provider/login_form_provider.dart).
export class LoginFormStore extends ChangeNotifier {
  phone = ''
  // The bare class number the API expects ('1'..'12'), or null before one is chosen.
  classNumber = null
  // Field errors show only after a submit attempt, like Form.validate().
  submitted = false
  // Why the server turned the sign-in down; cleared as soon as a field changes.
  serverError = null

  get isComplete() {
    return this.phone.trim().length === 10 && this.classNumber != null
  }

  get phoneError() {
    return this.submitted ? phoneError(this.phone) : null
  }

  get classError() {
    return this.submitted && this.classNumber == null ? 'Please choose your class' : null
  }

  // Always notifies, even when only a stray letter was typed: the redraw
  // puts the field back to the digits.
  setPhone(value) {
    this.phone = digitsOnly(value)
    this.serverError = null
    this.notifyListeners()
  }

  setClassNumber(value) {
    this.classNumber = value || null
    this.serverError = null
    this.notifyListeners()
  }

  setServerError(message) {
    this.serverError = message
    this.notifyListeners()
  }

  // Marks the form as submitted; true when it can be sent.
  validate() {
    this.submitted = true
    this.notifyListeners()
    return phoneError(this.phone) == null && this.classNumber != null
  }
}
