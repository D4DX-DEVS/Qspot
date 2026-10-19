import { afterEach, beforeEach, vi } from 'vitest'

// Minimal browser bits the services use: localStorage and location.
class MemoryStorage {
  #items = new Map()
  get length() {
    return this.#items.size
  }
  key(i) {
    return [...this.#items.keys()][i] ?? null
  }
  getItem(k) {
    return this.#items.has(k) ? this.#items.get(k) : null
  }
  setItem(k, v) {
    this.#items.set(k, String(v))
  }
  removeItem(k) {
    this.#items.delete(k)
  }
  clear() {
    this.#items.clear()
  }
}

globalThis.window = { localStorage: new MemoryStorage(), location: { origin: 'http://localhost' } }

beforeEach(() => {
  window.localStorage.clear()
})

afterEach(() => {
  vi.restoreAllMocks()
})
