import { ChangeNotifier } from '../../../lib/ChangeNotifier'

// Which questions the answer review shows: all, or only the wrong ones
// (mobile-app/lib/screens/quiz/provider/quiz_review_filter_provider.dart).
// Question numbers stay those of the full attempt.
export class ReviewFilterStore extends ChangeNotifier {
  filter = 'all' // 'all' | 'wrong'

  constructor(results) {
    super()
    this.results = results
  }

  get total() {
    return this.results.length
  }

  get wrongCount() {
    return this.results.filter((r) => !r.isCorrect).length
  }

  // Only useful when some, but not all, answers were wrong.
  get showsFilter() {
    return this.wrongCount > 0 && this.wrongCount < this.total
  }

  // [{number, result}] to show.
  get visible() {
    return this.results
      .map((result, i) => ({ number: i + 1, result }))
      .filter(({ result }) => this.filter === 'all' || !result.isCorrect)
  }

  labelFor = (f) => (f === 'all' ? `All ${this.total}` : `Wrong ${this.wrongCount}`)

  select(f) {
    if (f === this.filter) return
    this.filter = f
    this.notifyListeners()
  }
}
