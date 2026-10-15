import React, { useCallback, useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { FiCheckCircle, FiGrid } from 'react-icons/fi';
import Sidebar from '../components/Sidebar';
import PageHeader from '../components/ui/PageHeader';
import Spinner from '../components/ui/Spinner';
import ErrorState from '../components/ui/ErrorState';
import EmptyState from '../components/ui/EmptyState';
import GradebookFilters from '../components/grading/GradebookFilters';
import SubmissionPanel from '../components/grading/SubmissionPanel';
import usePageTitle from '../hooks/usePageTitle';
import apiClient from '../api/client';

const when = (date) => (date ? new Date(date).toLocaleString(undefined, { day: 'numeric', month: 'short', hour: 'numeric', minute: '2-digit' }) : '');
const typing = (target) => ['INPUT', 'TEXTAREA', 'SELECT'].includes(target?.tagName);

// Work waiting for a mark, oldest first, opened one at a time. J and K move
// through the list; saving moves on to the next.
const MarkWorkPage = () => {
  usePageTitle('Mark work');
  const navigate = useNavigate();
  const [cls, setCls] = useState('');
  const [courseId, setCourseId] = useState('');
  const [items, setItems] = useState([]);
  const [total, setTotal] = useState(0);
  const [index, setIndex] = useState(0);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  const load = useCallback(async () => {
    setLoading(true);
    setError('');
    try {
      const response = await apiClient.get('/admin/gradebook/queue', { params: { class: cls || undefined, courseId: courseId || undefined } });
      setItems(response.data.items || []);
      setTotal(response.data.total || 0);
      setIndex(0);
    } catch (err) {
      setError(err.message || 'Could not load the work to mark.');
    } finally {
      setLoading(false);
    }
  }, [cls, courseId]);

  useEffect(() => { load(); }, [load]);

  useEffect(() => {
    const onKey = (event) => {
      if (typing(event.target) || event.metaKey || event.ctrlKey || event.altKey) return;
      if (event.key === 'j') setIndex((i) => Math.min(i + 1, Math.max(items.length - 1, 0)));
      if (event.key === 'k') setIndex((i) => Math.max(i - 1, 0));
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [items.length]);

  // Marked or returned: it leaves the queue and the next one opens.
  const done = () => {
    setItems((current) => current.filter((_, i) => i !== index));
    setTotal((t) => Math.max(t - 1, 0));
    setIndex((i) => Math.min(i, Math.max(items.length - 2, 0)));
  };

  const current = items[index];

  return (
    <div className="flex min-h-screen overflow-x-hidden bg-black">
      <Sidebar currentPage="markWork" onNavigate={navigate} />
      <main className="min-w-0 flex-1 p-4 pb-28 md:ml-64 md:p-8 md:pb-8">
        <PageHeader
          eyebrow="LEARNERS"
          title="Mark work"
          description={`Submissions waiting for a mark, oldest first. ${total} waiting. Keys: J / K next and previous, Ctrl + Enter save.`}
          actions={<button type="button" onClick={() => navigate('/admin/gradebook')} className="inline-flex items-center gap-2 rounded-xl border border-white/10 bg-white/5 px-3.5 py-2.5 text-sm font-semibold text-white/85"><FiGrid /> Gradebook</button>}
        />
        <GradebookFilters cls={cls} courseId={courseId} onClass={setCls} onCourse={setCourseId} />
        {loading ? <Spinner /> : error ? <ErrorState message={error} onRetry={load} /> : !items.length ? (
          <EmptyState icon={FiCheckCircle} title="Nothing to mark" description="New submissions will appear here." />
        ) : (
          <div className="grid gap-4 lg:grid-cols-[300px_minmax(0,1fr)]">
            <ul className="space-y-1.5" aria-label="Waiting for a mark">
              {items.map((item, i) => (
                <li key={item.id}>
                  <button
                    type="button"
                    onClick={() => setIndex(i)}
                    className={`w-full rounded-xl border px-3 py-2.5 text-left ${i === index ? 'border-[#EFB078] bg-[#EFB078]/10' : 'border-white/10 bg-white/[0.03] hover:bg-white/[0.06]'}`}
                  >
                    <span className="block truncate text-sm font-semibold text-white">{item.learner?.name || 'Learner'}</span>
                    <span className="block truncate text-xs text-white/50">{item.assignment?.title} · {when(item.submittedAt)}{item.late && <span className="text-rose-300"> · late</span>}</span>
                  </button>
                </li>
              ))}
            </ul>
            <section className="rounded-2xl border border-white/10 bg-white/[0.03] p-5">
              {current && <SubmissionPanel submission={current} saveLabel="Save and next" onSaved={done} />}
            </section>
          </div>
        )}
      </main>
    </div>
  );
};

export default MarkWorkPage;
