import { ChangeNotifier } from '../lib/ChangeNotifier'

// The one way to show a snack bar (mobile-app/lib/widgets/common/app_snack_bar.dart).
// Colour by outcome: 'success' green, 'danger' red, 'warning' orange. A new
// message replaces the one on screen.

// Long enough to read: 3 seconds, plus time for longer messages, up to 8.
export const toastDuration = (message) => Math.min(8000, Math.max(3000, String(message).length * 65))

class ToastStore extends ChangeNotifier {
  current = null
  #timer = null
  #nextId = 1

  show(message, tone = 'danger', durationMs = toastDuration(message)) {
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
