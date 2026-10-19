// Small wrapper around localStorage (the web stand-in for the app's
// SharedPreferences). Every key gets one prefix, and storage trouble (private
// mode, full disk) never throws: it reads as empty and writes report false.
const PREFIX = 'qspot:'

function store() {
  try {
    return window.localStorage
  } catch {
    return null
  }
}

export const Storage = {
  getString(key) {
    try {
      return store()?.getItem(PREFIX + key) ?? ''
    } catch {
      return ''
    }
  },

  setString(key, value) {
    try {
      store()?.setItem(PREFIX + key, value)
      return true
    } catch (e) {
      console.warn('Storage write failed:', e)
      return false
    }
  },

  remove(key) {
    try {
      store()?.removeItem(PREFIX + key)
    } catch {
      // Nothing to do: the key stays, and is ignored next time.
    }
  },

  // Keys (without the prefix) that start with [start].
  keysStartingWith(start) {
    const s = store()
    if (!s) return []
    const found = []
    try {
      for (let i = 0; i < s.length; i += 1) {
        const key = s.key(i)
        if (key?.startsWith(PREFIX + start)) found.push(key.slice(PREFIX.length))
      }
    } catch {
      return []
    }
    return found
  },
}
