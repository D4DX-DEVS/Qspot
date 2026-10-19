// Same idea as Flutter's ChangeNotifier: a store keeps its own state and
// logic, and calls notifyListeners() after every change. Components read it
// through useNotifier (see ./useNotifier.js), so screens hold no logic.
export class ChangeNotifier {
  #listeners = new Set()
  #version = 0

  subscribe = (listener) => {
    this.#listeners.add(listener)
    return () => this.#listeners.delete(listener)
  }

  getVersion = () => this.#version

  notifyListeners() {
    this.#version += 1
    for (const listener of [...this.#listeners]) listener()
  }
}
