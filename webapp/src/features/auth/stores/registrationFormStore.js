import { ChangeNotifier } from '../../../lib/ChangeNotifier'
import { fetchActiveCourses } from '../services/courseService'
import { digitsOnly, phoneError } from './phoneRules'

// Screen state for the registration form
// (mobile-app/lib/screens/auth/provider/registration_form_provider.dart).
export class RegistrationFormStore extends ChangeNotifier {
  phone = ''
  name = ''
  classNumber = null
  hasConsent = false
  // 'parent' or 'school', as the API expects.
  consentBy = 'parent'
  consentName = ''
  courses = []
  selectedCourseIds = new Set()
  coursesLoading = true
  submitted = false

  get isComplete() {
    return this.phone.trim().length === 10 && this.name.trim().length >= 3 && this.classNumber != null
  }

  get phoneError() {
    return this.submitted ? phoneError(this.phone) : null
  }

  get nameError() {
    if (!this.submitted) return null
    if (this.name.trim() === '') return 'Please enter your name'
    if (this.name.trim().length < 3) return 'Name must be at least 3 characters'
    return null
  }

  get classError() {
    return this.submitted && this.classNumber == null ? 'Please choose your class' : null
  }

  get consentNameError() {
    if (!this.submitted || !this.hasConsent || this.consentName.trim() !== '') return null
    return this.consentBy === 'parent' ? 'Please enter the parent/guardian name' : 'Please enter the school name'
  }

  // The consent the API stores, or null when the box is not ticked.
  get consent() {
    if (!this.hasConsent) return null
    const name = this.consentName.trim()
    return { by: this.consentBy, ...(name ? { name } : {}) }
  }

  async loadCourses() {
    this.courses = await fetchActiveCourses()
    this.coursesLoading = false
    this.notifyListeners()
  }

  setPhone(value) {
    this.phone = digitsOnly(value)
    this.notifyListeners()
  }

  setName(value) {
    this.name = value
    this.notifyListeners()
  }

  setClassNumber(value) {
    this.classNumber = value || null
    this.notifyListeners()
  }

  setHasConsent(value) {
    this.hasConsent = value
    this.notifyListeners()
  }

  setConsentBy(value) {
    this.consentBy = value
    this.notifyListeners()
  }

  setConsentName(value) {
    this.consentName = value
    this.notifyListeners()
  }

  toggleCourse(id, selected) {
    const next = new Set(this.selectedCourseIds)
    if (selected) next.add(id)
    else next.delete(id)
    this.selectedCourseIds = next
    this.notifyListeners()
  }

  // Marks the form as submitted; true when every field is valid.
  validate() {
    this.submitted = true
    this.notifyListeners()
    return (
      this.isComplete &&
      this.phoneError == null &&
      this.nameError == null &&
      this.classError == null &&
      this.consentNameError == null
    )
  }
}
