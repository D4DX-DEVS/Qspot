import { ChangeNotifier } from '../../../lib/ChangeNotifier'
import { userFriendlyError } from '../../../utils/userFriendlyError'
import { localeOf } from '../models/quizModels'
import { fetchAttempt } from '../services/quizAttemptService'
import { ReviewFilterStore } from './reviewFilterStore'

// The answer review's data: the results handed over by the result page, or
// (after a refresh) the attempt loaded again.
export class QuizReviewStore extends ChangeNotifier {
  filter = null
  language = 'en'
  error = null

  constructor(attemptId, initial) {
    super()
    this.attemptId = attemptId
    if (initial?.results?.length) this.#use(initial.results, initial.language)
  }

  #use(results, language) {
    this.filter = new ReviewFilterStore(results)
    this.language = language ?? 'en'
  }

  async loadIfNeeded() {
    if (this.filter) return
    try {
      const attempt = await fetchAttempt(this.attemptId)
      this.#use(attempt.results, localeOf(attempt.language))
    } catch (e) {
      this.error = userFriendlyError(e)
    }
    this.notifyListeners()
  }
}
