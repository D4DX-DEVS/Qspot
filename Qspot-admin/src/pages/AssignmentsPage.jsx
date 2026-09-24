import React, { useEffect, useMemo, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  FiActivity,
  FiBookOpen,
  FiCalendar,
  FiCheck,
  FiClock,
  FiEdit2,
  FiFileText,
  FiPlus,
  FiSearch,
  FiTrash2,
  FiUser,
  FiUsers,
  FiX,
} from 'react-icons/fi';
import Sidebar from '../components/Sidebar';
import ConfirmDialog from '../components/dialogs/ConfirmDialog';
import ErrorState from '../components/ui/ErrorState';
import EmptyState from '../components/ui/EmptyState';
import Spinner from '../components/ui/Spinner';
import Modal from '../components/ui/Modal';
import usePageTitle from '../hooks/usePageTitle';
import apiClient from '../api/client';

const cardClass = 'rounded-2xl border border-white/10 bg-gradient-to-br from-[#11060d]/75 via-[#1c0b18]/55 to-[#12060f]/75 shadow-[0_10px_32px_rgba(0,0,0,0.35)] backdrop-blur-xl';
const inputClass = 'w-full rounded-xl border border-white/10 bg-white/5 px-3 py-2.5 text-sm text-white placeholder-white/40 outline-none transition focus:border-[#EFB078]/60 focus:ring-2 focus:ring-[#701845]/30';
const emptyForm = () => ({
  title: '',
  instructions: '',
  courseId: '',
  subjectId: '',
  videoId: '',
  releaseAt: '',
  dueAt: '',
  maxPoints: '100',
  isPublished: false,
});

const value = (item, keys, fallback = '') => {
  for (const key of keys) {
    if (item?.[key] !== undefined && item?.[key] !== null) return item[key];
  }
  return fallback;
};

const toDateInput = (date) => {
  if (!date) return '';
  const parsed = new Date(date);
  if (Number.isNaN(parsed.getTime())) return '';
  const local = new Date(parsed.getTime() - parsed.getTimezoneOffset() * 60000);
  return local.toISOString().slice(0, 16);
};

const toIso = (date) => (date ? new Date(date).toISOString() : undefined);

const displayDate = (date) => {
  if (!date) return 'No due date';
  const parsed = new Date(date);
  return Number.isNaN(parsed.getTime())
    ? 'No due date'
    : parsed.toLocaleDateString(undefined, { month: 'short', day: 'numeric', year: 'numeric' });
};

const isPast = (date) => date && new Date(date).getTime() < Date.now();
const extractItems = (data) => (Array.isArray(data) ? data : Array.isArray(data?.items) ? data.items : Array.isArray(data?.assignments) ? data.assignments : []);

const getName = (item, fallback = 'Unassigned') => value(item, ['title', 'name'], fallback);
const getId = (item) => value(item, ['_id', 'id']);

const AssignmentsPage = () => {
  usePageTitle('Assignments');
  const navigate = useNavigate();
  const [assignments, setAssignments] = useState([]);
  const [courses, setCourses] = useState([]);
  const [subjects, setSubjects] = useState([]);
  const [videos, setVideos] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [search, setSearch] = useState('');
  const [status, setStatus] = useState('all');
  const [formOpen, setFormOpen] = useState(false);
  const [editing, setEditing] = useState(null);
  const [form, setForm] = useState(emptyForm());
  const [saving, setSaving] = useState(false);
  const [formError, setFormError] = useState('');
  const [deleteTarget, setDeleteTarget] = useState(null);
  const [submissionsFor, setSubmissionsFor] = useState(null);
  const [submissions, setSubmissions] = useState([]);
  const [submissionsLoading, setSubmissionsLoading] = useState(false);
  const [submissionsError, setSubmissionsError] = useState('');
  const [grading, setGrading] = useState(null);

  const load = async () => {
    setLoading(true);
    setError('');
    try {
      const [assignmentResponse, courseResponse, subjectResponse, videoResponse] = await Promise.all([
        apiClient.get('/admin/assignments'),
        apiClient.get('/courses'),
        apiClient.get('/subjects'),
        apiClient.get('/videos'),
      ]);
      setAssignments(extractItems(assignmentResponse.data));
      setCourses(extractItems(courseResponse.data));
      setSubjects(extractItems(subjectResponse.data));
      setVideos(extractItems(videoResponse.data));
    } catch (err) {
      setError(err.message || 'Could not load assignments.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { load(); }, []);

  const filteredAssignments = useMemo(() => {
    const query = search.trim().toLowerCase();
    return assignments
      .filter((assignment) => {
        if (status === 'published' && !value(assignment, ['isPublished', 'published'], false)) return false;
        if (status === 'draft' && value(assignment, ['isPublished', 'published'], false)) return false;
        if (status === 'overdue' && !isPast(value(assignment, ['dueAt', 'dueDate']))) return false;
        if (!query) return true;
        return [assignment.title, assignment.instructions, assignment.course?.title, assignment.subject?.name, assignment.video?.title]
          .filter(Boolean)
          .some((field) => String(field).toLowerCase().includes(query));
      })
      .sort((a, b) => {
        const dateA = new Date(value(a, ['dueAt', 'dueDate'], '9999-12-31')).getTime();
        const dateB = new Date(value(b, ['dueAt', 'dueDate'], '9999-12-31')).getTime();
        return dateA - dateB;
      });
  }, [assignments, search, status]);

  const publishedCount = assignments.filter((item) => Boolean(value(item, ['isPublished', 'published'], false))).length;
  const overdueCount = assignments.filter((item) => isPast(value(item, ['dueAt', 'dueDate']))).length;
  const reviewCount = assignments.reduce((sum, item) => sum + Number(value(item, ['pendingSubmissions', 'submissionsPending', 'needsReview'], 0) || 0), 0);

  const openCreate = () => {
    setEditing(null);
    setForm(emptyForm());
    setFormError('');
    setFormOpen(true);
  };

  const openEdit = (assignment) => {
    setEditing(assignment);
    setForm({
      title: assignment.title || '',
      instructions: assignment.instructions || assignment.description || '',
      courseId: getId(assignment.course) || assignment.courseId || '',
      subjectId: getId(assignment.subject) || assignment.subjectId || '',
      videoId: getId(assignment.video) || assignment.videoId || '',
      releaseAt: toDateInput(value(assignment, ['releaseAt', 'availableFrom'])),
      dueAt: toDateInput(value(assignment, ['dueAt', 'dueDate'])),
      maxPoints: String(value(assignment, ['maxPoints', 'points'], 100)),
      isPublished: Boolean(value(assignment, ['isPublished', 'published'], false)),
    });
    setFormError('');
    setFormOpen(true);
  };

  const closeForm = () => {
    if (saving) return;
    setFormOpen(false);
    setEditing(null);
  };

  const saveAssignment = async (event) => {
    event.preventDefault();
    if (!form.title.trim()) return setFormError('Title is required.');
    if (form.dueAt && form.releaseAt && new Date(form.dueAt) < new Date(form.releaseAt)) return setFormError('Due date must be after the release date.');
    const payload = {
      title: form.title.trim(),
      instructions: form.instructions.trim(),
      courseId: form.courseId || undefined,
      subjectId: form.subjectId || undefined,
      videoId: form.videoId || undefined,
      releaseAt: toIso(form.releaseAt),
      dueAt: toIso(form.dueAt),
      maxPoints: Number(form.maxPoints) || 100,
      isPublished: Boolean(form.isPublished),
    };
    try {
      setSaving(true);
      setFormError('');
      if (editing) await apiClient.put(`/admin/assignments/${getId(editing)}`, payload);
      else await apiClient.post('/admin/assignments', payload);
      closeForm();
      await load();
    } catch (err) {
      setFormError(err.message || 'Failed to save assignment.');
    } finally {
      setSaving(false);
    }
  };

  const deleteAssignment = async () => {
    if (!deleteTarget) return;
    try {
      await apiClient.delete(`/admin/assignments/${getId(deleteTarget)}`);
      setDeleteTarget(null);
      await load();
    } catch (err) {
      setError(err.message || 'Failed to delete assignment.');
      setDeleteTarget(null);
    }
  };

  const openSubmissions = async (assignment) => {
    setSubmissionsFor(assignment);
    setSubmissions([]);
    setSubmissionsError('');
    setSubmissionsLoading(true);
    try {
      const response = await apiClient.get(`/admin/assignments/${getId(assignment)}/submissions`);
      setSubmissions(extractItems(response.data));
    } catch (err) {
      setSubmissionsError(err.message || 'Could not load submissions.');
    } finally {
      setSubmissionsLoading(false);
    }
  };

  const updateSubmission = async (submission, patch) => {
    const submissionId = getId(submission);
    const assignmentId = getId(submissionsFor);
    if (!submissionId || !assignmentId) return;
    try {
      setGrading(submissionId);
      const response = await apiClient.put(`/admin/assignments/${assignmentId}/submissions/${submissionId}`, patch);
      const updated = response.data?.submission || response.data;
      setSubmissions((current) => current.map((item) => (getId(item) === submissionId ? { ...item, ...updated } : item)));
    } catch (err) {
      setSubmissionsError(err.message || 'Could not update submission.');
    } finally {
      setGrading(null);
    }
  };

  const scopedSubjects = form.courseId
    ? subjects.filter((subject) => String(getId(subject.course) || subject.courseId || '') === String(form.courseId))
    : subjects;
  const scopedVideos = form.subjectId
    ? videos.filter((video) => String(getId(video.subject) || video.subjectId || '') === String(form.subjectId))
    : videos;

  return (
    <div className="flex min-h-screen overflow-x-hidden bg-black">
      <Sidebar currentPage="assignments" onNavigate={navigate} />
      <div className="flex w-full flex-1 flex-col pb-28 md:ml-64 md:pb-0">
        <main className="flex-1 p-4 sm:p-6 md:p-8">
          <div className="mb-6 flex flex-col gap-4 lg:flex-row lg:items-end lg:justify-between">
            <div>
              <p className="mb-2 text-xs font-semibold uppercase tracking-[0.25em] text-[#EFB078]/70">Learning operations</p>
              <h1 className="text-2xl font-bold text-white sm:text-3xl">Assignments</h1>
              <p className="mt-1 text-sm text-white/55">Give learners a clear next step and review their work in one place.</p>
            </div>
            <button type="button" onClick={openCreate} className="inline-flex items-center justify-center gap-2 rounded-xl bg-gradient-to-r from-[#701845]/90 via-[#9E4B63]/80 to-[#EFB078]/85 px-4 py-2.5 text-sm font-semibold text-white shadow-[0_8px_20px_rgba(112,24,69,0.3)] transition hover:brightness-110">
              <FiPlus size={16} /> New assignment
            </button>
          </div>

          <div className="mb-6 grid grid-cols-2 gap-3 lg:grid-cols-4">
            {[
              ['Total', assignments.length, FiFileText],
              ['Published', publishedCount, FiCheck],
              ['Overdue', overdueCount, FiClock],
              ['Needs review', reviewCount, FiUsers],
            ].map(([label, count, metricIcon]) => (
              <div key={label} className={`${cardClass} p-4`}>
                <div className="flex items-center gap-3"><span className="flex h-9 w-9 items-center justify-center rounded-xl bg-[#701845]/30 text-[#EFB078]">{React.createElement(metricIcon, { size: 16 })}</span><div><p className="text-xl font-bold text-white">{count}</p><p className="text-xs text-white/50">{label}</p></div></div>
              </div>
            ))}
          </div>

          <div className={`${cardClass} mb-5 flex flex-col gap-3 p-3 sm:flex-row sm:items-center`}>
            <div className="relative min-w-0 flex-1"><FiSearch className="absolute left-3 top-1/2 -translate-y-1/2 text-white/35" size={16} /><input value={search} onChange={(event) => setSearch(event.target.value)} placeholder="Search assignments, courses, or lessons" className={`${inputClass} pl-9`} /></div>
            <div className="flex items-center gap-1 overflow-x-auto rounded-xl border border-white/10 bg-black/20 p-1">
              {[['all', 'All'], ['published', 'Published'], ['draft', 'Draft'], ['overdue', 'Overdue']].map(([key, label]) => <button key={key} type="button" onClick={() => setStatus(key)} className={`shrink-0 rounded-lg px-3 py-2 text-xs font-semibold transition ${status === key ? 'bg-[#701845]/70 text-white' : 'text-white/55 hover:text-white'}`}>{label}</button>)}
            </div>
          </div>

          {loading ? <Spinner /> : error ? <ErrorState message={error} onRetry={load} /> : filteredAssignments.length === 0 ? <div className={cardClass}><EmptyState icon={FiFileText} title={search || status !== 'all' ? 'No assignments match this view' : 'No assignments yet'} description="Create an assignment to give learners a focused practice step." action={<button type="button" onClick={openCreate} className="mt-2 rounded-xl bg-[#701845]/70 px-4 py-2 text-sm font-semibold text-white">Create assignment</button>} /></div> : (
            <div className={`${cardClass} overflow-hidden`}>
              <div className="hidden grid-cols-[minmax(0,1.6fr)_minmax(120px,1fr)_minmax(125px,0.9fr)_auto] gap-4 border-b border-white/10 px-5 py-3 text-[11px] font-semibold uppercase tracking-[0.18em] text-white/40 md:grid"><span>Assignment</span><span>Scope</span><span>Due</span><span>Actions</span></div>
              <div className="divide-y divide-white/10">{filteredAssignments.map((assignment) => {
                const published = Boolean(value(assignment, ['isPublished', 'published'], false));
                const dueAt = value(assignment, ['dueAt', 'dueDate']);
                const courseName = getName(assignment.course, assignment.courseId ? 'Course linked' : 'All courses');
                const subjectName = getName(assignment.subject, assignment.subjectId ? 'Subject linked' : 'All subjects');
                const videoName = getName(assignment.video, assignment.videoId ? 'Lesson linked' : 'All lessons');
                const pending = Number(value(assignment, ['pendingSubmissions', 'submissionsPending', 'needsReview'], 0) || 0);
                return <div key={getId(assignment)} className="grid gap-3 px-4 py-4 transition hover:bg-white/[0.03] md:grid-cols-[minmax(0,1.6fr)_minmax(120px,1fr)_minmax(125px,0.9fr)_auto] md:items-center md:gap-4 md:px-5">
                  <div className="min-w-0"><div className="flex items-start gap-3"><span className="mt-0.5 flex h-8 w-8 shrink-0 items-center justify-center rounded-lg bg-[#701845]/35 text-[#EFB078]"><FiBookOpen size={15} /></span><div className="min-w-0"><h2 className="break-words text-sm font-semibold text-white">{assignment.title || 'Untitled assignment'}</h2><p className="mt-1 line-clamp-2 text-xs text-white/50">{assignment.instructions || 'No instructions added yet.'}</p></div></div><div className="mt-2 flex flex-wrap items-center gap-2 pl-11 text-[11px] text-white/45"><span className={`rounded-full px-2 py-0.5 ${published ? 'bg-emerald-400/15 text-emerald-300' : 'bg-white/10 text-white/55'}`}>{published ? 'Published' : 'Draft'}</span>{pending > 0 && <span className="text-amber-300">{pending} awaiting review</span>}</div></div>
                  <div className="pl-11 text-xs text-white/60 md:pl-0"><p>{courseName}</p><p className="mt-1 text-white/40">{subjectName} · {videoName}</p></div>
                  <div className="flex items-center gap-2 pl-11 text-xs text-white/60 md:pl-0"><FiCalendar className="shrink-0 text-[#EFB078]" size={14} /><span className={isPast(dueAt) ? 'text-rose-300' : ''}>{displayDate(dueAt)}</span></div>
                  <div className="flex items-center gap-1 pl-11 md:justify-end md:pl-0"><button type="button" title="Review submissions" onClick={() => openSubmissions(assignment)} className="inline-flex h-8 items-center gap-1 rounded-lg border border-white/10 bg-white/5 px-2 text-xs text-white/70 hover:bg-white/10"><FiUsers size={14} /><span className="hidden lg:inline">Review</span></button><button type="button" title="Edit assignment" onClick={() => openEdit(assignment)} className="inline-flex h-8 w-8 items-center justify-center rounded-lg border border-white/10 bg-white/5 text-white/70 hover:bg-white/10"><FiEdit2 size={14} /></button><button type="button" title="Delete assignment" onClick={() => setDeleteTarget(assignment)} className="inline-flex h-8 w-8 items-center justify-center rounded-lg border border-rose-300/15 bg-rose-400/5 text-rose-200/70 hover:bg-rose-400/10"><FiTrash2 size={14} /></button></div>
                </div>;
              })}</div>
            </div>
          )}
        </main>
      </div>

      {formOpen && <Modal title={editing ? 'Edit assignment' : 'New assignment'} subtitle="Learning operations" onClose={closeForm} maxWidth="max-w-2xl">
        <form onSubmit={saveAssignment} className="space-y-4">
          {formError && <ErrorState message={formError} />}
          <label className="block"><span className="mb-1.5 block text-xs font-semibold uppercase tracking-[0.15em] text-white/55">Title</span><input required value={form.title} onChange={(event) => setForm((current) => ({ ...current, title: event.target.value }))} className={inputClass} placeholder="e.g. Reflection after lesson 3" /></label>
          <label className="block"><span className="mb-1.5 block text-xs font-semibold uppercase tracking-[0.15em] text-white/55">Instructions</span><textarea value={form.instructions} onChange={(event) => setForm((current) => ({ ...current, instructions: event.target.value }))} className={`${inputClass} min-h-24 resize-y`} placeholder="Tell learners what a good submission includes." /></label>
          <div className="grid gap-3 sm:grid-cols-2"><label className="block"><span className="mb-1.5 block text-xs font-semibold text-white/55">Course</span><select value={form.courseId} onChange={(event) => setForm((current) => ({ ...current, courseId: event.target.value, subjectId: '', videoId: '' }))} className={inputClass}><option value="">All courses</option>{courses.map((item) => <option key={getId(item)} value={getId(item)}>{getName(item)}</option>)}</select></label><label className="block"><span className="mb-1.5 block text-xs font-semibold text-white/55">Subject</span><select value={form.subjectId} onChange={(event) => setForm((current) => ({ ...current, subjectId: event.target.value, videoId: '' }))} className={inputClass}><option value="">All subjects</option>{scopedSubjects.map((item) => <option key={getId(item)} value={getId(item)}>{getName(item)}</option>)}</select></label></div>
          <label className="block"><span className="mb-1.5 block text-xs font-semibold text-white/55">Lesson (optional)</span><select value={form.videoId} onChange={(event) => setForm((current) => ({ ...current, videoId: event.target.value }))} className={inputClass}><option value="">All lessons in this scope</option>{scopedVideos.map((item) => <option key={getId(item)} value={getId(item)}>{getName(item)}</option>)}</select></label>
          <div className="grid gap-3 sm:grid-cols-3"><label className="block"><span className="mb-1.5 block text-xs font-semibold text-white/55">Available from</span><input type="datetime-local" value={form.releaseAt} onChange={(event) => setForm((current) => ({ ...current, releaseAt: event.target.value }))} className={inputClass} /></label><label className="block"><span className="mb-1.5 block text-xs font-semibold text-white/55">Due date</span><input type="datetime-local" value={form.dueAt} onChange={(event) => setForm((current) => ({ ...current, dueAt: event.target.value }))} className={inputClass} /></label><label className="block"><span className="mb-1.5 block text-xs font-semibold text-white/55">Max points</span><input type="number" min="1" value={form.maxPoints} onChange={(event) => setForm((current) => ({ ...current, maxPoints: event.target.value }))} className={inputClass} /></label></div>
          <label className="flex items-center gap-3 rounded-xl border border-white/10 bg-white/5 px-3 py-3 text-sm text-white/75"><input type="checkbox" checked={form.isPublished} onChange={(event) => setForm((current) => ({ ...current, isPublished: event.target.checked }))} className="h-4 w-4 accent-[#EFB078]" /> Publish this assignment for learners</label>
          <div className="flex justify-end gap-2 border-t border-white/10 pt-4"><button type="button" onClick={closeForm} className="rounded-xl border border-white/10 px-4 py-2 text-sm text-white/65 hover:bg-white/5">Cancel</button><button type="submit" disabled={saving} className="rounded-xl bg-gradient-to-r from-[#701845] to-[#EFB078]/80 px-4 py-2 text-sm font-semibold text-white disabled:opacity-60">{saving ? 'Saving…' : editing ? 'Save changes' : 'Create assignment'}</button></div>
        </form>
      </Modal>}

      {submissionsFor && <Modal title="Submission review" subtitle={submissionsFor.title || 'Assignment'} onClose={() => setSubmissionsFor(null)} maxWidth="max-w-3xl">
        {submissionsLoading ? <Spinner /> : submissionsError ? <ErrorState message={submissionsError} onRetry={() => openSubmissions(submissionsFor)} /> : submissions.length === 0 ? <EmptyState icon={FiUsers} title="No submissions yet" description="Learner submissions will appear here when they turn in this assignment." /> : <div className="space-y-3">{submissions.map((submission) => { const learner = submission.user || submission.student || {}; const id = getId(submission); const statusValue = submission.status || 'submitted'; return <div key={id} className="rounded-xl border border-white/10 bg-white/[0.03] p-4"><div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between"><div className="min-w-0"><div className="flex items-center gap-2 text-sm font-semibold text-white"><FiUser className="text-[#EFB078]" size={14} />{learner.name || learner.fullName || learner.phone || submission.userName || 'Learner'}</div><p className="mt-1 text-xs text-white/45">Submitted {displayDate(submission.submittedAt || submission.createdAt)}</p></div><span className={`rounded-full px-2 py-1 text-[11px] font-semibold ${statusValue === 'graded' ? 'bg-emerald-400/15 text-emerald-300' : statusValue === 'returned' ? 'bg-amber-400/15 text-amber-200' : 'bg-white/10 text-white/65'}`}>{statusValue}</span></div><p className="mt-3 whitespace-pre-wrap rounded-lg bg-black/20 p-3 text-sm text-white/70">{submission.text || submission.answer || submission.content || 'No written response. Check attached files in the learner record.'}</p><div className="mt-3 grid gap-2 sm:grid-cols-[130px_1fr_auto]"><input type="number" min="0" value={submission.grade ?? submission.score ?? ''} onChange={(event) => setSubmissions((current) => current.map((item) => getId(item) === id ? { ...item, grade: event.target.value } : item))} placeholder="Points" className={inputClass} /><input value={submission.feedback || ''} onChange={(event) => setSubmissions((current) => current.map((item) => getId(item) === id ? { ...item, feedback: event.target.value } : item))} placeholder="Feedback for learner" className={inputClass} /><button type="button" disabled={grading === id} onClick={() => updateSubmission(submission, { grade: submission.grade === '' ? null : Number(submission.grade), feedback: submission.feedback || '', status: 'graded' })} className="inline-flex items-center justify-center gap-1 rounded-xl bg-[#701845]/75 px-3 py-2 text-xs font-semibold text-white disabled:opacity-50"><FiCheck size={14} />{grading === id ? 'Saving' : 'Save grade'}</button></div></div>; })}</div>}
      </Modal>}

      {deleteTarget && <ConfirmDialog title="Delete assignment" description={`Delete “${deleteTarget.title || 'this assignment'}”? Existing submissions may become unavailable.`} cancelLabel="Keep assignment" confirmLabel="Delete" confirmVariant="danger" onCancel={() => setDeleteTarget(null)} onConfirm={deleteAssignment} />}
    </div>
  );
};

export default AssignmentsPage;
