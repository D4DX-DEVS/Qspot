import React, { useCallback, useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { FiDownload, FiEdit3, FiGrid, FiX } from 'react-icons/fi';
import Sidebar from '../components/Sidebar';
import PageHeader from '../components/ui/PageHeader';
import Spinner from '../components/ui/Spinner';
import ErrorState from '../components/ui/ErrorState';
import EmptyState from '../components/ui/EmptyState';
import GradebookFilters from '../components/grading/GradebookFilters';
import GradebookTable from '../components/grading/GradebookTable';
import SubmissionPanel from '../components/grading/SubmissionPanel';
import usePageTitle from '../hooks/usePageTitle';
import apiClient from '../api/client';
import { downloadText, gradebookCsv } from '../utils/gradebook';

const buttonClass = 'inline-flex items-center gap-2 rounded-xl border border-white/10 bg-white/5 px-3.5 py-2.5 text-sm font-semibold text-white/85 disabled:opacity-40';

// Every learner's marks for a class, with the submission behind any cell one
// click away.
const GradebookPage = () => {
  usePageTitle('Gradebook');
  const navigate = useNavigate();
  const [cls, setCls] = useState('');
  const [courseId, setCourseId] = useState('');
  const [book, setBook] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [open, setOpen] = useState(null); // { loading, error, submission }

  const load = useCallback(async () => {
    setLoading(true);
    setError('');
    try {
      const response = await apiClient.get('/admin/gradebook', { params: { class: cls || undefined, courseId: courseId || undefined } });
      setBook(response.data);
    } catch (err) {
      setError(err.message || 'Could not load the gradebook.');
    } finally {
      setLoading(false);
    }
  }, [cls, courseId]);

  useEffect(() => { load(); }, [load]);

  const openCell = async (column, cell) => {
    if (cell.attemptId) {
      navigate(`/admin/quiz/attempts/${cell.attemptId}`);
      return;
    }
    setOpen({ loading: true });
    try {
      const response = await apiClient.get(`/admin/gradebook/submissions/${cell.submissionId}`);
      setOpen({ submission: response.data });
    } catch (err) {
      setOpen({ error: err.message || 'Could not open this submission.' });
    }
  };

  const exportCsv = () => {
    const name = `gradebook${cls ? `-class-${cls}` : ''}-${new Date().toISOString().slice(0, 10)}.csv`;
    downloadText(name, gradebookCsv(book));
  };

  return (
    <div className="flex min-h-screen overflow-x-hidden bg-black">
      <Sidebar currentPage="gradebook" onNavigate={navigate} />
      <main className="min-w-0 flex-1 p-4 pb-28 md:ml-64 md:p-8 md:pb-8">
        <PageHeader
          eyebrow="LEARNERS"
          title="Gradebook"
          description="Every exam and assignment mark for a class. Click a mark to open the work behind it."
          actions={<>
            <button type="button" onClick={() => navigate('/admin/mark-work')} className={buttonClass}><FiEdit3 /> Mark work{book?.needsMarking ? ` (${book.needsMarking})` : ''}</button>
            <button type="button" onClick={exportCsv} disabled={!book?.rows?.length} className={buttonClass}><FiDownload /> Export CSV</button>
          </>}
        />
        <GradebookFilters cls={cls} courseId={courseId} onClass={setCls} onCourse={setCourseId} />
        <p className="mb-4 text-xs text-white/45">Exams are matched to learners by class. The course filter applies to assignments, practice and lessons.</p>
        {book?.truncated && <p className="mb-4 rounded-xl border border-amber-200/30 bg-amber-200/10 px-3 py-2 text-sm text-amber-100">Showing the first {book.learnerLimit} learners. Pick a class to see everyone in it.</p>}
        {loading ? <Spinner /> : error ? <ErrorState message={error} onRetry={load} /> : !book?.rows?.length ? (
          <EmptyState icon={FiGrid} title="No learners match these filters" />
        ) : <GradebookTable book={book} onOpenCell={openCell} />}
      </main>

      {open && (
        <div className="fixed inset-0 z-[60] flex justify-end bg-black/60" onClick={() => setOpen(null)}>
          <aside className="h-full w-full max-w-md overflow-y-auto border-l border-white/10 bg-[#12060f] p-5" onClick={(event) => event.stopPropagation()}>
            <div className="mb-4 flex justify-end">
              <button type="button" aria-label="Close" onClick={() => setOpen(null)} className="rounded-lg p-2 text-white/60 hover:bg-white/10"><FiX /></button>
            </div>
            {open.loading ? <Spinner /> : open.error ? <ErrorState message={open.error} /> : (
              <SubmissionPanel submission={open.submission} onSaved={() => { setOpen(null); load(); }} />
            )}
          </aside>
        </div>
      )}
    </div>
  );
};

export default GradebookPage;
