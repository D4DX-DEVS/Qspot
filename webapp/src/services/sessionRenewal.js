import { ApiClient } from './apiClient'
import { Storage } from './storage'

// Keeps a student signed in (mobile-app/lib/services/session_renewal_service.dart).
// A sign-in lasts 30 days; when less than a day is left it is swapped for a
// fresh one, so it can never run out in the middle of a quiz. The expiry is
// read from the token itself, so the server is only asked when it is due.
const THRESHOLD_MS = 24 * 60 * 60 * 1000
const TOKEN_KEY = 'auth_token'
let inFlight = null

// When the sign-in [token] (a JWT) expires, or null when it cannot be read.
export function expiryOf(token) {
  const parts = (token || '').split('.')
  if (parts.length !== 3) return null
  try {
    const base64 = parts[1].replace(/-/g, '+').replace(/_/g, '/')
    const padded = base64 + '='.repeat((4 - (base64.length % 4)) % 4)
    const payload = JSON.parse(atob(padded))
    return typeof payload?.exp === 'number' ? new Date(Math.round(payload.exp * 1000)) : null
  } catch {
    return null
  }
}

// Less than a day left, but not run out yet: one that has run out cannot be
// renewed, the student signs in again.
export function needsRenewal(expiry, now) {
  const left = expiry.getTime() - now.getTime()
  return left > 0 && left < THRESHOLD_MS
}

// Renews the sign-in when it is close to running out. One request at a time;
// never throws.
export function renewIfNeeded() {
  inFlight ??= renew().finally(() => {
    inFlight = null
  })
  return inFlight
}

async function renew() {
  try {
    const token = Storage.getString(TOKEN_KEY)
    const expiry = token ? expiryOf(token) : null
    if (!expiry || !needsRenewal(expiry, new Date())) return
    const data = await ApiClient.post('/api/user/refresh-token')
    if (typeof data?.token === 'string' && data.token !== '') Storage.setString(TOKEN_KEY, data.token)
  } catch (e) {
    console.warn('Sign-in not renewed:', e)
  }
}
