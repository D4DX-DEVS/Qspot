import React, { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  FiPlus,
  FiEdit2,
  FiTrash2,
  FiX,
  FiSave,
  FiCalendar,
  FiClock,
  FiActivity,
  FiList,
  FiBarChart2,
  FiHelpCircle,
  FiUsers,
  FiAward
} from 'react-icons/fi';
import Sidebar from '../components/Sidebar';
import ConfirmDialog from '../components/dialogs/ConfirmDialog';
import ErrorState from '../components/ui/ErrorState';
import Spinner from '../components/ui/Spinner';
import Pagination from '../components/ui/Pagination';
import PageHeader from '../components/ui/PageHeader';
import usePageTitle from '../hooks/usePageTitle';
import apiClient from '../api/client';
import { localDateTimeToISO, isoToLocalDateTimeInput, formatDateTime } from '../utils/format';
import brandIcon from '../assets/Icon.png';

const DEFAULT_FORM = {
  title: '',
  assessmentType: 'quiz',
  startDate: '',
  endDate: '',
  numberOfQuestions: '',
  overallTimeLimit: '',
  perQuestionTimeLimit: '',
  timerMode: 'none',
  allowedClasses: '',
  requireCompletedVideo: false,
  optionsCount: '',
  questionsRandomization: false,
  isEnable: false,
  certificateEnabled: false,
  certificateTitle: 'Certificate of Achievement',
  certificateIssuerName: '',
  certificateSignatoryName: '',
  certificateDescription: 'For successfully completing the examination.',
  certificateMinimumPercentage: '0',
  certificateEligibleClasses: ''
};

const toDateInputValue = isoToLocalDateTimeInput;

const QuizzesPage = () => {
  usePageTitle('Quizzes');
  const navigate = useNavigate();

  const [quizzes, setQuizzes] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [page, setPage] = useState(1);
  const [total, setTotal] = useState(0);
  const limit = 12;
  const totalPages = Math.max(1, Math.ceil(total / limit));

  const [showModal, setShowModal] = useState(false);
  const [editingQuiz, setEditingQuiz] = useState(null);
  const [form, setForm] = useState(DEFAULT_FORM);
  const [formError, setFormError] = useState('');
  const [saving, setSaving] = useState(false);

  const [deleteTarget, setDeleteTarget] = useState(null);
  const [deleteLoading, setDeleteLoading] = useState(false);

  const fetchQuizzes = async (targetPage = page) => {
    try {
      setLoading(true);
      setError('');
      const response = await apiClient.get('/quiz-definitions', {
        params: { page: targetPage, limit }
      });
      setQuizzes(Array.isArray(response.data?.items) ? response.data.items : []);
      setTotal(response.data?.total || 0);
    } catch (err) {
      setError(err.message || 'Failed to load quizzes');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchQuizzes(page);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [page]);

  const openCreateModal = () => {
    setEditingQuiz(null);
    setForm(DEFAULT_FORM);
    setFormError('');
    setShowModal(true);
  };

  const openEditModal = (quiz) => {
    setEditingQuiz(quiz);
    setForm({
      title: quiz.title || '',
      assessmentType: quiz.assessmentType || 'quiz',
      startDate: toDateInputValue(quiz.startDate),
      endDate: toDateInputValue(quiz.endDate),
      numberOfQuestions: String(quiz.numberOfQuestions ?? ''),
      overallTimeLimit: quiz.overallTimeLimit != null ? String(quiz.overallTimeLimit) : '',
      perQuestionTimeLimit: quiz.perQuestionTimeLimit != null ? String(quiz.perQuestionTimeLimit) : '',
      timerMode: quiz.timerMode || 'none',
      allowedClasses: Array.isArray(quiz.allowedClasses) ? quiz.allowedClasses.join(', ') : '',
      requireCompletedVideo: Boolean(quiz.conditions?.requireCompletedVideo),
      optionsCount: quiz.optionsCount != null ? String(quiz.optionsCount) : '',
      questionsRandomization: Boolean(quiz.questionsRandomization),
      isEnable: Boolean(quiz.isEnable),
      certificateEnabled: Boolean(quiz.certificate?.enabled),
      certificateTitle: quiz.certificate?.title || 'Certificate of Achievement',
      certificateIssuerName: quiz.certificate?.issuerName || '',
      certificateSignatoryName: quiz.certificate?.signatoryName || '',
      certificateDescription: quiz.certificate?.description || 'For successfully completing the examination.',
      certificateMinimumPercentage: String(quiz.certificate?.minimumPercentage ?? 0),
      certificateEligibleClasses: Array.isArray(quiz.certificate?.eligibleClasses) ? quiz.certificate.eligibleClasses.join(', ') : ''
    });
    setFormError('');
    setShowModal(true);
  };

  const closeModal = () => {
    setShowModal(false);
    setEditingQuiz(null);
    setForm(DEFAULT_FORM);
    setFormError('');
  };

  const handleFieldChange = (field, value) => {
    setForm((prev) => ({ ...prev, [field]: value }));
  };

  const handleSave = async (event) => {
    event.preventDefault();

    if (!form.title.trim()) {
      setFormError('Title is required.');
      return;
    }
    if (!form.startDate || !form.endDate) {
      setFormError('Start and end date are required.');
      return;
    }
    if (new Date(form.startDate) >= new Date(form.endDate)) {
      setFormError('Start date must be before end date.');
      return;
    }
    const numberOfQuestions = Number(form.numberOfQuestions);
    if (!numberOfQuestions || numberOfQuestions < 1) {
      setFormError('Number of questions must be at least 1.');
      return;
    }

    const payload = {
      title: form.title.trim(),
      assessmentType: form.assessmentType,
      startDate: localDateTimeToISO(form.startDate),
      endDate: localDateTimeToISO(form.endDate),
      numberOfQuestions,
      questionsRandomization: form.questionsRandomization,
      isEnable: form.isEnable
    };
    payload.timerMode = form.timerMode;
    payload.allowedClasses = form.allowedClasses;
    payload.conditions = { requireCompletedVideo: form.requireCompletedVideo };
    payload.certificate = {
      enabled: form.certificateEnabled,
      title: form.certificateTitle.trim(),
      issuerName: form.certificateIssuerName.trim(),
      signatoryName: form.certificateSignatoryName.trim(),
      description: form.certificateDescription.trim(),
      minimumPercentage: Number(form.certificateMinimumPercentage || 0),
      eligibleClasses: form.certificateEligibleClasses
    };
    if (form.overallTimeLimit !== '') payload.overallTimeLimit = Number(form.overallTimeLimit);
    if (form.perQuestionTimeLimit !== '') payload.perQuestionTimeLimit = Number(form.perQuestionTimeLimit);
    if (form.optionsCount !== '') payload.optionsCount = Number(form.optionsCount);

    try {
      setSaving(true);
      setFormError('');
      if (editingQuiz) {
        await apiClient.put(`/quiz-definitions/${editingQuiz._id}`, payload);
      } else {
        await apiClient.post('/quiz-definitions', payload);
      }
      closeModal();
      fetchQuizzes();
    } catch (err) {
      setFormError(err.message || 'Failed to save quiz');
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async () => {
    if (!deleteTarget) return;
    try {
      setDeleteLoading(true);
      await apiClient.delete(`/quiz-definitions/${deleteTarget._id}`);
      setDeleteTarget(null);
      fetchQuizzes();
    } catch (err) {
      setError(err.message || 'Failed to delete quiz');
      setDeleteTarget(null);
    } finally {
      setDeleteLoading(false);
    }
  };

  return (
    <div className="flex min-h-screen overflow-x-hidden bg-black">
      <Sidebar currentPage="quizzes" onNavigate={navigate} />

      <div className="flex-1 flex flex-col w-full pb-28 md:ml-64 md:pb-0">
        <main className="flex-1 p-6 md:p-8 flex flex-col gap-8">
          <PageHeader
            title="Quizzes"
            actions={
              <button
                onClick={openCreateModal}
                className="inline-flex items-center gap-1.5 rounded-xl bg-gradient-to-r from-[#701845]/80 via-[#9E4B63]/75 to-[#EFB078]/80 px-3.5 py-1.5 text-xs font-semibold uppercase tracking-[0.2em] text-white shadow-[0_10px_28px_rgba(112,24,69,0.35)] transition hover:from-[#5a1538] hover:to-[#d49a6a]"
              >
                <FiPlus size={13} /> Create Quiz
              </button>
            }
          />

          {error && !loading && <ErrorState message={error} onRetry={() => fetchQuizzes(page)} />}

          {loading ? (
            <Spinner />
          ) : quizzes.length === 0 ? (
            <div className="rounded-3xl border border-dashed border-white/15 bg-white/5 px-8 py-12 text-center text-white/70">
              <p className="text-lg font-semibold">No quizzes yet</p>
              <p className="text-sm text-white/50 mt-2">Create your first quiz to get started.</p>
            </div>
          ) : (
            <div className="grid grid-cols-1 gap-4 md:grid-cols-2 xl:grid-cols-3">
              {quizzes.map((quiz) => (
                <div
                  key={quiz._id}
                  className="flex flex-col gap-3 rounded-2xl border border-white/10 bg-gradient-to-br from-[#11060d]/75 via-[#1c0b18]/55 to-[#12060f]/75 p-4 shadow-[0_10px_32px_rgba(0,0,0,0.35)] backdrop-blur-xl"
                >
                  <div className="flex flex-wrap items-start justify-between gap-2">
                    <div className="flex min-w-0 items-center gap-2">
                      <img src={brandIcon} alt="" className="h-6 w-6 shrink-0 rounded object-contain" />
                      <h3 className="text-base font-semibold text-white break-words">{quiz.title}</h3>
                    </div>
                    <span
                      className={`text-xs font-semibold ${quiz.isEnable ? 'text-green-300' : 'text-red-300'}`}
                    >
                      {quiz.isEnable ? 'Enabled' : 'Disabled'}
                    </span>
                  </div>

                  <div className="space-y-1.5 text-xs text-white/70">
                    <div className="font-semibold uppercase tracking-[0.16em] text-[#EFB078]">{quiz.assessmentType === 'practical' ? 'Practical exam' : 'Knowledge quiz'}</div>
                    <div className="flex items-center gap-2">
                      <FiCalendar className="text-[#EFB078]" size={12} />
                      {formatDateTime(quiz.startDate)} → {formatDateTime(quiz.endDate)}
                    </div>
                    <div className="flex items-center gap-2">
                      <FiActivity className="text-[#EFB078]" size={12} />
                      {quiz.numberOfQuestions} questions per attempt
                      {quiz.questionsRandomization ? ' · randomized' : ''}
                    </div>
                    {(quiz.overallTimeLimit || quiz.perQuestionTimeLimit) && (
                      <div className="flex items-center gap-2">
                        <FiClock className="text-[#EFB078]" size={12} />
                        {quiz.overallTimeLimit ? `${quiz.overallTimeLimit >= 60 ? `${Math.floor(quiz.overallTimeLimit / 60)}m` : `${quiz.overallTimeLimit}s`} overall` : ''}
                        {quiz.overallTimeLimit && quiz.perQuestionTimeLimit ? ' · ' : ''}
                        {quiz.perQuestionTimeLimit ? `${quiz.perQuestionTimeLimit}s/question` : ''}
                      </div>
                    )}
                    <div className="flex items-center gap-4 pt-1">
                      <span className="flex items-center gap-1.5" title="Questions in the bank">
                        <FiHelpCircle className="text-[#EFB078]" size={12} /> {quiz.questionCount ?? 0} bank
                      </span>
                      <span className="flex items-center gap-1.5" title="Student attempts">
                        <FiUsers className="text-[#EFB078]" size={12} /> {quiz.attemptCount ?? 0} attempts
                      </span>
                    </div>
                  </div>

                  <div className="mt-2 flex flex-wrap items-center gap-2 border-t border-white/10 pt-3">
                    <button
                      onClick={() => navigate(`/admin/quiz?quizId=${quiz._id}`)}
                      className="inline-flex items-center gap-1.5 rounded-lg border border-white/12 bg-white/5 px-3 py-1.5 text-xs font-semibold text-white/80 transition hover:border-[#EFB078]/40 hover:text-white"
                    >
                      <FiList size={13} /> Questions
                    </button>
                    <button
                      onClick={() => navigate(`/admin/quiz/attempts?quizId=${quiz._id}`)}
                      className="inline-flex items-center gap-1.5 rounded-lg border border-white/12 bg-white/5 px-3 py-1.5 text-xs font-semibold text-white/80 transition hover:border-[#EFB078]/40 hover:text-white"
                    >
                      <FiBarChart2 size={13} /> Results
                    </button>
                    <button
                      onClick={() => navigate(`/admin/certificates?quizId=${quiz._id}`)}
                      className="inline-flex items-center gap-1.5 rounded-lg border border-[#EFB078]/25 bg-[#EFB078]/5 px-3 py-1.5 text-xs font-semibold text-[#F4C58F] transition hover:border-[#EFB078]/60 hover:bg-[#EFB078]/15"
                    >
                      <FiAward size={13} /> Certificates
                    </button>
                    <button
                      onClick={() => openEditModal(quiz)}
                      aria-label="Edit quiz"
                      title="Edit quiz"
                      className="ml-auto inline-flex h-9 w-9 items-center justify-center rounded-lg border border-white/12 bg-white/5 text-white/75 transition hover:border-[#EFB078]/40 hover:text-[#EFB078]"
                    >
                      <FiEdit2 size={13} />
                    </button>
                    <button
                      onClick={() => setDeleteTarget(quiz)}
                      aria-label="Delete quiz"
                      title="Delete quiz"
                      className="inline-flex h-9 w-9 items-center justify-center rounded-lg border border-red-400/30 bg-red-500/10 text-red-300 transition hover:border-red-300/60 hover:text-red-200"
                    >
                      <FiTrash2 size={13} />
                    </button>
                  </div>
                </div>
              ))}
            </div>
          )}

          {!loading && <Pagination page={page} totalPages={totalPages} total={total} onChange={setPage} label="quizzes" />}
        </main>
      </div>

      {deleteTarget && (
        <ConfirmDialog
          title="Delete Quiz"
          description={`This will permanently delete "${deleteTarget.title}" and cannot be undone. Questions and results tied to this quiz will remain but no longer be reachable through this quiz.`}
          confirmLabel={deleteLoading ? 'Deleting…' : 'Delete'}
          cancelLabel="Cancel"
          confirmVariant="danger"
          onCancel={() => (!deleteLoading ? setDeleteTarget(null) : null)}
          onConfirm={() => {
            if (!deleteLoading) handleDelete();
          }}
        />
      )}

      {showModal && (
        <div className="fixed inset-0 z-[140] flex items-center justify-center px-4 py-8">
          <div className="absolute inset-0 bg-black/70 backdrop-blur-md" onClick={closeModal} aria-hidden="true" />
          <section
            className="relative z-[150] w-full max-w-2xl max-h-[90vh] overflow-y-auto rounded-[32px] border border-white/10 bg-gradient-to-br from-[#0d0711]/90 via-[#160b19]/75 to-[#0e0611]/88 shadow-[0_26px_64px_-18px_rgba(112,24,69,0.55)] backdrop-blur-2xl p-5 sm:p-6"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="flex items-start justify-between gap-3">
              <h2 className="text-xl font-semibold text-white">
                {editingQuiz ? 'Edit Quiz' : 'Create Quiz'}
              </h2>
              <button
                type="button"
                onClick={closeModal}
                className="inline-flex h-9 w-9 shrink-0 items-center justify-center rounded-full border border-white/15 bg-white/5 text-white/70 hover:border-white/30 hover:text-white transition"
              >
                <FiX size={16} />
              </button>
            </div>

            <form onSubmit={handleSave} className="mt-5 space-y-4">
              <label className="block text-xs font-semibold uppercase tracking-[0.2em] text-white/65">
                Title *
                <input
                  type="text"
                  value={form.title}
                  onChange={(e) => handleFieldChange('title', e.target.value)}
                  className="mt-2 w-full rounded-2xl border border-white/15 bg-white/5 px-4 py-2.5 text-sm text-white placeholder:text-white/30 focus:border-[#EFB078]/60 focus:outline-none"
                  placeholder="e.g. Ramadan Quiz 2026"
                  required
                />
              </label>

              <label className="block text-xs font-semibold uppercase tracking-[0.2em] text-white/65">
                Assessment Type
                <select value={form.assessmentType} onChange={(e) => handleFieldChange('assessmentType', e.target.value)} className="mt-2 w-full rounded-2xl border border-white/15 bg-[#160b17] px-4 py-2.5 text-sm text-white focus:border-[#EFB078]/60 focus:outline-none">
                  <option value="quiz">Knowledge quiz</option>
                  <option value="practical">Practical exam</option>
                </select>
              </label>

              <div className="grid gap-4 sm:grid-cols-2">
                <label className="block text-xs font-semibold uppercase tracking-[0.2em] text-white/65 sm:col-span-2">
                  Timer mode
                  <select
                    value={form.timerMode}
                    onChange={(e) => handleFieldChange('timerMode', e.target.value)}
                    className="mt-2 w-full rounded-2xl border border-white/15 bg-[#1b0d20] px-4 py-2.5 text-sm text-white focus:border-[#EFB078]/60 focus:outline-none"
                  >
                    <option value="none">No timer</option>
                    <option value="overall">Overall timer</option>
                    <option value="per-question">Timer per question</option>
                    <option value="both">Overall + per question</option>
                  </select>
                </label>
                <label className="block text-xs font-semibold uppercase tracking-[0.2em] text-white/65">
                  Start Date *
                  <input
                    type="datetime-local"
                    value={form.startDate}
                    onChange={(e) => handleFieldChange('startDate', e.target.value)}
                    className="mt-2 w-full rounded-2xl border border-white/15 bg-white/5 px-4 py-2.5 text-sm text-white focus:border-[#EFB078]/60 focus:outline-none"
                    required
                  />
                </label>
                <label className="block text-xs font-semibold uppercase tracking-[0.2em] text-white/65">
                  End Date *
                  <input
                    type="datetime-local"
                    value={form.endDate}
                    onChange={(e) => handleFieldChange('endDate', e.target.value)}
                    className="mt-2 w-full rounded-2xl border border-white/15 bg-white/5 px-4 py-2.5 text-sm text-white focus:border-[#EFB078]/60 focus:outline-none"
                    required
                  />
                </label>
              </div>

              <div className="grid gap-4 sm:grid-cols-2">
                <label className="block text-xs font-semibold uppercase tracking-[0.2em] text-white/65">
                  Allowed classes
                  <input
                    type="text"
                    value={form.allowedClasses}
                    onChange={(e) => handleFieldChange('allowedClasses', e.target.value)}
                    className="mt-2 w-full rounded-2xl border border-white/15 bg-white/5 px-4 py-2.5 text-sm text-white focus:border-[#EFB078]/60 focus:outline-none"
                    placeholder="Class 8, Class 9 (optional)"
                  />
                </label>
                <label className="mt-7 flex items-center gap-2.5 text-xs font-semibold uppercase tracking-[0.18em] text-white/65">
                  <input
                    type="checkbox"
                    checked={form.requireCompletedVideo}
                    onChange={(e) => handleFieldChange('requireCompletedVideo', e.target.checked)}
                    className="h-4 w-4 accent-[#EFB078]"
                  />
                  Require completed lesson
                </label>
              </div>

              <div className="grid gap-4 sm:grid-cols-2">
                <label className="block text-xs font-semibold uppercase tracking-[0.2em] text-white/65">
                  Number of Questions *
                  <input
                    type="text"
                    inputMode="numeric"
                    value={form.numberOfQuestions}
                    onChange={(e) => handleFieldChange('numberOfQuestions', e.target.value.replace(/\D/g, ''))}
                    className="mt-2 w-full rounded-2xl border border-white/15 bg-white/5 px-4 py-2.5 text-sm text-white focus:border-[#EFB078]/60 focus:outline-none"
                    required
                  />
                </label>
                <label className="block text-xs font-semibold uppercase tracking-[0.2em] text-white/65">
                  Options Count
                  <input
                    type="text"
                    inputMode="numeric"
                    value={form.optionsCount}
                    onChange={(e) => handleFieldChange('optionsCount', e.target.value.replace(/\D/g, ''))}
                    className="mt-2 w-full rounded-2xl border border-white/15 bg-white/5 px-4 py-2.5 text-sm text-white focus:border-[#EFB078]/60 focus:outline-none"
                    placeholder="Optional"
                  />
                </label>
              </div>

              <div className="grid gap-4 sm:grid-cols-2">
                <label className="block text-xs font-semibold uppercase tracking-[0.2em] text-white/65">
                  Overall Time Limit (seconds)
                  <input
                    type="text"
                    inputMode="numeric"
                    value={form.overallTimeLimit}
                    onChange={(e) => handleFieldChange('overallTimeLimit', e.target.value.replace(/\D/g, ''))}
                    className="mt-2 w-full rounded-2xl border border-white/15 bg-white/5 px-4 py-2.5 text-sm text-white focus:border-[#EFB078]/60 focus:outline-none"
                    placeholder="Optional"
                  />
                </label>
                <label className="block text-xs font-semibold uppercase tracking-[0.2em] text-white/65">
                  Per-Question Time Limit (seconds)
                  <input
                    type="text"
                    inputMode="numeric"
                    value={form.perQuestionTimeLimit}
                    onChange={(e) => handleFieldChange('perQuestionTimeLimit', e.target.value.replace(/\D/g, ''))}
                    className="mt-2 w-full rounded-2xl border border-white/15 bg-white/5 px-4 py-2.5 text-sm text-white focus:border-[#EFB078]/60 focus:outline-none"
                    placeholder="Optional"
                  />
                </label>
              </div>

              <div className="flex flex-wrap gap-6">
                <div className="text-xs font-semibold uppercase tracking-[0.2em] text-white/65 flex flex-col gap-2">
                  Randomization
                  <button
                    type="button"
                    aria-pressed={form.questionsRandomization}
                    onClick={() => handleFieldChange('questionsRandomization', !form.questionsRandomization)}
                    className={`relative inline-flex h-7 w-12 items-center rounded-full border border-white/15 transition ${
                      form.questionsRandomization ? 'bg-indigo-500/70' : 'bg-gray-700'
                    }`}
                  >
                    <span
                      className={`inline-block h-5 w-5 transform rounded-full bg-white shadow transition ${
                        form.questionsRandomization ? 'translate-x-5' : 'translate-x-1'
                      }`}
                    />
                  </button>
                </div>
                <div className="text-xs font-semibold uppercase tracking-[0.2em] text-white/65 flex flex-col gap-2">
                  Availability
                  <button
                    type="button"
                    aria-pressed={form.isEnable}
                    onClick={() => handleFieldChange('isEnable', !form.isEnable)}
                    className={`relative inline-flex h-7 w-12 items-center rounded-full border border-white/15 transition ${
                      form.isEnable ? 'bg-green-500/70' : 'bg-gray-700'
                    }`}
                  >
                    <span
                      className={`inline-block h-5 w-5 transform rounded-full bg-white shadow transition ${
                        form.isEnable ? 'translate-x-5' : 'translate-x-1'
                      }`}
                    />
                  </button>
                </div>
              </div>

              <div className="rounded-2xl border border-[#EFB078]/20 bg-[#EFB078]/5 p-4">
                <div className="flex flex-wrap items-start justify-between gap-3">
                  <div>
                    <h3 className="text-sm font-semibold text-white">Certificate settings</h3>
                    <p className="mt-1 text-xs text-white/55">Configure the certificate issued after this exam ends.</p>
                  </div>
                  <button
                    type="button"
                    aria-pressed={form.certificateEnabled}
                    onClick={() => handleFieldChange('certificateEnabled', !form.certificateEnabled)}
                    className={`relative inline-flex h-7 w-12 items-center rounded-full border border-white/15 transition ${form.certificateEnabled ? 'bg-[#EFB078]/80' : 'bg-gray-700'}`}
                  >
                    <span className={`inline-block h-5 w-5 transform rounded-full bg-white shadow transition ${form.certificateEnabled ? 'translate-x-5' : 'translate-x-1'}`} />
                  </button>
                </div>
                {form.certificateEnabled && (
                  <div className="mt-4 space-y-3">
                    <div className="grid gap-3 sm:grid-cols-2">
                      <label className="block text-xs font-semibold uppercase tracking-[0.16em] text-white/65">
                        Certificate title
                        <input value={form.certificateTitle} onChange={(e) => handleFieldChange('certificateTitle', e.target.value)} className="mt-2 w-full rounded-xl border border-white/15 bg-white/5 px-3 py-2 text-sm normal-case tracking-normal text-white focus:border-[#EFB078]/60 focus:outline-none" placeholder="Certificate of Achievement" />
                      </label>
                      <label className="block text-xs font-semibold uppercase tracking-[0.16em] text-white/65">
                        Minimum percentage
                        <input type="number" min="0" max="100" value={form.certificateMinimumPercentage} onChange={(e) => handleFieldChange('certificateMinimumPercentage', e.target.value)} className="mt-2 w-full rounded-xl border border-white/15 bg-white/5 px-3 py-2 text-sm normal-case tracking-normal text-white focus:border-[#EFB078]/60 focus:outline-none" />
                      </label>
                    </div>
                    <div className="grid gap-3 sm:grid-cols-2">
                      <label className="block text-xs font-semibold uppercase tracking-[0.16em] text-white/65">
                        Issuing organization
                        <input value={form.certificateIssuerName} onChange={(e) => handleFieldChange('certificateIssuerName', e.target.value)} className="mt-2 w-full rounded-xl border border-white/15 bg-white/5 px-3 py-2 text-sm normal-case tracking-normal text-white focus:border-[#EFB078]/60 focus:outline-none" placeholder="QSPOT Learning" />
                      </label>
                      <label className="block text-xs font-semibold uppercase tracking-[0.16em] text-white/65">
                        Signatory
                        <input value={form.certificateSignatoryName} onChange={(e) => handleFieldChange('certificateSignatoryName', e.target.value)} className="mt-2 w-full rounded-xl border border-white/15 bg-white/5 px-3 py-2 text-sm normal-case tracking-normal text-white focus:border-[#EFB078]/60 focus:outline-none" placeholder="Director / Principal" />
                      </label>
                    </div>
                    <label className="block text-xs font-semibold uppercase tracking-[0.16em] text-white/65">
                      Eligible classes (optional)
                      <input value={form.certificateEligibleClasses} onChange={(e) => handleFieldChange('certificateEligibleClasses', e.target.value)} className="mt-2 w-full rounded-xl border border-white/15 bg-white/5 px-3 py-2 text-sm normal-case tracking-normal text-white focus:border-[#EFB078]/60 focus:outline-none" placeholder="8, 9" />
                    </label>
                    <label className="block text-xs font-semibold uppercase tracking-[0.16em] text-white/65">
                      Certificate description
                      <textarea rows={2} value={form.certificateDescription} onChange={(e) => handleFieldChange('certificateDescription', e.target.value)} className="mt-2 w-full rounded-xl border border-white/15 bg-white/5 px-3 py-2 text-sm normal-case tracking-normal text-white focus:border-[#EFB078]/60 focus:outline-none" />
                    </label>
                  </div>
                )}
              </div>

              {formError && (
                <div className="rounded-2xl border border-red-500/30 bg-red-500/10 px-4 py-3 text-sm text-red-200">
                  {formError}
                </div>
              )}

              <div className="flex items-center justify-end gap-3 pt-2">
                <button
                  type="button"
                  onClick={closeModal}
                  className="inline-flex items-center gap-2 px-4 py-2 rounded-xl border border-white/15 text-white hover:border-white/30 transition"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={saving}
                  className="inline-flex items-center gap-2 rounded-xl bg-gradient-to-r from-[#8C2852] via-[#B74A6D] to-[#F0B47F] px-5 py-2.5 text-sm font-semibold text-white shadow-[0_8px_20px_rgba(112,24,69,0.25)] transition-all hover:scale-[1.01] disabled:opacity-50"
                >
                  <FiSave size={16} /> {saving ? 'Saving...' : 'Save Quiz'}
                </button>
              </div>
            </form>
          </section>
        </div>
      )}
    </div>
  );
};

export default QuizzesPage;
