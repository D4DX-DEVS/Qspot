import { ChangeNotifier } from '../../../lib/ChangeNotifier'

// How many quizzes a home section shows before "View All".
export const SECTION_PREVIEW = 3

// Id of the Past Quizzes section, which the home stat tiles scroll to.
export const PAST_SECTION_ID = 'past-quizzes'

// Which home sections (Live, Upcoming, Past) are opened to show every quiz.
export class QuizSectionsStore extends ChangeNotifier {
  #open = new Set()

  isOpen = (key) => this.#open.has(key)

  hasMore = (quizzes) => quizzes.length > SECTION_PREVIEW

  // The quizzes the section shows right now.
  visible = (key, quizzes) => (this.isOpen(key) ? quizzes : quizzes.slice(0, SECTION_PREVIEW))

  toggle(key) {
    if (this.#open.has(key)) this.#open.delete(key)
    else this.#open.add(key)
    this.notifyListeners()
  }
}
