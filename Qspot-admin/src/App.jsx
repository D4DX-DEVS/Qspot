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
import QuizPage from './pages/QuizPage';
import QuizAttemptsPage from './pages/QuizAttemptsPage';
import QuizAttemptDetailPage from './pages/QuizAttemptDetailPage';

function App() {
  return (
    <Router>
      <div className="App">
        <Routes>
          <Route path="/" element={<Navigate to="/admin/login" replace />} />
          <Route path="/admin/login" element={<AdminLogin />} />
          <Route path="/admin/dashboard" element={<AdminDashboard />} />
          <Route path="/admin/speakers" element={<SpeakersPage />} />
          <Route path="/admin/banner" element={<BannerPage />} />
          <Route path="/admin/notifications" element={<NotificationsPage />} />
          <Route path="/admin/questions" element={<QuestionsPage />} />
          <Route path="/admin/videos" element={<VideosPage />} />
          <Route path="/admin/subjects" element={<SubjectsPage />} />
          <Route path="/admin/schedules" element={<SchedulesPage />} />
          <Route path="/admin/quiz" element={<QuizPage />} />
          <Route path="/admin/quiz/attempts" element={<QuizAttemptsPage />} />
          <Route path="/admin/quiz/attempts/:attemptId" element={<QuizAttemptDetailPage />} />
        </Routes>
      </div>
    </Router>
  );
}

export default App;
