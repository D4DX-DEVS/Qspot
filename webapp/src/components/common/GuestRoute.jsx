import { Navigate, Outlet } from 'react-router-dom'
import { useNotifier } from '../../lib/useNotifier'
import { authStore } from '../../features/auth/stores/authStore'

// Sign-in pages; someone already signed in goes to their quizzes.
export default function GuestRoute() {
  const auth = useNotifier(authStore)
  return auth.isAuthenticated ? <Navigate to="/quizzes" replace /> : <Outlet />
}
