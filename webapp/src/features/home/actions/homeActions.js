import { continueQuiz, openQuizFromList } from '../../quiz/actions/quizListActions'

// The hero card's button: carry on with a quiz started here, otherwise the
// same as tapping the quiz in the list.
export function openHeroQuiz(hero, navigate) {
  if (hero.record) return continueQuiz(hero.record, navigate)
  return openQuizFromList(hero.quiz, navigate)
}

// Brings a home section (by its id) into view, e.g. Past Quizzes from the
// stat tiles.
export function scrollToSection(id) {
  const reduce = window.matchMedia('(prefers-reduced-motion: reduce)').matches
  document.getElementById(id)?.scrollIntoView({ behavior: reduce ? 'auto' : 'smooth', block: 'start' })
}
