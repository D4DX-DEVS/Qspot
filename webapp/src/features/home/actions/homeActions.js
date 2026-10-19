import { continueQuiz, openQuizFromList } from '../../quiz/actions/quizListActions'

// The hero card's button: carry on with a quiz started here, otherwise the
// same as tapping the quiz in the list.
export function openHeroQuiz(hero, navigate) {
  if (hero.record) return continueQuiz(hero.record, navigate)
  return openQuizFromList(hero.quiz, navigate)
}
