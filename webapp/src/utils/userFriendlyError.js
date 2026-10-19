import { ApiException, NetworkError, TimeoutError } from '../services/apiClient'

// Turns a thrown error into text that is safe to show a user
// (mobile-app/lib/utils/user_friendly_error.dart). Raw error text never
// leaves this function.
export function userFriendlyError(error) {
  if (error instanceof TimeoutError) {
    return 'This is taking longer than usual. Please check your connection and try again.'
  }
  if (error instanceof NetworkError) {
    return "Can't reach the server. Please check your internet connection and try again."
  }
  if (error instanceof ApiException) {
    if (error.status === 401) return 'Your session has expired. Please sign in again.'
    if (error.status === 403) return "You don't have permission to do that."
    if (error.status === 404) {
      return readable(error.message) ? error.message : "We couldn't find what you requested."
    }
    if (error.status >= 500) return 'Something went wrong on our side. Please try again in a moment.'
    return readable(error.message) ? error.message : 'Please check the details and try again.'
  }
  return 'Something went wrong. Please try again.'
}

function readable(message) {
  const lower = message.toLowerCase()
  return (
    message.trim() !== '' &&
    !['exception', 'socket', 'errno', 'uri=', 'failed host lookup', 'internal server error', 'bad gateway'].some((hint) =>
      lower.includes(hint),
    )
  )
}
