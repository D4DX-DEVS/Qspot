import React, { useCallback, useEffect, useMemo, useState } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import { FiActivity, FiRefreshCw, FiSearch, FiTrash2, FiUsers, FiArrowLeft, FiFilter, FiAward } from 'react-icons/fi';
import Sidebar from '../components/Sidebar';
import ConfirmDialog from '../components/dialogs/ConfirmDialog';
import ErrorState from '../components/ui/ErrorState';
import Pagination from '../components/ui/Pagination';
import usePageTitle from '../hooks/usePageTitle';
import apiClient from '../api/client';
import { formatDuration } from '../utils/format';

// Attempts are always scoped to one quiz (CONTRACT.md removed the unscoped
// /api/quizzes/stats endpoint). When no ?quizId is present we show a quiz
// picker instead of a table; the picker loads every quiz page so it can be
// searched client-side (the admin quiz list endpoint has no search param).
const QuizAttemptsPage = () => {
  const navigate = useNavigate();
  const [searchParams, setSearchParams] = useSearchParams();
  const quizId = searchParams.get('quizId');

  const [attempts, setAttempts] = useState([]);
  const [quizOptions, setQuizOptions] = useState([]);
  const [quizOptionsLoading, setQuizOptionsLoading] = useState(true);
  const [quizPickerSearch, setQuizPickerSearch] = useState('');
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

  usePageTitle(quizId ? `${scopedQuiz?.title || 'Quiz'} · Attempts` : 'Quiz Attempts');

  // Load every quiz (paging until the server says there are no more) so the
  // picker can be filtered client-side by title.
  useEffect(() => {
    let cancelled = false;
    const loadAll = async () => {
      setQuizOptionsLoading(true);
      const collected = [];
      let p = 1;
      // Safety cap: 50 pages * 50 = 2500 quizzes, far beyond realistic use.
      for (; p <= 50; p += 1) {
        try {
          const response = await apiClient.get('/quiz-definitions', { params: { page: p, limit: 50 } });
          const items = Array.isArray(response.data?.items) ? response.data.items : [];
          collected.push(...items);
          const totalCount = response.data?.total || 0;
          if (collected.length >= totalCount || items.length === 0) break;
        } catch {
          break;
        }
      }
      if (!cancelled) {
        setQuizOptions(collected);
        setQuizOptionsLoading(false);
      }
    };
    loadAll();
    return () => {
      cancelled = true;
    };
  }, []);

  const fetchAttempts = useCallback(async () => {
    if (!quizId) {
      setAttempts([]);
      setTotal(0);
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
      if (searchTerm.trim()) params.search = searchTerm.trim();

      const response = await apiClient.get(`/quiz-definitions/${quizId}/results`, { params });
      setAttempts(Array.isArray(response.data?.items) ? response.data.items : []);
      setTotal(response.data?.total || 0);
    } catch (error) {
      setTableError(error.message || 'Failed to load quiz attempts.');
    } finally {
      setTableLoading(false);
    }
  }, [quizId, fromDate, toDate, minScore, maxScore, searchTerm, page]);

  useEffect(() => {
    fetchAttempts();
  }, [fetchAttempts]);

  useEffect(() => {
    setPage(1);
  }, [quizId, fromDate, toDate, minScore, maxScore, searchTerm]);

  useEffect(() => {
    if (!quizId) {
      setScopedQuiz(null);
      return;
    }
    apiClient
      .get(`/quiz-definitions/${quizId}`)
      .then((response) => setScopedQuiz(response.data))
      .catch(() => setScopedQuiz(null));
  }, [quizId]);

  const handleSelectQuiz = (id) => {
    if (id) {
      setSearchParams({ quizId: id });
    } else {
      setSearchParams({});
    }
  };

  const filteredQuizOptions = useMemo(() => {
    const query = quizPickerSearch.trim().toLowerCase();
    if (!query) return quizOptions;
    return quizOptions.filter((q) => (q.title || '').toLowerCase().includes(query));
  }, [quizOptions, quizPickerSearch]);

  const handleViewAttempt = (attemptId) => navigate(`/admin/quiz/attempts/${attemptId}`);

  const handleDeleteAttempt = async () => {
    if (!deleteTarget) return;
    try {
      setDeleteLoading(true);
      await apiClient.delete(`/quizzes/attempt/${deleteTarget.attemptId}`);
      setDeleteTarget(null);
      fetchAttempts();
    } catch (error) {
      setTableError(error.message || 'Failed to delete quiz attempt.');
    } finally {
      setDeleteLoading(false);
    }
  };

  return (
    <div className="flex min-h-screen overflow-x-hidden bg-[#0b0614] text-white">
      <Sidebar currentPage="quizAttempts" onNavigate={navigate} />

      <main className="w-full bg-[#0f0a1d] px-4 py-8 pb-28 sm:px-6 md:ml-64 md:pb-8">
        <header className="mb-8 flex flex-col justify-between gap-4 rounded-2xl border border-white/5 bg-white/5 px-4 py-5 shadow-[0_20px_60px_rgba(10,7,18,0.55)] backdrop-blur sm:px-6">
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
              <p className="text-sm text-white/70">Pick a quiz to review participant submissions.</p>
            </div>
            {quizId && (
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
            )}
          </div>
        </header>

        <section className="rounded-2xl border border-white/5 bg-gradient-to-b from-[#12091f]/90 to-[#0b0714]/95 p-4 shadow-[0_25px_60px_rgba(5,3,10,0.55)] sm:p-5">
          <div className="mb-4 flex flex-col gap-3 sm:flex-row sm:items-center">
            <div className="relative w-full sm:max-w-xs">
              <FiSearch className="pointer-events-none absolute left-3 top-1/2 -translate-y-1/2 text-white/40" />
              <input
                type="text"
                placeholder={quizOptionsLoading ? 'Loading quizzes…' : 'Search quiz by title'}
                className="w-full rounded-xl border border-white/10 bg-white/5 py-2.5 pl-10 pr-3 text-sm text-white placeholder:text-white/40 focus:border-[#EFB078] focus:outline-none"
                value={quizPickerSearch}
                onChange={(e) => setQuizPickerSearch(e.target.value)}
              />
            </div>
            <select
              value={quizId || ''}
              onChange={(event) => handleSelectQuiz(event.target.value)}
              className="w-full rounded-xl border border-white/10 bg-[#0d0711] px-3 py-2.5 text-sm text-white focus:border-[#EFB078] focus:outline-none sm:w-auto"
            >
              <option value="">Select a quiz…</option>
              {filteredQuizOptions.map((quiz) => (
                <option key={quiz._id} value={quiz._id}>
                  {quiz.title}
                </option>
              ))}
            </select>
          </div>

          {!quizId ? (
            <div className="rounded-2xl border border-dashed border-white/15 bg-white/5 px-6 py-12 text-center text-white/60">
              Select a quiz above to see its attempts.
            </div>
          ) : (
            <>
              {tableError && !tableLoading && (
                <div className="mb-4">
                  <ErrorState message={tableError} onRetry={fetchAttempts} />
                </div>
              )}

              <div className="mb-4 flex flex-col gap-3 sm:flex-row sm:items-center">
                <div className="relative w-full sm:flex-1">
                  <FiSearch className="pointer-events-none absolute left-3 top-1/2 -translate-y-1/2 text-white/40" />
                  <input
                    type="text"
                    placeholder="Search by user name"
                    className="w-full rounded-xl border border-white/10 bg-white/5 py-2.5 pl-10 pr-3 text-sm text-white placeholder:text-white/40 focus:border-[#EFB078] focus:outline-none"
                    value={searchTerm}
                    onChange={(event) => setSearchTerm(event.target.value)}
                  />
                </div>
                <div className="flex w-full items-center justify-center gap-2 rounded-xl border border-white/10 bg-white/5 px-3 py-2 text-xs text-white/70 sm:w-auto">
                  <FiActivity className="text-base text-[#EFB078]" />
                  Live data
                </div>
              </div>

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
                      {!tableLoading && !attempts.length && (
                        <tr>
                          <td colSpan={6} className="px-4 py-6 text-center text-white/60">
                            No attempts found.
                          </td>
                        </tr>
                      )}
                      {!tableLoading &&
                        attempts.map((attempt) => {
                          const rank = attempt.rank;
                          const isTop3 = rank && rank <= 3;
                          const medalColor = rank === 1 ? 'text-[#EFB078]' : rank === 2 ? 'text-white/70' : 'text-[#9E4B63]';
                          return (
                            <tr
                              key={attempt.attemptId}
                              className={`cursor-pointer transition text-white/85 hover:bg-white/5 ${
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
                                  <span
                                    className="font-semibold hover:underline"
                                    onClick={(e) => {
                                      e.stopPropagation();
                                      navigate(`/admin/users/${attempt.userId}`);
                                    }}
                                  >
                                    {attempt.name || 'Unknown'}
                                  </span>
                                  <span className="text-[11px] text-white/60">{attempt.class}</span>
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

              {!tableLoading && (
                <Pagination page={page} totalPages={totalPages} total={total} onChange={setPage} label="attempts" />
              )}
            </>
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
