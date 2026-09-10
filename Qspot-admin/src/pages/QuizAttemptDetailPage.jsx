import React, { useEffect, useMemo, useState } from 'react';
import axios from 'axios';
import { useNavigate, useParams } from 'react-router-dom';
import { FiActivity, FiAlertCircle, FiClock, FiArrowLeft } from 'react-icons/fi';
import Sidebar from '../components/Sidebar';
import brandIcon from '../assets/Icon.png';

const formatDuration = (seconds) => {
  const value = Number(seconds);
  if (Number.isNaN(value) || value < 0) return '0s';
  const mins = Math.floor(value / 60);
  const secs = Math.floor(value % 60);
  if (mins <= 0) return `${secs}s`;
  return `${mins}m ${secs.toString().padStart(2, '0')}s`;
};

const formatDateTime = (isoString) => {
  if (!isoString) return 'NA';
  const date = new Date(isoString);
  if (Number.isNaN(date.getTime())) return 'NA';
  return date.toLocaleString();
};

const QuizAttemptDetailPage = () => {
  const { attemptId } = useParams();
  const baseURL = import.meta.env.VITE_API_BASE_URL;
  const token = useMemo(() => localStorage.getItem('adminToken'), []);
  const navigate = useNavigate();

  const [attempt, setAttempt] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  const handleNavigate = (path) => {
    window.location.href = path;
  };

  useEffect(() => {
    const fetchAttempt = async () => {
      if (!baseURL || !token || !attemptId) {
        setError('Missing configuration or authentication token.');
        setLoading(false);
        return;
      }
      try {
        setLoading(true);
        setError('');
        const response = await axios.get(`${baseURL}/quizzes/attempt/${attemptId}`, {
          headers: { Authorization: `Bearer ${token}` }
        });
        setAttempt(response.data);
      } catch (fetchError) {
        console.error('Error fetching attempt detail:', fetchError);
        setError(fetchError.response?.data?.message || 'Failed to load attempt details.');
      } finally {
        setLoading(false);
      }
    };

    fetchAttempt();
  }, [attemptId, baseURL, token]);

  return (
    <div className="flex min-h-screen bg-black text-white">
      <Sidebar currentPage="quizAttempts" onNavigate={handleNavigate} />
      <main className="ml-64 w-full bg-transparent px-4 py-5">
        {/* Header - styled to match other project */}
        <header className="bg-transparent backdrop-blur-sm shadow-lg rounded-xl border border-white/5">
          <div className="max-w-4xl mx-auto px-4">
            <div className="flex justify-between items-center py-3">
              <div className="flex items-center gap-4">
                <img
                  src={brandIcon}
                  alt="QSpot"
                  className="w-10 h-10 object-contain rounded-lg border border-white/10 bg-white/5 p-1"
                />
                <div>
                  <h1
                    className="text-2xl md:text-3xl font-semibold text-white tracking-wide"
                    style={{ fontFamily: "'Poppins', 'Segoe UI', 'Roboto', sans-serif", letterSpacing: '0.02em' }}
                  >
                    Quiz Result Details
                  </h1>
                  <p className="text-[10px] uppercase tracking-[0.25em] text-white/50">ID #{attemptId}</p>
                </div>
              </div>
              <div className="flex items-center gap-3">
                <button
                  type="button"
                  onClick={() => navigate('/admin/quiz/attempts')}
                  className="bg-gradient-to-r from-gray-700 to-gray-800 text-white p-1.5 rounded-md font-medium hover:from-gray-800 hover:to-gray-900 transition-all duration-200 shadow-md inline-flex items-center gap-2"
                >
                  <FiArrowLeft className="text-sm" />
                </button>
                <div className="text-right hidden sm:block">
                  <p className="text-xs text-gray-400 font-medium">Admin Dashboard</p>
                  <p className="text-[10px] text-gray-500">Detailed Quiz Analysis</p>
                </div>
              </div>
            </div>
          </div>
        </header>

        {/* Error / Loading */}
        {error && (
          <div className="max-w-4xl mx-auto mt-3 rounded-xl border border-red-700/50 bg-red-900/40 px-3 py-2.5 text-xs text-red-200">
            {error}
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
            {/* User Information Card */}
            <div className="bg-gray-900/80 backdrop-blur-sm rounded-xl shadow-xl border border-gray-700/50 overflow-hidden">
              <div className="px-5 py-3 border-b border-gray-700/70">
                <div className="flex items-center justify-between">
                  <h2 className="text-base font-bold text-white">User Information</h2>
                </div>
              </div>
              <div className="px-5 py-4">
                <div className="mb-2.5 p-3.5 bg-gradient-to-r from-violet-900/20 to-purple-900/20 rounded-lg border border-violet-700/30">
                  <div className="flex items-center justify-between">
                    <label className="text-xs font-medium text-gray-400">Full Name</label>
                    <p className="text-lg font-bold text-white leading-tight">{attempt.user?.name || 'Unknown'}</p>
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

            {/* Result Summary Card */}
            <div className="bg-gray-900/80 backdrop-blur-sm rounded-xl shadow-xl border border-gray-700/50 overflow-hidden">
              <div className="px-5 py-3 border-b border-gray-700/70">
                <h2 className="text-base font-bold text-white">Quiz Result Summary</h2>
                <p className="text-[11px] text-gray-300 mt-0.5">Performance metrics and statistics</p>
              </div>
              <div className="px-5 py-4">
                <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
                  <div className="text-center">
                    <label className="block text-[11px] font-medium text-gray-400 mb-0.5">Score</label>
                    <p className="text-xl font-bold text-green-400">{attempt.score}</p>
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

            {/* Questions & Answers */}
            <div className="bg-gray-900/80 backdrop-blur-sm rounded-xl shadow-xl border border-gray-700/50 overflow-hidden">
              <div className="px-5 py-3 border-b border-gray-700/70">
                <div className="flex items-center gap-2 text-[13px] font-semibold text-white">
                  <FiActivity className="text-sm text-[#EFB078]" />
                  Questions &amp; Answers
                </div>
                <p className="text-[11px] text-gray-300 mt-0.5">Detailed analysis of each question</p>
              </div>
              <div className="px-5 py-4">
                <div className="max-h-[480px] space-y-2.5 overflow-y-auto pr-1 text-[12px] [scrollbar-width:thin] [&::-webkit-scrollbar]:w-2">
                  {attempt.questions?.map((question, index) => {
                    const answer = attempt.answers?.[index];
                    const isCorrect = answer?.isCorrect === 'true';
                    // Normalize identifiers for option comparison if options exist
                    const userAnswerId = typeof answer?.attemptedAnswer === 'object' ? answer?.attemptedAnswer?.id : answer?.attemptedAnswer;
                    const correctAnswerId = typeof question?.correctAnswer === 'object' ? question?.correctAnswer?.id : question?.correctAnswer;
                    return (
                      <div
                        key={`${question.questionNumber}-${index}`}
                        className={`p-3.5 rounded-lg border ${
                          isCorrect ? 'bg-green-900/20 border-green-700/50' : 'bg-red-900/20 border-red-700/50'
                        }`}
                      >
                        <div className="flex items-start justify-between mb-1.5">
                          <div className="flex items-center gap-1.5">
                            <span className="text-[13px] font-semibold text-white">Question {question.questionNumber}</span>
                            {answer?.duration && (
                              <span className="text-[10px] text-gray-300 bg-gray-800/50 px-1.5 py-0.5 rounded">
                                {formatDuration(answer.duration)}
                              </span>
                            )}
                          </div>
                          <span
                            className={`inline-flex items-center px-1.5 py-0.5 text-[10px] font-semibold rounded-full ${
                              isCorrect ? 'bg-green-900/50 text-green-200' : 'bg-red-900/50 text-red-200'
                            }`}
                          >
                            {isCorrect ? (
                              <>
                                <span className="text-green-400 text-sm font-bold mr-1">✓</span>Correct
                              </>
                            ) : (
                              <>
                                <span className="text-red-400 text-sm font-bold mr-1">✗</span>Incorrect
                              </>
                            )}
                          </span>
                        </div>
                        <p className="mt-1 text-[13px] text-gray-200 leading-relaxed">{question.question}</p>

                        {/* Options grid (if options available) */}
                        {!!question?.options?.length && (
                          <div className="mt-3">
                            <label className="block text-[10px] font-medium text-gray-400 mb-1">Options</label>
                            <div className="grid grid-cols-1 md:grid-cols-2 gap-1.5">
                              {question.options.map((option, optIdx) => {
                                const optionId = typeof option === 'object' ? option.id : option;
                                const optionLabel =
                                  typeof option === 'object'
                                    ? option.name || option.text || option.label || optionId
                                    : option;
                                const isCorrectOption =
                                  optionId === correctAnswerId || option === question.correctAnswer;
                                const isUserOption = optionId === userAnswerId || option === answer?.attemptedAnswer;
                                const baseClasses = 'p-1.5 rounded border flex items-center justify-between';
                                const colorClasses = isCorrectOption
                                  ? 'bg-green-900/30 border-green-600/50 text-green-300'
                                  : isUserOption
                                  ? 'bg-red-900/30 border-red-600/50 text-red-300'
                                  : 'bg-gray-800/30 border-gray-600/50 text-gray-300';
                                return (
                                  <div key={optIdx} className={`${baseClasses} ${colorClasses}`}>
                                    <span className="text-[12px]">{optionLabel}</span>
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

                        {/* Answers summary */}
                        <div className="mt-2.5 grid grid-cols-1 md:grid-cols-2 gap-2.5">
                          <div>
                            <label className="block text-[10px] font-medium text-gray-400 mb-1">Correct Answer</label>
                            <p className="text-[13px] font-semibold text-green-400">
                              {typeof question.correctAnswer === 'object'
                                ? question.correctAnswer?.name ||
                                  question.correctAnswer?.text ||
                                  question.correctAnswer?.label ||
                                  question.correctAnswer?.id
                                : question.correctAnswer || 'NA'}
                            </p>
                          </div>
                          <div>
                            <label className="block text-[10px] font-medium text-gray-400 mb-1">User's Answer</label>
                            <p className={`text-[13px] font-semibold ${isCorrect ? 'text-green-400' : 'text-red-400'}`}>
                              {answer?.attemptedAnswer
                                ? typeof answer.attemptedAnswer === 'object'
                                  ? answer.attemptedAnswer?.name ||
                                    answer.attemptedAnswer?.text ||
                                    answer.attemptedAnswer?.label ||
                                    answer.attemptedAnswer?.id
                                  : answer.attemptedAnswer
                                : 'Not answered'}
                            </p>
                          </div>
                        </div>
                      </div>
                    );
                  })}
                  {!attempt.questions?.length && (
                    <p className="text-center text-white/60">No question data available.</p>
                  )}
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

