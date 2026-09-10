import React, { useCallback, useEffect, useMemo, useState } from 'react';
import axios from 'axios';
import { useNavigate } from 'react-router-dom';
import {
  FiActivity,
  FiRefreshCw,
  FiSearch,
  FiTrash2,
  FiUsers
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

  const [attempts, setAttempts] = useState([]);
  const [searchTerm, setSearchTerm] = useState('');
  const [tableLoading, setTableLoading] = useState(true);
  const [tableError, setTableError] = useState('');
  const [deleteTarget, setDeleteTarget] = useState(null);
  const [deleteLoading, setDeleteLoading] = useState(false);

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
      const response = await axios.get(`${baseURL}/quizzes/stats`, {
        headers: { Authorization: `Bearer ${token}` }
      });
      const attendees = Array.isArray(response.data?.attendees) ? response.data.attendees : [];
      setAttempts(attendees);
    } catch (error) {
      console.error('Error fetching quiz attempts:', error);
      setTableError(error.response?.data?.message || 'Failed to load quiz attempts.');
    } finally {
      setTableLoading(false);
    }
  }, [baseURL, token]);

  useEffect(() => {
    fetchAttempts();
  }, [fetchAttempts]);

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
    <div className="flex min-h-screen bg-[#0b0614] text-white">
      <Sidebar currentPage="quizAttempts" onNavigate={handleNavigate} />

      <main className="ml-64 w-full bg-[#0f0a1d] px-6 py-8">
        <header className="mb-8 flex flex-col justify-between gap-4 rounded-2xl border border-white/5 bg-white/5/20 px-6 py-5 shadow-[0_20px_60px_rgba(10,7,18,0.55)] backdrop-blur">
          <div className="flex w-full flex-wrap items-center gap-4">
            <div>
              <p className="text-xs uppercase tracking-[0.35em] text-white/60">Analytics</p>
              <h1 className="text-2xl font-semibold text-white">Quiz Attempts</h1>
              <p className="text-sm text-white/70">
                Review participant submissions and inspect per-question performance.
              </p>
            </div>
            <div className="ml-auto flex items-center gap-3">
              <button
                onClick={fetchAttempts}
                className="inline-flex items-center gap-2 rounded-xl border border-white/10 bg-white/10 px-4 py-2 text-sm font-semibold text-white transition hover:border-[#EFB078]/60 hover:bg-[#701845]/30"
              >
                <FiRefreshCw className="text-base" />
                Refresh
              </button>
              <div className="flex items-center gap-2 rounded-xl border border-white/10 bg-white/5 px-3 py-2 text-xs font-semibold">
                <FiUsers className="text-base text-[#EFB078]" />
                {attempts.length} Attempts
              </div>
            </div>
          </div>
        </header>

        {tableError && (
          <div className="mb-6 rounded-2xl border border-red-500/40 bg-red-500/10 px-4 py-3 text-sm text-red-200">
            {tableError}
          </div>
        )}

        <section className="rounded-2xl border border-white/5 bg-gradient-to-b from-[#12091f]/90 to-[#0b0714]/95 p-5 shadow-[0_25px_60px_rgba(5,3,10,0.55)]">
            <div className="mb-4 flex flex-col gap-3 sm:flex-row sm:items-center">
              <div className="relative flex-1">
                <FiSearch className="pointer-events-none absolute left-3 top-1/2 -translate-y-1/2 text-white/40" />
                <input
                  type="text"
                  placeholder="Search by user name or ID"
                  className="w-full rounded-xl border border-white/10 bg-white/5 py-2 pl-10 pr-3 text-sm text-white placeholder:text-white/40 focus:border-[#EFB078] focus:outline-none"
                  value={searchTerm}
                  onChange={(event) => setSearchTerm(event.target.value)}
                />
              </div>
              <div className="flex items-center gap-2 rounded-xl border border-white/10 bg-white/5 px-3 py-2 text-xs text-white/70">
                <FiActivity className="text-base text-[#EFB078]" />
                Live data
              </div>
            </div>

            <div className="overflow-hidden rounded-2xl border border-white/5">
              <div className="max-h-[520px] overflow-y-auto [scrollbar-width:thin] [&::-webkit-scrollbar]:w-2">
                <table className="min-w-full divide-y divide-white/5 text-sm">
                  <thead className="bg-white/5 text-left text-xs uppercase tracking-wide text-white/60">
                    <tr>
                      <th className="px-4 py-3 font-semibold">Participant</th>
                      <th className="px-4 py-3 font-semibold">Score</th>
                      <th className="px-4 py-3 font-semibold">Percentage</th>
                      <th className="px-4 py-3 font-semibold">Duration</th>
                      <th className="px-4 py-3 font-semibold text-center">Actions</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-white/5">
                    {tableLoading && (
                      <tr>
                        <td colSpan={5} className="px-4 py-6 text-center text-white/60">
                          Loading attempts…
                        </td>
                      </tr>
                    )}
                    {!tableLoading && !filteredAttempts.length && (
                      <tr>
                        <td colSpan={5} className="px-4 py-6 text-center text-white/60">
                          No attempts found.
                        </td>
                      </tr>
                    )}
                    {!tableLoading &&
                      filteredAttempts.map((attempt) => {
                        return (
                          <tr
                            key={attempt.attemptId}
                            className="transition text-white/85 hover:bg-white/5"
                            onClick={() => handleViewAttempt(attempt.attemptId)}
                          >
                            <td className="px-4 py-3">
                              <div className="flex flex-col">
                                <span className="font-semibold">{attempt.name || 'Unknown'}</span>
                                <span className="text-xs text-white/60">{attempt.userId}</span>
                              </div>
                            </td>
                            <td className="px-4 py-3 font-semibold">{attempt.score}</td>
                            <td className="px-4 py-3">{attempt.percentage}%</td>
                            <td className="px-4 py-3">{formatDuration(attempt.duration)}</td>
                            <td className="px-4 py-3">
                              <button
                                type="button"
                                onClick={(event) => {
                                  event.stopPropagation();
                                  setDeleteTarget(attempt);
                                }}
                                className="flex items-center justify-center text-red-300 transition hover:text-red-200"
                                aria-label="Delete attempt"
                              >
                                <FiTrash2 size={18} />
                              </button>
                            </td>
                          </tr>
                        );
                      })}
                  </tbody>
                </table>
              </div>
            </div>
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


