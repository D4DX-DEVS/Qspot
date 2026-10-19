import { API_BASE_URL } from '../config/env'
import { Storage } from './storage'

// Port of mobile-app/lib/services/api_client.dart.

// What the server's auth middleware (Qspot-API/middlewares/auth.js) sends with
// a 403 for a bad or expired token. Every other 403 is a business rule (quiz
// not live, not ready, ...) and must not sign the user out.
const EXPIRED_TOKEN_MESSAGE = 'Invalid or expired token'
const TOKEN_KEY = 'auth_token'
const USER_KEY = 'user_data'
const DEFAULT_TIMEOUT_MS = 15000

const TECHNICAL_HINTS = [
  'internal server error',
  'bad gateway',
  'service unavailable',
  'socketexception',
  'clientexception',
  'failed host lookup',
  'errno',
  'uri=',
  'exception:',
]

function normaliseMessage(status, message) {
  const trimmed = (message || '').trim()
  const lower = trimmed.toLowerCase()
  const technical = trimmed === '' || TECHNICAL_HINTS.some((hint) => lower.includes(hint))

  if (status === 401 || (status === 403 && trimmed === EXPIRED_TOKEN_MESSAGE)) {
    return 'Your session has expired. Please sign in again.'
  }
  // Other 403s are business rules ("Quiz is not live right now") whose
  // message is the useful part.
  if (status === 403 && technical) return "You don't have permission to do that."
  if (status === 404 && technical) return "We couldn't find what you requested."
  if (status >= 500 || technical) return 'Something went wrong on our side. Please try again in a moment.'
  return trimmed === '' ? 'Something went wrong. Please try again.' : trimmed
}

// An error reply from the server. [message] is always safe to show; [body] is
// the decoded JSON reply (e.g. a 409's `{message, attempt}`).
export class ApiException extends Error {
  constructor(status, message, body = null) {
    super(normaliseMessage(status, message))
    this.name = 'ApiException'
    this.status = status
    this.body = body
  }

  // The server turned the call away because the sign-in is no longer valid.
  get isAuthFailure() {
    return this.status === 401 || (this.status === 403 && this.body?.message === EXPIRED_TOKEN_MESSAGE)
  }
}

// The request never got an answer (offline, DNS, CORS, connection reset).
export class NetworkError extends Error {
  constructor(cause) {
    super('Network request failed')
    this.name = 'NetworkError'
    this.cause = cause
  }
}

// The server took longer than the timeout to answer.
export class TimeoutError extends Error {
  constructor() {
    super('Request timed out')
    this.name = 'TimeoutError'
  }
}

let sessionExpiryInFlight = null

// Called once when a signed-in call is refused because the sign-in ran out;
// set by the auth store (clears the account's data and signs out).
let onSessionExpired = null
export function setSessionExpiredHandler(handler) {
  onSessionExpired = handler
}

const token = () => Storage.getString(TOKEN_KEY) || null

function buildUrl(path, query) {
  const url = new URL(path.startsWith('http') ? path : `${API_BASE_URL}${path}`, window.location.origin)
  for (const [key, value] of Object.entries(query || {})) {
    if (value != null) url.searchParams.set(key, String(value))
  }
  return url.toString()
}

async function handleSessionExpired() {
  if (sessionExpiryInFlight) return sessionExpiryInFlight
  sessionExpiryInFlight = (async () => {
    Storage.remove(TOKEN_KEY)
    Storage.remove(USER_KEY)
    await onSessionExpired?.()
  })()
  try {
    await sessionExpiryInFlight
  } finally {
    sessionExpiryInFlight = null
  }
}

async function handle(response, hadToken) {
  const status = response.status
  let body = null
  try {
    const raw = await response.text()
    body = raw === '' ? null : JSON.parse(raw)
  } catch {
    body = null
  }

  if (status >= 200 && status < 300) return body

  const message = typeof body?.message === 'string' ? body.message : 'Something went wrong. Please try again.'
  // Only a call that was actually signed in signs the user out; a public
  // endpoint that happens to refuse must not.
  if ((status === 401 || (status === 403 && message === EXPIRED_TOKEN_MESSAGE)) && hadToken) {
    await handleSessionExpired()
  }
  throw new ApiException(status, message, body)
}

async function request(method, path, { query, body, timeout = DEFAULT_TIMEOUT_MS } = {}) {
  const headers = {}
  if (body !== undefined) headers['Content-Type'] = 'application/json'
  const current = token()
  if (current) headers.Authorization = `Bearer ${current}`

  const controller = new AbortController()
  const timer = setTimeout(() => controller.abort(), timeout)
  let response
  try {
    response = await fetch(buildUrl(path, query), {
      method,
      headers,
      body: body === undefined ? undefined : JSON.stringify(body),
      signal: controller.signal,
    })
  } catch (e) {
    if (controller.signal.aborted) throw new TimeoutError()
    throw new NetworkError(e)
  } finally {
    clearTimeout(timer)
  }
  return handle(response, current != null)
}

// Single HTTP wrapper used by every service: adds the sign-in token, applies
// a 15 second timeout, reads `{message}` error bodies into ApiException and
// signs the user out when the server says the sign-in ran out.
export const ApiClient = {
  // [timeout] (ms) overrides the default for this call, e.g. to give up
  // sooner when a saved copy is on the device.
  get: (path, { query, timeout } = {}) => request('GET', path, { query, timeout }),
  // No [body] sends no body at all (an empty JSON "null" would be refused).
  post: (path, { body } = {}) => request('POST', path, { body }),
  put: (path, { body } = {}) => request('PUT', path, { body }),
}
