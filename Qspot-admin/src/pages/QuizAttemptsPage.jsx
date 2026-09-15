import React, { useCallback, useEffect, useMemo, useState } from 'react';
import axios from 'axios';
import { useNavigate, useSearchParams } from 'react-router-dom';
import {
  FiActivity,
  FiRefreshCw,
  FiSearch,
  FiTrash2,
  FiUsers,
  FiArrowLeft,
  FiFilter,
  FiAward
} from 'react-icons/fi';
import Sidebar from '../components/Sidebar';
import ConfirmDialog from '../components/dialogs/ConfirmDialog';

const formatDuration = (seconds) => {
  const value = Number(seconds);
  if (Number.isNaN(value) || value < 0) return '0s';
  const mins = Math.floor(value / 60);
  const secs = Math.floor(value % 60);
  if (mins <= 0) return `${secs}s`;
  return `${mins}m ${secs.toString().padStart(2, '0')}s`;
};

const QuizAttemptsPage = () => {
  const baseURL = import.meta.env.VITE_API_BASE_URL;
  const token = useMemo(() => localStorage.getItem('adminToken'), []);
  const navigate = useNavigate();
  const [searchParams, setSearchParams] = useSearchParams();
  const quizId = searchParams.get('quizId');

  const [attempts, setAttempts] = useState([]);
  const [quizOptions, setQuizOptions] = useState([]);
  const [searchTerm, setSearchTerm] = useState('');
  const [tableLoading, setTableLoading] = useState(true);
  const [tableError, setTableError] = useState('');
  const [deleteTarget, setDeleteTarget] = useState(null);
  const [deleteLoading, setDeleteLoading] = useState(false);
  const [scopedQuiz, setScopedQuiz] = useState(null);

  const [fromDate, setFromDate] = useState('');
  const [toDate, setToDate] = useState('');
  const [minScore, setMinScore] = useState('');
  const [maxScore, setMaxScore] = useState('');
  const [page, setPage] = useState(1);
  const [total, setTotal] = useState(0);
  const limit = 20;
  const totalPages = Math.max(1, Math.ceil(total / limit));

  const handleNavigate = (path) => {
    window.location.href = path;
  };

  const fetchAttempts = useCallback(async () => {
    if (!baseURL || !token) {
      setTableError('Missing configuration or authentication token.');
      setTableLoading(false);
      return;
    }
    try {
      setTableLoading(true);
      setTableError('');
      const params = { page, limit };
      if (fromDate) params.from = fromDate;
      if (toDate) params.to = toDate;
      if (minScore !== '') params.minScore = minScore;
      if (maxScore !== '') params.maxScore = maxScore;

      if (quizId) {
        const response = await axios.get(`${baseURL}/quiz-definitions/${quizId}/results`, {
          headers: { Authorization: `Bearer ${token}` },
          params
        });
        setAttempts(Array.isArray(response.data?.items) ? response.data.items : []);
        setTotal(response.data?.total || 0);
      } else {
        const response = await axios.get(`${baseURL}/quizzes/stats`, {
          headers: { Authorization: `Bearer ${token}` },
          params
        });
        setAttempts(Array.isArray(response.data?.attendees) ? response.data.attendees : []);
        setTotal(response.data?.total || 0);
      }
    } catch (error) {
      console.error('Error fetching quiz attempts:', error);
      setTableError(error.response?.data?.message || 'Failed to load quiz attempts.');
    } finally {
      setTableLoading(false);
    }
  }, [baseURL, token, quizId, fromDate, toDate, minScore, maxScore, page]);

  useEffect(() => {
    fetchAttempts();
  }, [fetchAttempts]);

  useEffect(() => {
    setPage(1);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [quizId, fromDate, toDate, minScore, maxScore]);

  useEffect(() => {
    if (!quizId || !baseURL || !token) {
      setScopedQuiz(null);
      return;
    }
    axios
      .get(`${baseURL}/quiz-definitions/${quizId}`, { headers: { Authorization: `Bearer ${token}` } })
      .then((response) => setScopedQuiz(response.data))
      .catch((error) => console.error('Error fetching quiz:', error));
  }, [quizId, baseURL, token]);

  // Populates the Quiz filter dropdown from the existing quiz list endpoint.
  useEffect(() => {
    if (!baseURL || !token) return;
    axios
      .get(`${baseURL}/quiz-definitions`, {
        headers: { Authorization: `Bearer ${token}` },
        params: { limit: 100 }
      })
      .then((response) => setQuizOptions(Array.isArray(response.data?.items) ? response.data.items : []))
      .catch((error) => console.error('Error fetching quiz list:', error));
  }, [baseURL, token]);

  const handleQuizFilterChange = (value) => {
    if (value) {
      setSearchParams({ quizId: value });
    } else {
      setSearchParams({});
    }
  };

  const filteredAttempts = useMemo(() => {
    if (!searchTerm.trim()) return attempts;
    const query = searchTerm.trim().toLowerCase();
    return attempts.filter((item) => {
      return (
        item.name?.toLowerCase().includes(query) ||
        item.userId?.toString().toLowerCase().includes(query)
      );
    });
  }, [attempts, searchTerm]);

  const handleViewAttempt = (attemptId) => {
    navigate(`/admin/quiz/attempts/${attemptId}`);
  };

  const handleDeleteAttempt = async () => {
    if (!deleteTarget || !baseURL || !token) return;
    try {
      setDeleteLoading(true);
      await axios.delete(`${baseURL}/quizzes/attempt/${deleteTarget.attemptId}`, {
        headers: { Authorization: `Bearer ${token}` }
      });
      setDeleteTarget(null);
      fetchAttempts();
    } catch (error) {
      console.error('Error deleting quiz attempt:', error);
      setTableError(error.response?.data?.message || 'Failed to delete quiz attempt.');
    } finally {
      setDeleteLoading(false);
    }
  };

  return (
    <div className="flex min-h-screen overflow-x-hidden bg-[#0b0614] text-white">
      <Sidebar currentPage="quizAttempts" onNavigate={handleNavigate} />

      <main className="w-full bg-[#0f0a1d] px-4 py-8 pb-28 sm:px-6 md:ml-64 md:pb-8">
        <header className="mb-8 flex flex-col justify-between gap-4 rounded-2xl border border-white/5 bg-white/5/20 px-4 py-5 shadow-[0_20px_60px_rgba(10,7,18,0.55)] backdrop-blur sm:px-6">
          <div className="flex w-full flex-col flex-wrap items-start gap-4 sm:flex-row sm:items-center">
            <div>
              {quizId && (
                <button
                  type="button"
                  onClick={() => navigate('/admin/quizzes')}
                  className="mb-2 inline-flex items-center gap-2 text-xs font-semibold uppercase tracking-[0.2em] text-white/60 hover:text-[#EFB078] transition"
                >
                  <FiArrowLeft size={14} /> Back to Quizzes
                </button>
              )}
              <p className="text-xs uppercase tracking-[0.35em] text-white/60">Analytics</p>
              <h1 className="text-xl font-semibold text-white sm:text-2xl">
                {quizId ? `${scopedQuiz?.title || 'Quiz'} — Results` : 'Quiz Attempts'}
              </h1>
              <p className="text-sm text-white/70">
                Review participant submissions and inspect per-question performance.
              </p>
            </div>
            <div className="flex w-full items-center gap-3 sm:ml-auto sm:w-auto">
              <button
                onClick={fetchAttempts}
                className="inline-flex items-center gap-2 rounded-xl border border-white/10 bg-white/10 px-4 py-2 text-sm font-semibold text-white transition hover:border-[#EFB078]/60 hover:bg-[#701845]/30"
              >
                <FiRefreshCw className="text-base" />
                Refresh
              </button>
              <div className="flex items-center gap-2 rounded-xl border border-white/10 bg-white/5 px-3 py-2 text-xs font-semibold">
                <FiUsers className="text-base text-[#EFB078]" />
                {total} Attempts
              </div>
            </div>
          </div>
        </header>

        {tableError && (
          <div className="mb-6 rounded-2xl border border-red-500/40 bg-red-500/10 px-4 py-3 text-sm text-red-200">
            {tableError}
          </div>
        )}

        <section className="rounded-2xl border border-white/5 bg-gradient-to-b from-[#12091f]/90 to-[#0b0714]/95 p-4 shadow-[0_25px_60px_rgba(5,3,10,0.55)] sm:p-5">
            <div className="mb-4 flex flex-col gap-3 sm:flex-row sm:items-center">
              <label className="flex flex-col gap-2 text-xs font-semibold text-white/70 sm:flex-row sm:items-center">
                Quiz
                <select
                  value={quizId || ''}
                  onChange={(event) => handleQuizFilterChange(event.target.value)}
                  className="w-full rounded-xl border border-white/10 bg-[#0d0711] px-3 py-2.5 text-sm text-white focus:border-[#EFB078] focus:outline-none sm:w-auto sm:py-2"
                >
                  <option value="" style={{ backgroundColor: '#0d0711', color: '#ffffff' }}>
                    All Quizzes
                  </option>
                  {quizOptions.map((quiz) => (
                    <option
                      key={quiz._id}
                      value={quiz._id}
                      style={{ backgroundColor: '#0d0711', color: '#ffffff' }}
                    >
                      {quiz.title || 'Legacy Quiz'}
                    </option>
                  ))}
                </select>
              </label>
              <div className="relative w-full sm:flex-1">
                <FiSearch className="pointer-events-none absolute left-3 top-1/2 -translate-y-1/2 text-white/40" />
                <input
                  type="text"
                  placeholder="Search by user name or ID"
                  className="w-full rounded-xl border border-white/10 bg-white/5 py-2.5 pl-10 pr-3 text-sm text-white placeholder:text-white/40 focus:border-[#EFB078] focus:outline-none sm:py-2"
                  value={searchTerm}
                  onChange={(event) => setSearchTerm(event.target.value)}
                />
              </div>
              <div className="flex w-full items-center justify-center gap-2 rounded-xl border border-white/10 bg-white/5 px-3 py-2 text-xs text-white/70 sm:w-auto">
                <FiActivity className="text-base text-[#EFB078]" />
                Live data
              </div>
            </div>

            {quizId && (
              <div className="mb-4 flex flex-wrap items-center gap-3 rounded-xl border border-white/10 bg-white/5 px-4 py-3">
                <div className="flex items-center gap-2 text-xs font-semibold uppercase tracking-[0.2em] text-white/60">
                  <FiFilter /> Filters
                </div>
                <label className="flex items-center gap-2 text-xs text-white/70">
                  From
                  <input
                    type="datetime-local"
                    value={fromDate}
                    onChange={(e) => setFromDate(e.target.value)}
                    className="rounded-lg border border-white/10 bg-black/30 px-2 py-1 text-white focus:border-[#EFB078] focus:outline-none"
                  />
                </label>
                <label className="flex items-center gap-2 text-xs text-white/70">
                  To
                  <input
                    type="datetime-local"
                    value={toDate}
                    onChange={(e) => setToDate(e.target.value)}
                    className="rounded-lg border border-white/10 bg-black/30 px-2 py-1 text-white focus:border-[#EFB078] focus:outline-none"
                  />
                </label>
                <label className="flex items-center gap-2 text-xs text-white/70">
                  Min score
                  <input
                    type="text"
                    inputMode="numeric"
                    value={minScore}
                    onChange={(e) => setMinScore(e.target.value.replace(/\D/g, ''))}
                    className="w-16 rounded-lg border border-white/10 bg-black/30 px-2 py-1 text-white focus:border-[#EFB078] focus:outline-none"
                  />
                </label>
                <label className="flex items-center gap-2 text-xs text-white/70">
                  Max score
                  <input
                    type="text"
                    inputMode="numeric"
                    value={maxScore}
                    onChange={(e) => setMaxScore(e.target.value.replace(/\D/g, ''))}
                    className="w-16 rounded-lg border border-white/10 bg-black/30 px-2 py-1 text-white focus:border-[#EFB078] focus:outline-none"
                  />
                </label>
              </div>
            )}

            <div className="overflow-hidden rounded-2xl border border-white/5">
              <div className="max-h-[520px] overflow-x-auto overflow-y-auto [scrollbar-width:thin] [&::-webkit-scrollbar]:h-2 [&::-webkit-scrollbar]:w-2">
                <table className="w-full min-w-[640px] divide-y divide-white/5 text-sm">
                  <thead className="bg-white/5 text-left text-xs uppercase tracking-wide text-white/60">
                    <tr>
                      <th className="px-3 py-2 font-semibold">Rank</th>
                      <th className="px-3 py-2 font-semibold">Participant</th>
                      <th className="px-3 py-2 font-semibold">Score</th>
                      <th className="px-3 py-2 font-semibold">Percentage</th>
                      <th className="px-3 py-2 font-semibold">Time Taken</th>
                      <th className="px-3 py-2 font-semibold text-center">Actions</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-white/5">
                    {tableLoading && (
                      <tr>
                        <td colSpan={6} className="px-4 py-6 text-center text-white/60">
                          Loading attempts…
                        </td>
                      </tr>
                    )}
                    {!tableLoading && !filteredAttempts.length && (
                      <tr>
                        <td colSpan={6} className="px-4 py-6 text-center text-white/60">
                          No attempts found.
                        </td>
                      </tr>
                    )}
                    {!tableLoading &&
                      filteredAttempts.map((attempt) => {
                        const rank = attempt.rank;
                        const isTop3 = rank && rank <= 3;
                        const medalColor =
                          rank === 1 ? 'text-[#EFB078]' : rank === 2 ? 'text-white/70' : 'text-[#9E4B63]';
                        return (
                          <tr
                            key={attempt.attemptId}
                            className={`transition text-white/85 hover:bg-white/5 ${
                              isTop3 ? 'bg-gradient-to-r from-[#EFB078]/10 via-transparent to-transparent' : ''
                            }`}
                            onClick={() => handleViewAttempt(attempt.attemptId)}
                          >
                            <td className="px-3 py-2 font-semibold">
                              {isTop3 ? (
                                <span className={`inline-flex items-center gap-1 ${medalColor}`} title={`Rank ${rank}`}>
                                  <FiAward size={14} /> {rank}
                                </span>
                              ) : (
                                <span className="text-white/60">{rank ?? '—'}</span>
                              )}
                            </td>
                            <td className="px-3 py-2">
                              <div className="flex flex-col">
                                <span className="font-semibold">{attempt.name || 'Unknown'}</span>
                                <span className="text-[11px] text-white/60">{attempt.userId}</span>
                              </div>
                            </td>
                            <td className="px-3 py-2 font-semibold">{attempt.score}</td>
                            <td className="px-3 py-2">{attempt.percentage}%</td>
                            <td className="px-3 py-2">{formatDuration(attempt.duration)}</td>
                            <td className="px-3 py-2">
                              <button
                                type="button"
                                onClick={(event) => {
                                  event.stopPropagation();
                                  setDeleteTarget(attempt);
                                }}
                                title="Delete attempt"
                                className="flex h-9 w-9 items-center justify-center rounded-lg text-red-300 transition hover:bg-red-500/10 hover:text-red-200"
                                aria-label="Delete attempt"
                              >
                                <FiTrash2 size={15} />
                              </button>
                            </td>
                          </tr>
                        );
                      })}
                  </tbody>
                </table>
              </div>
            </div>

            {!tableLoading && totalPages > 1 && (
              <div className="mt-4 flex items-center justify-center gap-3 text-xs text-white/60">
                <button
                  onClick={() => setPage((p) => Math.max(1, p - 1))}
                  disabled={page === 1}
                  className="rounded-lg border border-white/10 bg-white/5 px-3 py-1 disabled:opacity-40"
                >
                  Prev
                </button>
                <span>
                  Page {page} of {totalPages}
                </span>
                <button
                  onClick={() => setPage((p) => Math.min(totalPages, p + 1))}
                  disabled={page === totalPages}
                  className="rounded-lg border border-white/10 bg-white/5 px-3 py-1 disabled:opacity-40"
                >
                  Next
                </button>
              </div>
            )}
        </section>
      </main>
      {deleteTarget && (
        <ConfirmDialog
          title="Delete Quiz Attempt"
          description="This will permanently remove the selected quiz attempt. This action cannot be undone."
          confirmLabel={deleteLoading ? 'Deleting…' : 'Delete'}
          cancelLabel="Cancel"
          confirmVariant="danger"
          onCancel={() => (!deleteLoading ? setDeleteTarget(null) : null)}
          onConfirm={() => {
            if (!deleteLoading) {
              handleDeleteAttempt();
            }
          }}
        />
      )}
    </div>
  );
};

export default QuizAttemptsPage;


