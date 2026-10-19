import { Navigate, Outlet, useLocation } from 'react-router-dom'
import { useNotifier } from '../../lib/useNotifier'
import { authStore } from '../../features/auth/stores/authStore'

// Pages that need a sign-in; anyone else goes to the sign-in page.
export default function ProtectedRoute() {
  const auth = useNotifier(authStore)
  const location = useLocation()
  return auth.isAuthenticated ? <Outlet /> : <Navigate to="/login" replace state={{ from: location.pathname }} />
}
