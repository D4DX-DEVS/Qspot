import { createElement } from 'react'
import { dialogStore } from '../../../stores/dialogStore'
import { logout } from '../../auth/actions/authActions'
import { authStore } from '../../auth/stores/authStore'
import { continueQuiz, openQuizFromList } from '../../quiz/actions/quizListActions'
import AccountSheet from '../components/AccountSheet'

// The hero card's button: carry on with a quiz started here, otherwise the
// same as tapping the quiz in the list.
export function openHeroQuiz(hero, navigate) {
  if (hero.record) return continueQuiz(hero.record, navigate)
  return openQuizFromList(hero.quiz, navigate)
}

// The avatar: the student's account, with Log Out (which asks first).
export async function openAccount(navigate) {
  const wantsLogout = await dialogStore.show(
    (close) => createElement(AccountSheet, { user: authStore.user, onLogout: () => close(true) }),
    { kind: 'sheet', dismissValue: false },
  )
  if (wantsLogout) await logout(navigate)
}
