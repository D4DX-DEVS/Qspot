import { Navigate, createBrowserRouter } from 'react-router-dom'
import GuestRoute from './components/common/GuestRoute'
import ProtectedRoute from './components/common/ProtectedRoute'
import { ANSWER_REVIEW_ENABLED, REGISTRATION_ENABLED } from './config/env'
import LoginPage from './features/auth/pages/LoginPage'
import RegistrationPage from './features/auth/pages/RegistrationPage'
import CertificatePage from './features/certificate/pages/CertificatePage'
import QuizListPage from './features/quiz/pages/QuizListPage'
import QuizPlayPage from './features/quiz/pages/QuizPlayPage'
import QuizResultPage from './features/quiz/pages/QuizResultPage'
import QuizReviewPage from './features/quiz/pages/QuizReviewPage'

// Sign-in pages for guests, quiz pages for signed-in students. The
// registration page exists only when switched on (VITE_ENABLE_REGISTRATION),
// and the answer review page only while ANSWER_REVIEW_ENABLED is on.
export const router = createBrowserRouter([
  {
    element: <GuestRoute />,
    children: [
      { path: '/login', element: <LoginPage /> },
      ...(REGISTRATION_ENABLED ? [{ path: '/register', element: <RegistrationPage /> }] : []),
    ],
  },
  {
    element: <ProtectedRoute />,
    children: [
      { path: '/quizzes', element: <QuizListPage /> },
      { path: '/quizzes/:quizId/play', element: <QuizPlayPage /> },
      { path: '/quizzes/:quizId/result', element: <QuizResultPage /> },
      ...(ANSWER_REVIEW_ENABLED ? [{ path: '/attempts/:attemptId/review', element: <QuizReviewPage /> }] : []),
      { path: '/certificates/:quizId', element: <CertificatePage /> },
    ],
  },
  { path: '*', element: <Navigate to="/quizzes" replace /> },
])
