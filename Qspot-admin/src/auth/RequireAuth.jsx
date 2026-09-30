import { Navigate, useLocation } from 'react-router-dom';
import { isLoggedIn } from '../api/client';

// Route guard: redirects to /admin/login (preserving where the admin was
// headed) when there is no token. The axios response interceptor handles
// the "token went stale" case (401/403 on a real request); this guard
// handles the "never logged in / manually opened a URL" case.
const RequireAuth = ({ children }) => {
  const location = useLocation();

  if (!isLoggedIn()) {
    return <Navigate to="/admin/login" replace state={{ from: location }} />;
  }

  return children;
};

export default RequireAuth;
