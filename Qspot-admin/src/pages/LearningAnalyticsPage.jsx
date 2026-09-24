import React, { useCallback, useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { FiActivity, FiRefreshCw, FiSearch, FiUsers } from 'react-icons/fi';
import Sidebar from '../components/Sidebar';
import PageHeader from '../components/ui/PageHeader';
import Spinner from '../components/ui/Spinner';
import ErrorState from '../components/ui/ErrorState';
import EmptyState from '../components/ui/EmptyState';
import usePageTitle from '../hooks/usePageTitle';
import apiClient from '../api/client';

const card = 'rounded-2xl border border-white/10 bg-white/[0.04] p-4';

const LearningAnalyticsPage = () => {
  usePageTitle('Learning Analytics');
  const navigate = useNavigate();
  const [data, setData] = useState(null);
  const [classFilter, setClassFilter] = useState('');
  const [videoId, setVideoId] = useState('');
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  const load = useCallback(async () => {
    setLoading(true);
    setError('');
    try {
      const response = await apiClient.get('/admin/analytics/overview', { params: { class: classFilter || undefined, videoId: videoId || undefined } });
      setData(response.data);
    } catch (err) {
      setError(err.message || 'Could not load learning analytics.');
    } finally {
      setLoading(false);
    }
  }, [classFilter, videoId]);

  useEffect(() => { load(); }, [load]);

  return (
    <div className="flex min-h-screen overflow-x-hidden bg-black">
      <Sidebar currentPage="analytics" onNavigate={navigate} />
      <main className="flex-1 p-4 pb-28 md:ml-64 md:p-8 md:pb-8">
        <PageHeader eyebrow="TEACHER VIEW" title="Learning analytics" description="See who started, finished, read notes, needs practice, or has submitted work." actions={<button type="button" onClick={load} className="inline-flex items-center gap-2 rounded-xl border border-white/10 bg-white/5 px-3.5 py-2.5 text-sm font-semibold text-white/80"><FiRefreshCw /> Refresh</button>} />
        <div className="mb-5 flex flex-col gap-3 sm:flex-row">
          <label className="relative flex-1"><FiSearch className="pointer-events-none absolute left-3 top-1/2 -translate-y-1/2 text-white/35" /><input value={classFilter} onChange={(event) => setClassFilter(event.target.value)} placeholder="Filter by class" className="w-full rounded-xl border border-white/10 bg-white/5 py-3 pl-9 pr-4 text-sm text-white placeholder-white/35 outline-none" /></label>
          <select value={videoId} onChange={(event) => setVideoId(event.target.value)} className="rounded-xl border border-white/10 bg-[#160b17] px-3 py-3 text-sm text-white outline-none sm:min-w-72"><option value="">All lessons</option>{data?.videos?.map((video) => <option key={video._id} value={video._id}>{video.title}</option>)}</select>
        </div>
        {loading ? <Spinner /> : error ? <ErrorState message={error} onRetry={load} /> : !data ? <EmptyState icon={FiActivity} title="No analytics yet" /> : <>
          <div className="mb-6 grid gap-3 sm:grid-cols-2 lg:grid-cols-7">{[['Learners', data.totals.learners], ['Started', data.totals.started], ['Completed', data.totals.completed], ['Notes read', data.totals.notesRead], ['Practice ready', data.totals.practiceReady], ['Submissions', data.totals.submittedAssignments], ['Overdue', data.totals.overdueAssignments]].map(([label, value]) => <div className={card} key={label}><p className="text-[10px] uppercase tracking-[0.18em] text-white/45">{label}</p><p className="mt-1 text-2xl font-semibold text-white">{value}</p></div>)}</div>
          <section className="overflow-hidden rounded-2xl border border-white/10 bg-white/[0.03]"><div className="flex items-center gap-2 border-b border-white/10 px-4 py-4"><FiUsers className="text-[#EFB078]" /><h2 className="text-sm font-semibold text-white">Learner roster</h2></div>{data.learners?.length ? <div className="overflow-x-auto"><table className="min-w-full text-left text-sm"><thead className="bg-white/[0.03] text-[10px] uppercase tracking-[0.15em] text-white/40"><tr><th className="px-4 py-3">Learner</th><th className="px-4 py-3">Class</th><th className="px-4 py-3">Started</th><th className="px-4 py-3">Completed</th><th className="px-4 py-3">Notes</th><th className="px-4 py-3">Practice</th><th className="px-4 py-3">Submissions</th><th className="px-4 py-3">Overdue</th></tr></thead><tbody className="divide-y divide-white/10">{data.learners.map((learner) => <tr key={learner.id} className="text-white/80"><td className="px-4 py-3 font-medium">{learner.name || 'Unnamed'}</td><td className="px-4 py-3 text-white/55">{learner.class || '—'}</td><td className="px-4 py-3">{learner.started}</td><td className="px-4 py-3">{learner.completed}</td><td className="px-4 py-3">{learner.notesRead}</td><td className="px-4 py-3 text-amber-200">{learner.practiceReady}</td><td className="px-4 py-3">{learner.submittedAssignments}</td><td className="px-4 py-3 text-red-200">{learner.overdueAssignments}</td></tr>)}</tbody></table></div> : <div className="p-6"><EmptyState icon={FiUsers} title="No learners match this filter" /></div>}</section>
        </>}
      </main>
    </div>
  );
};

export default LearningAnalyticsPage;
