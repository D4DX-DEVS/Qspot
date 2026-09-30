import React, { useEffect, useState } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import { FiActivity, FiAlertCircle, FiClock, FiArrowLeft } from 'react-icons/fi';
import Sidebar from '../components/Sidebar';
import ErrorState from '../components/ui/ErrorState';
import usePageTitle from '../hooks/usePageTitle';
import apiClient from '../api/client';
import { formatDuration, formatDateTime } from '../utils/format';
import brandIcon from '../assets/Icon.png';

// GET /api/quizzes/attempt/:attemptId ->
// { attemptId, quizId, title, user, language, score, totalQuestions,
//   percentage, totalDuration, createdAt, results: [QuestionResult] }
// QuestionResult = { questionId, type, question_en, question_ml, options_en,
//   options_ml, attemptedAnswer: index|null, correctAnswer: index, isCorrect }
const QuizAttemptDetailPage = () => {
  const { attemptId } = useParams();
  const navigate = useNavigate();

  const [attempt, setAttempt] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  usePageTitle(attempt?.title ? `${attempt.title} · Attempt` : 'Quiz Attempt');

  const fetchAttempt = async () => {
    try {
      setLoading(true);
      setError('');
      const response = await apiClient.get(`/quizzes/attempt/${attemptId}`);
      setAttempt(response.data);
    } catch (fetchError) {
      setError(fetchError.message || 'Failed to load attempt details.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchAttempt();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [attemptId]);

  return (
    <div className="flex min-h-screen overflow-x-hidden bg-black text-white">
      <Sidebar currentPage="quizAttempts" onNavigate={navigate} />
      <main className="w-full bg-transparent px-3 py-5 pb-28 sm:px-4 md:ml-64 md:pb-5">
        <header className="bg-transparent backdrop-blur-sm shadow-lg rounded-xl border border-white/5">
          <div className="max-w-4xl mx-auto px-3 sm:px-4">
            <div className="flex flex-wrap items-center justify-between gap-3 py-3">
              <div className="flex min-w-0 items-center gap-3 sm:gap-4">
                <img
                  src={brandIcon}
                  alt="QSpot"
                  className="h-9 w-9 shrink-0 object-contain rounded-lg border border-white/10 bg-white/5 p-1 sm:h-10 sm:w-10"
                />
                <div className="min-w-0">
                  <h1 className="truncate text-lg font-semibold text-white tracking-wide sm:text-2xl md:text-3xl">
                    {attempt?.title || 'Quiz Result Details'}
                  </h1>
                  <p className="text-[10px] uppercase tracking-[0.25em] text-white/50">ID #{attemptId}</p>
                </div>
              </div>
              <button
                type="button"
                onClick={() => navigate(attempt?.quizId ? `/admin/quiz/attempts?quizId=${attempt.quizId}` : '/admin/quiz/attempts')}
                className="bg-gradient-to-r from-gray-700 to-gray-800 text-white p-2 rounded-md font-medium hover:from-gray-800 hover:to-gray-900 transition-all duration-200 shadow-md inline-flex items-center gap-2"
              >
                <FiArrowLeft className="text-sm" />
              </button>
            </div>
          </div>
        </header>

        {error && (
          <div className="max-w-4xl mx-auto mt-3">
            <ErrorState message={error} onRetry={fetchAttempt} />
          </div>
        )}

        {loading && (
          <div className="max-w-4xl mx-auto mt-4 flex h-56 flex-col items-center justify-center text-white/70">
            <FiClock className="mb-2.5 animate-spin text-2xl text-white/60" />
            Loading quiz details…
          </div>
        )}

        {!loading && !attempt && !error && (
          <div className="max-w-4xl mx-auto mt-4 flex h-56 flex-col items-center justify-center text-center text-white/60">
            <FiAlertCircle className="mb-2.5 text-2xl text-white/40" />
            Attempt not found.
          </div>
        )}

        {!loading && attempt && (
          <section className="max-w-4xl mx-auto mt-4 space-y-4">
            <div className="bg-gray-900/80 backdrop-blur-sm rounded-xl shadow-xl border border-gray-700/50 overflow-hidden">
              <div className="px-3 sm:px-5 py-3 border-b border-gray-700/70">
                <h2 className="text-base font-bold text-white">User Information</h2>
              </div>
              <div className="px-3 sm:px-5 py-4">
                <div
                  className="mb-2.5 cursor-pointer p-3.5 bg-gradient-to-r from-violet-900/20 to-purple-900/20 rounded-lg border border-violet-700/30 hover:border-violet-500/50"
                  onClick={() => attempt.user?.id && navigate(`/admin/users/${attempt.user.id}`)}
                >
                  <div className="flex flex-wrap items-center justify-between gap-1">
                    <label className="text-xs font-medium text-gray-400">Full Name</label>
                    <p className="break-words text-lg font-bold text-white leading-tight">{attempt.user?.name || 'Unknown'}</p>
                  </div>
                </div>
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-2.5">
                  <div className="p-2.5 bg-gray-800/30 rounded-lg border border-gray-700/30">
                    <div className="flex items-center justify-between">
                      <label className="text-xs font-medium text-gray-400">Email</label>
                      <p className="text-xs font-semibold text-white">{attempt.user?.email || 'NA'}</p>
                    </div>
                  </div>
                  <div className="p-2.5 bg-gray-800/30 rounded-lg border border-gray-700/30">
                    <div className="flex items-center justify-between">
                      <label className="text-xs font-medium text-gray-400">Class</label>
                      <p className="text-xs font-semibold text-white">{attempt.user?.class || 'NA'}</p>
                    </div>
                  </div>
                  <div className="p-2.5 bg-gray-800/30 rounded-lg border border-gray-700/30">
                    <div className="flex items-center justify-between">
                      <label className="text-xs font-medium text-gray-400">Submitted At</label>
                      <p className="text-xs font-semibold text-white text-right">{formatDateTime(attempt.createdAt)}</p>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <div className="bg-gray-900/80 backdrop-blur-sm rounded-xl shadow-xl border border-gray-700/50 overflow-hidden">
              <div className="px-3 sm:px-5 py-3 border-b border-gray-700/70">
                <h2 className="text-base font-bold text-white">Quiz Result Summary</h2>
              </div>
              <div className="px-3 sm:px-5 py-4">
                <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
                  <div className="text-center">
                    <label className="block text-[11px] font-medium text-gray-400 mb-0.5">Score</label>
                    <p className="text-xl font-bold text-green-400">
                      {attempt.score}/{attempt.totalQuestions}
                    </p>
                  </div>
                  <div className="text-center">
                    <label className="block text-[11px] font-medium text-gray-400 mb-0.5">Percentage</label>
                    <p className="text-xl font-bold text-blue-400">{attempt.percentage}%</p>
                  </div>
                  <div className="text-center">
                    <label className="block text-[11px] font-medium text-gray-400 mb-0.5">Duration</label>
                    <p className="text-xl font-bold text-purple-400">{formatDuration(attempt.totalDuration)}</p>
                  </div>
                  <div className="text-center">
                    <label className="block text-[11px] font-medium text-gray-400 mb-0.5">Language</label>
                    <p className="text-xl font-bold text-indigo-400">{attempt.language || 'NA'}</p>
                  </div>
                </div>
              </div>
            </div>

            <div className="bg-gray-900/80 backdrop-blur-sm rounded-xl shadow-xl border border-gray-700/50 overflow-hidden">
              <div className="px-3 sm:px-5 py-3 border-b border-gray-700/70">
                <div className="flex items-center gap-2 text-[13px] font-semibold text-white">
                  <FiActivity className="text-sm text-[#EFB078]" />
                  Questions &amp; Answers
                </div>
              </div>
              <div className="px-3 sm:px-5 py-4">
                <div className="max-h-[480px] space-y-2.5 overflow-y-auto pr-1 text-[12px] [scrollbar-width:thin] [&::-webkit-scrollbar]:w-2">
                  {attempt.results?.map((result, index) => {
                    const isCorrect = Boolean(result.isCorrect);
                    const attemptedIndex =
                      typeof result.attemptedAnswer === 'number' ? result.attemptedAnswer : null;
                    return (
                      <div
                        key={result.questionId || index}
                        className={`p-3.5 rounded-lg border ${
                          isCorrect ? 'bg-green-900/20 border-green-700/50' : 'bg-red-900/20 border-red-700/50'
                        }`}
                      >
                        <div className="flex items-start justify-between mb-1.5">
                          <span className="text-[13px] font-semibold text-white">Question {index + 1}</span>
                          <span
                            className={`inline-flex items-center px-1.5 py-0.5 text-[10px] font-semibold rounded-full ${
                              isCorrect ? 'bg-green-900/50 text-green-200' : 'bg-red-900/50 text-red-200'
                            }`}
                          >
                            {isCorrect ? '✓ Correct' : '✗ Incorrect'}
                          </span>
                        </div>
                        <p className="mt-1 text-[13px] text-gray-200 leading-relaxed">{result.question_en}</p>
                        <p className="text-[12px] text-gray-400 leading-relaxed">{result.question_ml}</p>

                        {!!result.options_en?.length && (
                          <div className="mt-3">
                            <label className="block text-[10px] font-medium text-gray-400 mb-1">Options</label>
                            <div className="grid grid-cols-1 md:grid-cols-2 gap-1.5">
                              {result.options_en.map((option, optIdx) => {
                                const isCorrectOption = optIdx === result.correctAnswer;
                                const isUserOption = optIdx === attemptedIndex;
                                const colorClasses = isCorrectOption
                                  ? 'bg-green-900/30 border-green-600/50 text-green-300'
                                  : isUserOption
                                  ? 'bg-red-900/30 border-red-600/50 text-red-300'
                                  : 'bg-gray-800/30 border-gray-600/50 text-gray-300';
                                return (
                                  <div
                                    key={optIdx}
                                    className={`p-1.5 rounded border flex items-center justify-between ${colorClasses}`}
                                  >
                                    <span className="text-[12px]">{option}</span>
                                    <span className="ml-1.5">
                                      {isCorrectOption && <span className="text-green-400 text-xs font-bold">✓</span>}
                                      {isUserOption && !isCorrectOption && (
                                        <span className="text-red-400 text-xs font-bold">✗</span>
                                      )}
                                    </span>
                                  </div>
                                );
                              })}
                            </div>
                          </div>
                        )}

                        <div className="mt-2.5 grid grid-cols-1 md:grid-cols-2 gap-2.5">
                          <div>
                            <label className="block text-[10px] font-medium text-gray-400 mb-1">Correct Answer</label>
                            <p className="text-[13px] font-semibold text-green-400">
                              {result.options_en?.[result.correctAnswer] ?? 'NA'}
                            </p>
                          </div>
                          <div>
                            <label className="block text-[10px] font-medium text-gray-400 mb-1">User's Answer</label>
                            <p className={`text-[13px] font-semibold ${isCorrect ? 'text-green-400' : 'text-red-400'}`}>
                              {attemptedIndex !== null ? result.options_en?.[attemptedIndex] ?? 'NA' : 'Not answered'}
                            </p>
                          </div>
                        </div>
                      </div>
                    );
                  })}
                  {!attempt.results?.length && <p className="text-center text-white/60">No question data available.</p>}
                </div>
              </div>
            </div>
          </section>
        )}
      </main>
    </div>
  );
};

export default QuizAttemptDetailPage;
