import React, { useEffect, useState } from 'react';
import { FiCheck, FiCornerUpLeft } from 'react-icons/fi';
import apiClient from '../../api/client';
import { isRubricOn } from '../../utils/rubric';
import RubricScorer from './RubricScorer';
import SubmissionFiles from './SubmissionFiles';

const inputClass = 'w-full rounded-xl border border-white/10 bg-white/5 px-3 py-2.5 text-sm text-white placeholder-white/40 outline-none focus:border-[#EFB078]/60';

const when = (date) => (date ? new Date(date).toLocaleString(undefined, { day: 'numeric', month: 'short', hour: 'numeric', minute: '2-digit' }) : '');

const scoresFrom = (submission, criteria) =>
  criteria.map((_, i) => submission.rubricScores?.[i]?.points ?? '');

// One submission: the learner's text and files, a mark (one number, or a
// score for each part when the assignment is marked by parts) and feedback,
// and the two ways to finish with it. Ctrl/Cmd + Enter saves the mark.
const SubmissionPanel = ({ submission, onSaved, saveLabel = 'Save mark' }) => {
  const maxPoints = submission.assignment?.maxPoints || 100;
  const byParts = isRubricOn(submission.assignment?.rubric);
  const criteria = byParts ? submission.assignment.rubric.criteria : [];
  const [mark, setMark] = useState(submission.grade ?? '');
  const [scores, setScores] = useState(() => scoresFrom(submission, criteria));
  const [feedback, setFeedback] = useState(submission.feedback || '');
  const [saving, setSaving] = useState('');
  const [error, setError] = useState('');

  useEffect(() => {
    setMark(submission.grade ?? '');
    setScores(scoresFrom(submission, isRubricOn(submission.assignment?.rubric) ? submission.assignment.rubric.criteria : []));
    setFeedback(submission.feedback || '');
    setError('');
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [submission.id, submission.grade, submission.feedback]);

  const save = async (status) => {
    let body;
    if (status === 'graded' && byParts) {
      const missing = criteria.findIndex((part, i) => scores[i] === '' || !Number.isFinite(Number(scores[i])) || Number(scores[i]) < 0 || Number(scores[i]) > part.maxPoints);
      if (missing >= 0) {
        setError(`Score "${criteria[missing].label}" between 0 and ${criteria[missing].maxPoints}.`);
        return;
      }
      body = { rubricScores: scores.map(Number), feedback, status: 'graded' };
    } else if (status === 'graded') {
      const grade = Number(mark);
      if (String(mark).trim() === '' || !Number.isFinite(grade) || grade < 0 || grade > maxPoints) {
        setError(`Enter a mark between 0 and ${maxPoints}.`);
        return;
      }
      body = { grade, feedback, status: 'graded' };
    } else {
      if (!feedback.trim()) {
        setError('Say what to change in the feedback before returning it.');
        return;
      }
      body = { feedback, status: 'returned' };
    }
    setSaving(status);
    setError('');
    try {
      const response = await apiClient.put(`/admin/assignments/${submission.assignmentId}/submissions/${submission.id}`, body);
      onSaved?.(response.data.submission, status);
    } catch (err) {
      setError(err.message || 'Could not save. Try again.');
    } finally {
      setSaving('');
    }
  };

  return (
    <form
      className="flex flex-col gap-4"
      onSubmit={(event) => { event.preventDefault(); save('graded'); }}
      onKeyDown={(event) => { if (event.key === 'Enter' && (event.metaKey || event.ctrlKey)) { event.preventDefault(); save('graded'); } }}
    >
      <div className="min-w-0">
        <h3 className="break-words text-base font-semibold text-white">{submission.learner?.name || 'Learner'} · {submission.assignment?.title || 'Assignment'}</h3>
        <p className="mt-1 text-xs text-white/50">
          Sent {when(submission.submittedAt)} · {submission.late ? <span className="text-rose-300">late</span> : 'on time'}
          {submission.status === 'returned' && <span className="text-amber-200"> · returned for changes</span>}
        </p>
      </div>
      <SubmissionFiles files={submission.files} />
      <div className="rounded-xl border border-white/10 bg-black/20 p-3">
        <p className="mb-1 text-[10px] font-semibold uppercase tracking-[0.16em] text-white/40">Learner's answer</p>
        <p className="whitespace-pre-wrap break-words text-sm text-white/75">{submission.text || 'No written answer.'}</p>
      </div>
      {byParts ? (
        <RubricScorer criteria={criteria} scores={scores} onScore={(index, value) => setScores((current) => current.map((v, i) => (i === index ? value : v)))} />
      ) : (
        <label className="block">
          <span className="mb-1 block text-[10px] font-semibold uppercase tracking-[0.16em] text-white/40">Mark (out of {maxPoints})</span>
          <input id={`mark-${submission.id}`} type="number" min="0" max={maxPoints} value={mark} onChange={(event) => setMark(event.target.value)} className={inputClass} />
        </label>
      )}
      <label className="block">
        <span className="mb-1 block text-[10px] font-semibold uppercase tracking-[0.16em] text-white/40">Feedback</span>
        <textarea id={`feedback-${submission.id}`} rows={4} maxLength={10000} value={feedback} onChange={(event) => setFeedback(event.target.value)} placeholder="What went well, and what to work on" className={inputClass} />
      </label>
      {error && <p className="text-sm text-rose-300">{error}</p>}
      <div className="grid grid-cols-2 gap-2">
        <button type="button" disabled={Boolean(saving)} onClick={() => save('returned')} className="inline-flex items-center justify-center gap-1.5 rounded-xl border border-[#EFB078]/60 px-3 py-2.5 text-sm font-semibold text-[#EFB078] disabled:opacity-50">
          <FiCornerUpLeft size={15} />{saving === 'returned' ? 'Returning…' : 'Return for changes'}
        </button>
        <button type="submit" disabled={Boolean(saving)} className="inline-flex items-center justify-center gap-1.5 rounded-xl bg-gradient-to-r from-[#701845] via-[#9E4B63] to-[#EFB078] px-3 py-2.5 text-sm font-semibold text-white disabled:opacity-50">
          <FiCheck size={15} />{saving === 'graded' ? 'Saving…' : saveLabel}
        </button>
      </div>
    </form>
  );
};

export default SubmissionPanel;
