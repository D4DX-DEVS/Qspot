import { ChangeNotifier } from '../../../lib/ChangeNotifier'
import { acceptsLength, cleanNumber, INDIA, phoneForApi } from '../models/phoneCountry'
import { phoneError } from './phoneRules'

// Screen state for sign-in: the typed name and phone number (and its
// country), which together decide whether a sign-in can be sent
// (mobile-app/lib/screens/auth/provider/login_form_provider.dart).
export class LoginFormStore extends ChangeNotifier {
  name = ''
  phone = ''
  country = INDIA
  // Field errors show only after a submit attempt, like Form.validate().
  submitted = false
  // Why the server turned the sign-in down; cleared as soon as a field changes.
  serverError = null

  get isComplete() {
    return acceptsLength(this.country, this.phone.trim().length) && this.name.trim() !== ''
  }

  // The typed number the way the API expects it.
  get phoneForApi() {
    return phoneForApi(this.country, this.phone.trim())
  }

  get phoneError() {
    return this.submitted ? phoneError(this.phone, this.country) : null
  }

  get nameError() {
    return this.submitted && this.name.trim() === '' ? 'Please enter your name' : null
  }

  // Always notifies, even when only a stray letter was typed: the redraw
  // puts the field back to the digits.
  setPhone(value) {
    this.phone = cleanNumber(this.country, value)
    this.serverError = null
    this.notifyListeners()
  }

  // A number typed for the old country is cut to fit the new one.
  setCountry(country) {
    this.country = country
    this.phone = cleanNumber(country, this.phone)
    this.serverError = null
    this.notifyListeners()
  }

  setName(value) {
    this.name = value
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
    return phoneError(this.phone, this.country) == null && this.name.trim() !== ''
  }
}
