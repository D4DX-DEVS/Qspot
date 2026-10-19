import { ChangeNotifier } from '../lib/ChangeNotifier'

// The one way to show a snack bar (mobile-app/lib/widgets/common/app_snack_bar.dart).
// Colour by outcome: 'success' green, 'danger' red, 'warning' orange. A new
// message replaces the one on screen.
class ToastStore extends ChangeNotifier {
  current = null
  #timer = null
  #nextId = 1

  show(message, tone = 'danger', durationMs = 3000) {
    clearTimeout(this.#timer)
    this.current = { id: this.#nextId++, message, tone }
    this.notifyListeners()
    this.#timer = setTimeout(() => this.hide(), durationMs)
  }

  hide() {
    clearTimeout(this.#timer)
    this.current = null
    this.notifyListeners()
  }
}

export const toastStore = new ToastStore()
