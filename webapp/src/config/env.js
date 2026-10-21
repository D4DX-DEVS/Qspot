// Same API the mobile app talks to by default (mobile-app/lib/utils/api_urls.dart).
const PRODUCTION_API = 'https://qspot-app-vcbgp.ondigitalocean.app'

const configured = (import.meta.env.VITE_API_BASE_URL || '').trim()

// Where API calls go. In development it is empty, so calls hit the Vite
// dev server, which forwards /api (see vite.config.js).
export const API_BASE_URL = configured || (import.meta.env.DEV ? '' : PRODUCTION_API)

// The registration screen is built but hidden until this is switched on.
export const REGISTRATION_ENABLED = import.meta.env.VITE_ENABLE_REGISTRATION === 'true'

// Answer review (each question with the student's answer and the correct
// one) is hidden for now; true brings back "Review Answers" after a quiz
// closes. Keep it the same as answerReviewEnabled in the mobile app.
export const ANSWER_REVIEW_ENABLED = false
