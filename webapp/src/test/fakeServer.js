import { vi } from 'vitest'

// Replaces fetch with [handler](method, path, body) -> {status, body} or a
// thrown error (no connection). Records every call.
export function fakeServer(handler) {
  const calls = []
  globalThis.fetch = vi.fn(async (url, init = {}) => {
    const path = new URL(url).pathname
    const body = init.body ? JSON.parse(init.body) : undefined
    calls.push({ method: init.method, path, body })
    const reply = await handler(init.method, path, body)
    return {
      status: reply.status,
      text: async () => (reply.body === undefined ? '' : JSON.stringify(reply.body)),
    }
  })
  return calls
}

export const offline = () => {
  throw new TypeError('Failed to fetch')
}
