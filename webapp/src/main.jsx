import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { RouterProvider } from 'react-router-dom'
import DialogHost from './components/common/DialogHost'
import ToastHost from './components/common/ToastHost'
import { authStore } from './features/auth/stores/authStore'
import { quizStore } from './features/quiz/stores/quizStore'
import { renewIfNeeded } from './services/sessionRenewal'
import { setSessionExpiredHandler } from './services/apiClient'
import { dialogStore } from './stores/dialogStore'
import { router } from './App'
import './index.css'

// A sign-in that ran out: this account's lists are cleared and the student
// signs in again. Unsent quiz answers stay (saved under their id), so they
// can still be sent after signing back in.
setSessionExpiredHandler(() => {
  dialogStore.closeAll()
  quizStore.clear()
  authStore.markSignedOut()
})

// Renew a sign-in that is about to run out, on open and on coming back.
renewIfNeeded()
document.addEventListener('visibilitychange', () => {
  if (!document.hidden && authStore.isAuthenticated) renewIfNeeded()
})

createRoot(document.getElementById('root')).render(
  <StrictMode>
    <RouterProvider router={router} />
    <DialogHost />
    <ToastHost />
  </StrictMode>,
)
