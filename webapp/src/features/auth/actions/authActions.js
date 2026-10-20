import { createElement } from 'react'
import { dialogStore } from '../../../stores/dialogStore'
import { toastStore } from '../../../stores/toastStore'
import { quizStore } from '../../quiz/stores/quizStore'
import QuizLogoutWarningDialog from '../../quiz/components/QuizLogoutWarningDialog'
import LogoutConfirmDialog from '../components/LogoutConfirmDialog'
import CountryPickerSheet from '../components/CountryPickerSheet'
import PhoneCheckDialog from '../components/PhoneCheckDialog'
import { authStore } from '../stores/authStore'

// Sign-in, registration and logout flows (the screens' button handlers in the
// app), kept out of the page components. [navigate] is React Router's.

const SIGN_IN_FAILED = "We couldn't sign you in. Please check your details and try again."

export async function signIn(form, navigate, to = '/quizzes') {
  if (!form.validate()) return
  const result = await authStore.login(form.phoneForApi, form.name.trim())
  // Shown under the fields, where it stays until the student edits them.
  if (result.success) navigate(to, { replace: true })
  else form.setServerError(result.message || SIGN_IN_FAILED)
}

export async function register(form, navigate) {
  if (!form.validate()) return
  const phone = form.phoneForApi
  // The last chance to fix a mistyped number: it is verified by OTP later.
  const confirmed = await dialogStore.show(
    (close) => createElement(PhoneCheckDialog, { phone: form.phone.trim(), dialCode: form.country.dial, onClose: close }),
    { dismissible: false },
  )
  if (!confirmed) return

  const result = await authStore.register({
    phone,
    name: form.name.trim(),
    classNumber: form.classNumber,
    consent: form.consent,
    courseIds: [...form.selectedCourseIds],
  })
  if (!result.success) {
    toastStore.show(result.message || "We couldn't create your account. Please try again.", 'danger')
    return
  }
  toastStore.show('Your account is ready! Signing you in…', 'success')
  // Registration returns no token: sign in with the same name and number.
  const signedIn = await authStore.login(phone, form.name.trim())
  if (signedIn.success) navigate('/quizzes', { replace: true })
  else navigate('/login', { replace: true })
}

// Opens the country list; resolves to the country picked, or null when the
// sheet is closed without choosing.
export function pickCountry(selected) {
  return dialogStore.show((close) => createElement(CountryPickerSheet, { selected, onClose: close }), { kind: 'sheet' })
}

// Asks before logging out. With quiz answers here that never reached the
// server it warns they will be deleted; otherwise the usual "Are you sure?".
export function confirmLogout() {
  const unsent = quizStore.unsentQuizCount()
  return dialogStore.show((close) =>
    unsent > 0
      ? createElement(QuizLogoutWarningDialog, { count: unsent, onClose: close })
      : createElement(LogoutConfirmDialog, { onClose: close }),
  )
}

// Clears this account's data from the browser (so the next person to sign
// in never sees it) and signs out.
export async function logout(navigate) {
  if (!(await confirmLogout())) return
  quizStore.deleteSavedQuizzes()
  quizStore.clear()
  authStore.logout()
  navigate('/login', { replace: true })
}
