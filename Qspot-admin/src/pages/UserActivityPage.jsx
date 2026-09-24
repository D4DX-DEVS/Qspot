import React, { useCallback, useEffect, useState } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import { FiArrowLeft } from 'react-icons/fi';
import Sidebar from '../components/Sidebar';
import PageHeader from '../components/ui/PageHeader';
import Spinner from '../components/ui/Spinner';
import ErrorState from '../components/ui/ErrorState';
import EmptyState from '../components/ui/EmptyState';
import usePageTitle from '../hooks/usePageTitle';
import apiClient from '../api/client';
import { formatDateTime } from '../utils/format';

// GET /api/admin/users/:id/activity -> { user, quizAttempts, videoQuizzes, progress, questions }
const UserActivityPage = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  usePageTitle(data?.user?.name ? `${data.user.name} · Activity` : 'User Activity');

  const fetchActivity = useCallback(async () => {
    try {
      setLoading(true);
      setError('');
      const response = await apiClient.get(`/admin/users/${id}/activity`);
      setData(response.data);
    } catch (err) {
      setError(err.message || 'Failed to load user activity');
    } finally {
      setLoading(false);
    }
  }, [id]);

  useEffect(() => {
    fetchActivity();
  }, [fetchActivity]);

  return (
    <div className="flex min-h-screen overflow-x-hidden bg-black">
      <Sidebar currentPage="users" onNavigate={navigate} />
      <div className="flex-1 flex flex-col w-full pb-28 md:ml-64 md:pb-0">
        <main className="flex-1 p-4 sm:p-6">
          <button
            type="button"
            onClick={() => navigate('/admin/dashboard')}
            className="mb-4 inline-flex items-center gap-2 text-xs font-semibold uppercase tracking-[0.2em] text-white/60 hover:text-[#EFB078]"
          >
            <FiArrowLeft size={14} /> Back to Users
          </button>

          {loading ? (
            <Spinner />
          ) : error ? (
            <ErrorState message={error} onRetry={fetchActivity} />
          ) : (
            <>
              <PageHeader
                title={data.user?.name || 'User'}
                description={[data.user?.phone, data.user?.class, data.user?.email].filter(Boolean).join(' · ')}
              />

              <div className="grid gap-6 lg:grid-cols-2">
                <section className="rounded-3xl border border-white/10 bg-white/5 p-5">
                  <h2 className="mb-3 text-sm font-semibold uppercase tracking-[0.2em] text-white/60">
                    Quiz Attempts
                  </h2>
                  {data.quizAttempts?.length ? (
                    <ul className="space-y-2">
                      {data.quizAttempts.map((a) => (
                        <li
                          key={a.attemptId}
                          className="cursor-pointer rounded-xl border border-white/10 bg-black/30 px-4 py-3 text-sm text-white/85 hover:border-[#EFB078]/40"
                          onClick={() => navigate(`/admin/quiz/attempts/${a.attemptId}`)}
                        >
                          <div className="flex items-center justify-between">
                            <span className="font-medium">{a.title || 'Quiz'}</span>
                            <span className="text-[#EFB078]">{a.percentage}%</span>
                          </div>
                          <div className="mt-1 text-xs text-white/40">{formatDateTime(a.createdAt)}</div>
                        </li>
                      ))}
                    </ul>
                  ) : (
                    <EmptyState title="No quiz attempts yet" />
                  )}
                </section>

                <section className="rounded-3xl border border-white/10 bg-white/5 p-5">
                  <h2 className="mb-3 text-sm font-semibold uppercase tracking-[0.2em] text-white/60">
                    Video Quizzes
                  </h2>
                  {data.videoQuizzes?.length ? (
                    <ul className="space-y-2">
                      {data.videoQuizzes.map((v) => (
                        <li
                          key={v.videoId}
                          className="rounded-xl border border-white/10 bg-black/30 px-4 py-3 text-sm text-white/85"
                        >
                          <div className="flex items-center justify-between">
                            <span className="font-medium">{v.title || 'Video'}</span>
                            <span className="text-[#EFB078]">{v.percentage}%</span>
                          </div>
                          <div className="mt-1 text-xs text-white/40">{formatDateTime(v.createdAt)}</div>
                        </li>
                      ))}
                    </ul>
                  ) : (
                    <EmptyState title="No video quizzes yet" />
                  )}
                </section>

                <section className="rounded-3xl border border-white/10 bg-white/5 p-5">
                  <h2 className="mb-3 text-sm font-semibold uppercase tracking-[0.2em] text-white/60">
                    Video Progress
                  </h2>
                  {data.progress?.length ? (
                    <ul className="space-y-2">
                      {data.progress.map((p) => (
                        <li
                          key={p.videoId}
                          className="rounded-xl border border-white/10 bg-black/30 px-4 py-3 text-sm text-white/85"
                        >
                          <div className="flex items-center justify-between">
                            <span className="font-medium">{p.title || 'Video'}</span>
                            <span
                              className={
                                p.status === 'completed' ? 'text-green-300' : 'text-white/50'
                              }
                            >
                              {p.status}
                            </span>
                          </div>
                        </li>
                      ))}
                    </ul>
                  ) : (
                    <EmptyState title="No video activity yet" />
                  )}
                </section>

                <section className="rounded-3xl border border-white/10 bg-white/5 p-5">
                  <h2 className="mb-3 text-sm font-semibold uppercase tracking-[0.2em] text-white/60">
                    Q&amp;A
                  </h2>
                  {data.questions?.length ? (
                    <ul className="space-y-2">
                      {data.questions.map((q) => (
                        <li
                          key={q._id}
                          className="rounded-xl border border-white/10 bg-black/30 px-4 py-3 text-sm text-white/85"
                        >
                          {q.description}
                        </li>
                      ))}
                    </ul>
                  ) : (
                    <EmptyState title="No questions asked yet" />
                  )}
                </section>
              </div>
            </>
          )}
        </main>
      </div>
    </div>
  );
};

export default UserActivityPage;
