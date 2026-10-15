// Wording, colours and CSV export for the gradebook. Plain functions so the
// pages only lay things out.

const STATUS_LABELS = {
  not_sat: 'not sat',
  not_sent: 'not sent',
  needs_mark: 'Needs mark',
  returned: 'Returned',
  pending: '—',
};

// What a cell shows: "82%" for an exam, "8/10" for a marked assignment, or a
// word for everything else.
export const cellLabel = (column, cell) => {
  if (!cell) return '—';
  if (column.kind === 'exam' && cell.status === 'done') return `${cell.percent}%`;
  if (column.kind === 'assignment' && cell.status === 'graded') return `${cell.value}/${column.maxPoints}`;
  return STATUS_LABELS[cell.status] || '—';
};

// Text colour by mark band; muted for blanks.
export const toneFor = (percent) => {
  if (percent === null || percent === undefined) return 'text-white/40';
  if (percent >= 80) return 'text-emerald-300';
  if (percent >= 50) return 'text-amber-200';
  return 'text-rose-300';
};

export const percentLabel = (value) => (value === null || value === undefined ? '—' : `${value}%`);

const csvField = (value) => {
  const text = value === null || value === undefined ? '' : String(value);
  return /[",\n\r]/.test(text) ? `"${text.replace(/"/g, '""')}"` : text;
};

// The gradebook exactly as shown, one learner per line.
export const gradebookCsv = (book) => {
  const header = [
    'Learner',
    'Class',
    ...book.columns.map((c) => (c.kind === 'assignment' ? `${c.title} (out of ${c.maxPoints})` : `${c.title} (%)`)),
    'Practice average (%)',
    `Lessons finished (of ${book.lessonsTotal})`,
    'Overall (%)',
  ];
  const lines = book.rows.map((row) => [
    row.learner.name,
    row.learner.class,
    ...book.columns.map((c) => {
      const cell = row.cells[c.id];
      if (c.kind === 'exam' && cell?.status === 'done') return cell.percent;
      if (c.kind === 'assignment' && cell?.status === 'graded') return cell.value;
      return cell?.status === 'pending' ? '' : STATUS_LABELS[cell?.status] || '';
    }),
    row.practiceAvg ?? '',
    row.lessonsDone,
    row.overall ?? '',
  ]);
  // Byte-order mark so Excel reads Malayalam names correctly.
  return '﻿' + [header, ...lines].map((line) => line.map(csvField).join(',')).join('\r\n');
};

export const downloadText = (filename, text, type = 'text/csv;charset=utf-8') => {
  const url = URL.createObjectURL(new Blob([text], { type }));
  const link = document.createElement('a');
  link.href = url;
  link.download = filename;
  document.body.appendChild(link);
  link.click();
  link.remove();
  URL.revokeObjectURL(url);
};

// Submission files are full URLs on the CDN, or /uploads/... paths on the
// API server when it stores files locally.
export const fileUrl = (url) => {
  if (!url || /^https?:\/\//i.test(url)) return url;
  try {
    return new URL(url, new URL(import.meta.env.VITE_API_BASE_URL).origin).toString();
  } catch {
    return url;
  }
};

// A submission from the Assignments review list in the shape the marking
// panel uses (the gradebook API already sends this shape).
export const submissionForPanel = (submission, assignment) => {
  const id = (value) => (value && typeof value === 'object' ? value._id || value.id : value);
  const learner = submission.userId && typeof submission.userId === 'object' ? submission.userId : submission.user || {};
  return {
    id: String(id(submission)),
    assignmentId: String(id(assignment)),
    assignment: { title: assignment.title, maxPoints: assignment.maxPoints, rubric: assignment.rubric },
    learner: { name: learner.name || '' },
    text: submission.text || '',
    files: submission.files || [],
    status: submission.status,
    late: Boolean(assignment.dueAt) && new Date(submission.submittedAt) > new Date(assignment.dueAt),
    grade: submission.grade ?? null,
    rubricScores: submission.rubricScores || [],
    feedback: submission.feedback || '',
    submittedAt: submission.submittedAt,
  };
};
