import React from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import AdminLogin from './pages/AdminLogin';
import AdminDashboard from './pages/AdminDashboard';
import SpeakersPage from './pages/SpeakersPage';
import BannerPage from './pages/BannerPage';
import NotificationsPage from './pages/NotificationsPage';
import QuestionsPage from './pages/QuestionsPage';
import VideosPage from './pages/VideosPage';
import SubjectsPage from './pages/SubjectsPage';
import SchedulesPage from './pages/SchedulesPage';
import QuizzesPage from './pages/QuizzesPage';
import QuizPage from './pages/QuizPage';
import QuizAttemptsPage from './pages/QuizAttemptsPage';
import QuizAttemptDetailPage from './pages/QuizAttemptDetailPage';
import VideoQuestionsPage from './pages/VideoQuestionsPage';
import ChapterGuidePage from './pages/ChapterGuidePage';
import CoursesPage from './pages/CoursesPage';
import CurriculumPage from './pages/CurriculumPage';
import AssignmentsPage from './pages/AssignmentsPage';
import UserActivityPage from './pages/UserActivityPage';
import LearningAnalyticsPage from './pages/LearningAnalyticsPage';
import NavigationPage from './pages/NavigationPage';
import RequireAuth from './auth/RequireAuth';
import ErrorBoundary from './components/ErrorBoundary';
import NotFound from './components/NotFound';

function App() {
  return (
    <ErrorBoundary>
      <Router>
        <div className="App">
          <Routes>
            <Route path="/" element={<Navigate to="/admin/login" replace />} />
            <Route path="/admin/login" element={<AdminLogin />} />

            <Route
              path="/admin/dashboard"
              element={
                <RequireAuth>
                  <AdminDashboard />
                </RequireAuth>
              }
            />
            <Route
              path="/admin/users/:id"
              element={
                <RequireAuth>
                  <UserActivityPage />
                </RequireAuth>
              }
            />
            <Route
              path="/admin/speakers"
              element={
                <RequireAuth>
                  <SpeakersPage />
                </RequireAuth>
              }
            />
            <Route
              path="/admin/banner"
              element={
                <RequireAuth>
                  <BannerPage />
                </RequireAuth>
              }
            />
            <Route
              path="/admin/notifications"
              element={
                <RequireAuth>
                  <NotificationsPage />
                </RequireAuth>
              }
            />
            <Route
              path="/admin/questions"
              element={
                <RequireAuth>
                  <QuestionsPage />
                </RequireAuth>
              }
            />
            <Route
              path="/admin/videos"
              element={
                <RequireAuth>
                  <VideosPage />
                </RequireAuth>
              }
            />
            {/* Video Content (questions/learn note/handouts) is reached from a
                video card's "Content" link rather than living in the sidebar. */}
            <Route
              path="/admin/video-questions"
              element={
                <RequireAuth>
                  <VideoQuestionsPage />
                </RequireAuth>
              }
            />
            <Route
              path="/admin/subjects"
              element={
                <RequireAuth>
                  <SubjectsPage />
                </RequireAuth>
              }
            />
            {/* Chapter Guide is reached from a subject's "Guide" link rather
                than living in the sidebar. */}
            <Route
              path="/admin/chapter-guide"
              element={
                <RequireAuth>
                  <ChapterGuidePage />
                </RequireAuth>
              }
            />
            <Route
              path="/admin/courses"
              element={
                <RequireAuth>
                  <CoursesPage />
                </RequireAuth>
              }
            />
            <Route
              path="/admin/curriculum"
              element={
                <RequireAuth>
                  <CurriculumPage />
                </RequireAuth>
              }
            />
            <Route
              path="/admin/assignments"
              element={
                <RequireAuth>
                  <AssignmentsPage />
                </RequireAuth>
              }
            />
            <Route path="/admin/analytics" element={<RequireAuth><LearningAnalyticsPage /></RequireAuth>} />
            <Route path="/admin/navigation" element={<RequireAuth><NavigationPage /></RequireAuth>} />
            <Route
              path="/admin/schedules"
              element={
                <RequireAuth>
                  <SchedulesPage />
                </RequireAuth>
              }
            />
            <Route
              path="/admin/quizzes"
              element={
                <RequireAuth>
                  <QuizzesPage />
                </RequireAuth>
              }
            />
            <Route
              path="/admin/quiz"
              element={
                <RequireAuth>
                  <QuizPage />
                </RequireAuth>
              }
            />
            <Route
              path="/admin/quiz/attempts"
              element={
                <RequireAuth>
                  <QuizAttemptsPage />
                </RequireAuth>
              }
            />
            <Route
              path="/admin/quiz/attempts/:attemptId"
              element={
                <RequireAuth>
                  <QuizAttemptDetailPage />
                </RequireAuth>
              }
            />

            <Route path="*" element={<NotFound />} />
          </Routes>
        </div>
      </Router>
    </ErrorBoundary>
  );
}

export default App;
