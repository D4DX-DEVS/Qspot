import React, { useEffect, useMemo, useState } from 'react';
import { useSearchParams, useNavigate, Navigate } from 'react-router-dom';
import {
  FiTrash2,
  FiX,
  FiEdit2,
  FiPlus,
  FiChevronRight,
  FiSearch,
  FiLayers,
  FiArrowLeft
} from 'react-icons/fi';
import Sidebar from '../components/Sidebar';
import ConfirmDialog from '../components/dialogs/ConfirmDialog';
import ErrorState from '../components/ui/ErrorState';
import Spinner from '../components/ui/Spinner';
import Modal from '../components/ui/Modal';
import usePageTitle from '../hooks/usePageTitle';
import apiClient from '../api/client';
import {
  QUESTION_TYPE_OPTIONS,
  DIFFICULTY_OPTIONS,
  isTrueFalseType,
  parseOptionsList,
  questionToFormShape
} from '../utils/quizQuestion';
import brandIcon from '../assets/Icon.png';

// Quiz questions are admin-only (CONTRACT.md): GET /api/quiz-questions?quizId=
// returns { items, total, page, limit } including correct_answer. Every
// question here MUST belong to a quiz — the unscoped /admin/quiz mode
// (no quizId) was removed per GAP-REPORT D6 / C4, so this page redirects to
// the quiz list if it's opened without one.

const createBlankOption = () => ({ en: '', ml: '' });
const createDefaultQuestionForm = () => ({
  type: QUESTION_TYPE_OPTIONS[0],
  difficulty: DIFFICULTY_OPTIONS[0],
  question_en: '',
  question_ml: '',
  options: [createBlankOption(), createBlankOption()],
  correctIndex: null
});

const formatPreview = (value, limit = 160) => {
  if (!value) return '';
  const trimmed = value.trim();
  return trimmed.length <= limit ? trimmed : `${trimmed.slice(0, limit)}…`;
};

const QuizPage = () => {
  const [searchParams] = useSearchParams();
  const navigate = useNavigate();
  const quizId = searchParams.get('quizId');

  const [scopedQuiz, setScopedQuiz] = useState(null);
  const [scopedQuizError, setScopedQuizError] = useState('');

  const [questionsLoading, setQuestionsLoading] = useState(true);
  const [questionsError, setQuestionsError] = useState('');
  const [questions, setQuestions] = useState([]);
  const [questionPage, setQuestionPage] = useState(1);
  const [questionTotal, setQuestionTotal] = useState(0);
  const questionPageSize = 20;
  const questionTotalPages = Math.max(1, Math.ceil(questionTotal / questionPageSize));
  const [detailLoading, setDetailLoading] = useState(false);
  const [questionSearch, setQuestionSearch] = useState('');
  const [difficultyFilter, setDifficultyFilter] = useState('all');
  const [showQuestionEditor, setShowQuestionEditor] = useState(false);
  const [editingQuestion, setEditingQuestion] = useState(null);
  const [questionForm, setQuestionForm] = useState(createDefaultQuestionForm);
  const [questionSaving, setQuestionSaving] = useState(false);
  const [questionFormError, setQuestionFormError] = useState('');
  const [questionDeleteTarget, setQuestionDeleteTarget] = useState(null);
  const [activeQuestionDetail, setActiveQuestionDetail] = useState(null);

  usePageTitle(scopedQuiz?.title ? `${scopedQuiz.title} · Questions` : 'Quiz Questions');

  useEffect(() => {
    if (!quizId) return;
    fetchScopedQuiz();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [quizId]);

  useEffect(() => {
    if (!quizId) return;
    fetchQuestions(questionPage);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [quizId, questionPage]);

  const fetchScopedQuiz = async () => {
    try {
      setScopedQuizError('');
      const response = await apiClient.get(`/quiz-definitions/${quizId}`);
      setScopedQuiz(response.data);
    } catch (error) {
      setScopedQuizError(error.message || 'Failed to load quiz');
    }
  };

  const fetchQuestions = async (targetPage = questionPage) => {
    try {
      setQuestionsLoading(true);
      setQuestionsError('');
      const response = await apiClient.get('/quiz-questions', {
        params: { page: targetPage, limit: questionPageSize, quizId }
      });
      setQuestions(Array.isArray(response.data?.items) ? response.data.items : []);
      setQuestionTotal(response.data?.total || 0);
    } catch (error) {
      setQuestionsError(error.message || 'Failed to load quiz questions');
      setQuestions([]);
    } finally {
      setQuestionsLoading(false);
    }
  };

  const handleQuestionFieldChange = (field, value) => {
    setQuestionForm((prev) => ({ ...prev, [field]: value }));
  };

  const handleQuestionTypeChange = (nextType) => {
    setQuestionForm((prev) => {
      if (isTrueFalseType(nextType)) {
        const alreadyTrueFalse =
          prev.options.length === 2 &&
          prev.options[0].en.trim().toLowerCase() === 'true' &&
          prev.options[1].en.trim().toLowerCase() === 'false';
        const options = alreadyTrueFalse
          ? prev.options
          : [{ en: 'True', ml: '' }, { en: 'False', ml: '' }];
        return { ...prev, type: nextType, options, correctIndex: prev.correctIndex };
      }
      return { ...prev, type: nextType, options: [createBlankOption(), createBlankOption()], correctIndex: null };
    });
  };

  const handleOptionTextChange = (index, lang, value) => {
    setQuestionForm((prev) => ({
      ...prev,
      options: prev.options.map((option, i) => (i === index ? { ...option, [lang]: value } : option))
    }));
  };

  const handleAddOption = () => {
    setQuestionForm((prev) => ({ ...prev, options: [...prev.options, createBlankOption()] }));
  };

  const handleRemoveOption = (index) => {
    setQuestionForm((prev) => {
      const options = prev.options.filter((_, i) => i !== index);
      let correctIndex = prev.correctIndex;
      if (correctIndex === index) correctIndex = null;
      else if (correctIndex !== null && correctIndex > index) correctIndex -= 1;
      return { ...prev, options, correctIndex };
    });
  };

  const handleCorrectAnswerChange = (index) => {
    setQuestionForm((prev) => ({ ...prev, correctIndex: index }));
  };

  const openQuestionEditor = (question = null) => {
    if (question) {
      setQuestionForm(questionToFormShape(question));
      setEditingQuestion(question);
    } else {
      setQuestionForm(createDefaultQuestionForm());
      setEditingQuestion(null);
    }
    setQuestionFormError('');
    setShowQuestionEditor(true);
  };

  const closeQuestionEditor = () => {
    setShowQuestionEditor(false);
    setQuestionFormError('');
    setQuestionSaving(false);
    setEditingQuestion(null);
    setQuestionForm(createDefaultQuestionForm());
  };

  const handleSaveQuestion = async (event) => {
    event.preventDefault();

    const questionEn = questionForm.question_en.trim();
    const questionMl = questionForm.question_ml.trim();
    if (!questionEn || !questionMl) {
      setQuestionFormError('Please enter the question in both English and Malayalam.');
      return;
    }

    const trimmedOptions = questionForm.options.map((option) => ({
      en: option.en.trim(),
      ml: option.ml.trim()
    }));

    if (trimmedOptions.length < 2) {
      setQuestionFormError('Add at least two answer choices.');
      return;
    }
    if (trimmedOptions.some((option) => !option.en || !option.ml)) {
      setQuestionFormError('Every option needs both an English and a Malayalam answer.');
      return;
    }
    const seen = new Set();
    for (const option of trimmedOptions) {
      const key = option.en.toLowerCase();
      if (seen.has(key)) {
        setQuestionFormError('Each option must be different from the others.');
        return;
      }
      seen.add(key);
    }
    if (questionForm.correctIndex === null || !trimmedOptions[questionForm.correctIndex]) {
      setQuestionFormError('Select the correct answer.');
      return;
    }

    const payload = {
      type: questionForm.type,
      difficulty: questionForm.difficulty,
      question_en: questionEn,
      question_ml: questionMl,
      options_en: JSON.stringify(trimmedOptions.map((option) => option.en)),
      options_ml: JSON.stringify(trimmedOptions.map((option) => option.ml)),
      correct_answer: trimmedOptions[questionForm.correctIndex].en,
      quizId
    };

    try {
      setQuestionSaving(true);
      setQuestionFormError('');
      if (editingQuestion) {
        await apiClient.put(`/quiz-questions/${editingQuestion._id}`, payload);
      } else {
        await apiClient.post('/quiz-questions', payload);
      }
      closeQuestionEditor();
      fetchQuestions();
    } catch (error) {
      setQuestionFormError(error.message || 'Failed to save quiz question');
    } finally {
      setQuestionSaving(false);
    }
  };

  const handleDeleteQuestion = async (questionId) => {
    try {
      await apiClient.delete(`/quiz-questions/${questionId}`);
      fetchQuestions(questionPage);
    } catch (error) {
      setQuestionsError(error.message || 'Failed to delete quiz question');
    }
  };

  const openQuestionDetail = async (question) => {
    setActiveQuestionDetail(question);
    setDetailLoading(true);
    try {
      const response = await apiClient.get(`/quiz-questions/${question._id}`);
      setActiveQuestionDetail(response.data);
    } catch {
      // keep the summary row shown; detail fields will just be sparse
    } finally {
      setDetailLoading(false);
    }
  };

  const closeQuestionDetail = () => setActiveQuestionDetail(null);

  const filteredQuestions = useMemo(() => {
    const query = questionSearch.trim().toLowerCase();
    const difficulty = difficultyFilter.toLowerCase();
    return questions.filter((question) => {
      const matchesSearch =
        !query ||
        question.question_en?.toLowerCase().includes(query) ||
        question.question_ml?.toLowerCase().includes(query) ||
        question.type?.toLowerCase().includes(query) ||
        question.difficulty?.toLowerCase().includes(query);
      const matchesDifficulty = difficulty === 'all' || (question.difficulty || '').toLowerCase() === difficulty;
      return matchesSearch && matchesDifficulty;
    });
  }, [questionSearch, difficultyFilter, questions]);

  if (!quizId) {
    return <Navigate to="/admin/quizzes" replace />;
  }

  return (
    <div className="flex min-h-screen overflow-x-hidden bg-black">
      <Sidebar currentPage="quizzes" onNavigate={navigate} />

      <div className="flex-1 flex flex-col w-full pb-28 md:ml-64 md:pb-0">
        <main className="flex-1 p-6 md:p-8 flex flex-col gap-6">
          <button
            type="button"
            onClick={() => navigate('/admin/quizzes')}
            className="inline-flex items-center gap-2 text-xs font-semibold uppercase tracking-[0.2em] text-white/60 hover:text-[#EFB078] transition w-fit"
          >
            <FiArrowLeft size={14} /> Back to Quizzes
          </button>

          {scopedQuizError ? (
            <ErrorState message={scopedQuizError} onRetry={fetchScopedQuiz} />
          ) : (
            <div className="flex flex-col gap-1">
              <p className="text-xs uppercase tracking-[0.35em] text-white/50">Quiz Questions</p>
              <h1 className="text-2xl font-semibold text-white">{scopedQuiz?.title || 'Loading…'}</h1>
            </div>
          )}

          <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
            <div className="relative w-full sm:max-w-sm">
              <FiSearch className="absolute left-3 top-1/2 -translate-y-1/2 text-white/30" size={15} />
              <input
                type="search"
                value={questionSearch}
                onChange={(event) => setQuestionSearch(event.target.value)}
                placeholder="Search text, type, difficulty"
                className="w-full rounded-xl border border-white/12 bg-black/30 py-2.5 pl-9 pr-3 text-sm text-white placeholder:text-white/40 focus:border-[#EFB078]/50 focus:outline-none"
              />
            </div>
            <div className="flex flex-wrap gap-2">
              {['all', 'easy', 'medium', 'hard'].map((option) => {
                const checked = difficultyFilter === option;
                return (
                  <button
                    type="button"
                    key={option}
                    onClick={() => setDifficultyFilter(option)}
                    className={`inline-flex items-center gap-2 rounded-full border px-3 py-1.5 text-[11px] font-semibold uppercase tracking-[0.2em] transition ${
                      checked
                        ? 'border-[#EFB078]/70 bg-[#EFB078]/15 text-white'
                        : 'border-white/15 bg-white/5 text-white/60 hover:border-white/30 hover:text-white'
                    }`}
                  >
                    {option}
                  </button>
                );
              })}
            </div>
            <button
              onClick={() => openQuestionEditor()}
              className="inline-flex items-center justify-center gap-2 rounded-xl bg-gradient-to-r from-[#701845]/80 via-[#9E4B63]/75 to-[#EFB078]/80 px-4 py-2 text-sm font-semibold uppercase tracking-[0.2em] text-white shadow-[0_10px_28px_rgba(112,24,69,0.35)] transition hover:from-[#5a1538] hover:to-[#d49a6a]"
            >
              <FiPlus /> Add Question
            </button>
          </div>

          {questionsError && !questionsLoading && (
            <ErrorState message={questionsError} onRetry={() => fetchQuestions(questionPage)} />
          )}

          {questionsLoading ? (
            <Spinner />
          ) : filteredQuestions.length === 0 ? (
            <div className="rounded-3xl border border-dashed border-white/15 bg-white/5 px-8 py-12 text-center text-white/70">
              <p className="text-lg font-semibold">No questions yet</p>
              <p className="text-sm text-white/50 mt-2">Add your first entry to get this quiz ready.</p>
              <button
                onClick={() => openQuestionEditor()}
                className="mt-5 inline-flex items-center gap-2 rounded-xl border border-white/15 bg-white/10 px-4 py-2 text-sm font-semibold uppercase tracking-[0.2em] text-white transition hover:border-[#EFB078]/50 hover:text-[#EFB078]"
              >
                <FiPlus /> Create question
              </button>
            </div>
          ) : (
            <div className="grid grid-cols-1 gap-4 md:grid-cols-2 xl:grid-cols-3">
              {filteredQuestions.map((question) => {
                const difficulty = question.difficulty || 'NA';
                const difficultyTone = (() => {
                  const level = difficulty.toLowerCase();
                  if (level === 'easy') return 'border-green-500/40 bg-green-900/30 text-green-200';
                  if (level === 'medium') return 'border-amber-500/40 bg-amber-900/30 text-amber-200';
                  if (level === 'hard') return 'border-red-500/40 bg-red-900/30 text-red-200';
                  return 'border-white/20 bg-white/5 text-white/80';
                })();
                return (
                  <button
                    type="button"
                    key={question._id}
                    onClick={() => openQuestionDetail(question)}
                    className="group flex h-full flex-col gap-2 rounded-2xl border border-white/10 bg-gradient-to-br from-[#11060d]/75 via-[#1c0b18]/55 to-[#12060f]/75 p-4 text-left shadow-[0_10px_32px_rgba(0,0,0,0.35)] backdrop-blur-xl transition-all duration-200 hover:border-[#EFB078]/40"
                  >
                    <div className="flex items-center gap-2 text-[10px] uppercase tracking-[0.28em] text-white/60">
                      <span className="inline-flex items-center gap-1 rounded-full border border-white/20 bg-black/30 px-3 py-1 font-semibold">
                        <FiLayers /> {question.type || 'General'}
                      </span>
                      <span className={`inline-flex items-center gap-2 rounded-full border px-3 py-1 font-semibold ${difficultyTone}`}>
                        {difficulty}
                      </span>
                    </div>
                    <div className="flex items-start justify-between gap-2">
                      <div className="space-y-1">
                        <p className="text-base font-semibold text-white line-clamp-2">{question.question_en}</p>
                        <p className="text-sm text-white/65 line-clamp-2">{question.question_ml}</p>
                      </div>
                      <FiChevronRight className="flex-none text-white/40 transition group-hover:translate-x-1" />
                    </div>
                  </button>
                );
              })}
            </div>
          )}

          {!questionsLoading && questionTotalPages > 1 && (
            <div className="flex items-center justify-center gap-3 text-xs text-white/60">
              <button
                onClick={() => setQuestionPage((p) => Math.max(1, p - 1))}
                disabled={questionPage === 1}
                className="rounded-lg border border-white/10 bg-white/5 px-3 py-1 disabled:opacity-40"
              >
                Prev
              </button>
              <span>
                Page {questionPage} of {questionTotalPages}
              </span>
              <button
                onClick={() => setQuestionPage((p) => Math.min(questionTotalPages, p + 1))}
                disabled={questionPage === questionTotalPages}
                className="rounded-lg border border-white/10 bg-white/5 px-3 py-1 disabled:opacity-40"
              >
                Next
              </button>
            </div>
          )}
        </main>
      </div>

      {questionDeleteTarget && (
        <ConfirmDialog
          title="Delete Quiz Question"
          description="This will permanently remove the selected question from this quiz's bank. This action cannot be undone."
          confirmLabel="Delete"
          cancelLabel="Cancel"
          confirmVariant="danger"
          onConfirm={() => {
            handleDeleteQuestion(questionDeleteTarget._id);
            setQuestionDeleteTarget(null);
          }}
          onCancel={() => setQuestionDeleteTarget(null)}
        />
      )}

      {showQuestionEditor && (
        <Modal
          title={editingQuestion ? 'Edit Question' : 'Create Question'}
          subtitle="Question Manager"
          icon={brandIcon}
          onClose={closeQuestionEditor}
          maxWidth="max-w-3xl"
        >
          <form onSubmit={handleSaveQuestion} className="space-y-5">
            <div className="grid gap-4 sm:grid-cols-2">
              <label className="text-xs font-semibold uppercase tracking-[0.18em] text-white/60 flex flex-col gap-2">
                Question Type *
                <select
                  value={questionForm.type}
                  onChange={(event) => handleQuestionTypeChange(event.target.value)}
                  className="w-full rounded-2xl border border-white/15 bg-[#0d0711] px-4 py-3 text-white focus:border-[#EFB078] focus:outline-none"
                  required
                >
                  {QUESTION_TYPE_OPTIONS.map((option) => (
                    <option key={option} value={option}>
                      {option}
                    </option>
                  ))}
                </select>
              </label>
              <label className="text-xs font-semibold uppercase tracking-[0.18em] text-white/60 flex flex-col gap-2">
                Difficulty *
                <select
                  value={questionForm.difficulty}
                  onChange={(event) => handleQuestionFieldChange('difficulty', event.target.value)}
                  className="w-full rounded-2xl border border-white/15 bg-[#0d0711] px-4 py-3 text-white focus:border-[#EFB078] focus:outline-none"
                  required
                >
                  {DIFFICULTY_OPTIONS.map((option) => (
                    <option key={option} value={option}>
                      {option}
                    </option>
                  ))}
                </select>
              </label>
            </div>

            <div className="grid gap-4 sm:grid-cols-2">
              <label className="text-xs font-semibold uppercase tracking-[0.18em] text-white/60 flex flex-col gap-2">
                Question (English) *
                <textarea
                  value={questionForm.question_en}
                  onChange={(event) => handleQuestionFieldChange('question_en', event.target.value)}
                  className="h-28 w-full resize-none rounded-2xl border border-white/15 bg-transparent px-4 py-3 text-white placeholder:text-white/40 focus:border-[#EFB078] focus:outline-none"
                  required
                />
              </label>
              <label className="text-xs font-semibold uppercase tracking-[0.18em] text-white/60 flex flex-col gap-2">
                Question (Malayalam) *
                <textarea
                  value={questionForm.question_ml}
                  onChange={(event) => handleQuestionFieldChange('question_ml', event.target.value)}
                  className="h-28 w-full resize-none rounded-2xl border border-white/15 bg-transparent px-4 py-3 text-white placeholder:text-white/40 focus:border-[#EFB078] focus:outline-none"
                  required
                />
              </label>
            </div>

            <div className="space-y-3">
              <div className="flex items-center justify-between">
                <p className="text-xs font-semibold uppercase tracking-[0.18em] text-white/60">Answer Options</p>
                {!isTrueFalseType(questionForm.type) && (
                  <button
                    type="button"
                    onClick={handleAddOption}
                    className="inline-flex items-center gap-1.5 rounded-lg border border-white/12 bg-white/5 px-3 py-1.5 text-xs font-semibold text-white/80 transition hover:border-[#EFB078]/40 hover:text-[#EFB078]"
                  >
                    <FiPlus size={13} /> Add Option
                  </button>
                )}
              </div>

              <div className="space-y-3">
                {questionForm.options.map((option, index) => (
                  <div key={index} className="rounded-2xl border border-white/12 bg-black/20 p-3 sm:p-4">
                    <div className="mb-2 flex items-center justify-between gap-2">
                      <label className="flex items-center gap-2 text-xs font-semibold text-white/80">
                        <input
                          type="radio"
                          name="correct-answer"
                          checked={questionForm.correctIndex === index}
                          onChange={() => handleCorrectAnswerChange(index)}
                          className="h-4 w-4 accent-[#EFB078]"
                        />
                        Option {index + 1}{' '}
                        {questionForm.correctIndex === index && <span className="text-[#EFB078]">(Correct)</span>}
                      </label>
                      {!isTrueFalseType(questionForm.type) && questionForm.options.length > 2 && (
                        <button
                          type="button"
                          onClick={() => handleRemoveOption(index)}
                          aria-label={`Remove option ${index + 1}`}
                          className="inline-flex h-9 w-9 flex-shrink-0 items-center justify-center rounded-lg border border-red-400/25 bg-red-500/5 text-red-300 transition hover:border-red-300/50 hover:text-red-200"
                        >
                          <FiTrash2 size={13} />
                        </button>
                      )}
                    </div>
                    <div className="grid gap-3 sm:grid-cols-2">
                      <label className="flex flex-col gap-1.5 text-[11px] font-medium text-white/50">
                        English
                        <input
                          type="text"
                          value={option.en}
                          disabled={isTrueFalseType(questionForm.type)}
                          onChange={(event) => handleOptionTextChange(index, 'en', event.target.value)}
                          className="w-full rounded-xl border border-white/12 bg-transparent px-3 py-2 text-sm text-white placeholder:text-white/30 focus:border-[#EFB078] focus:outline-none disabled:text-white/60"
                          placeholder="Answer choice"
                        />
                      </label>
                      <label className="flex flex-col gap-1.5 text-[11px] font-medium text-white/50">
                        Malayalam *
                        <input
                          type="text"
                          value={option.ml}
                          onChange={(event) => handleOptionTextChange(index, 'ml', event.target.value)}
                          className="w-full rounded-xl border border-white/12 bg-transparent px-3 py-2 text-sm text-white placeholder:text-white/30 focus:border-[#EFB078] focus:outline-none"
                          placeholder="Answer choice"
                          required
                        />
                      </label>
                    </div>
                  </div>
                ))}
              </div>
            </div>

            {questionFormError && <ErrorState message={questionFormError} />}

            <div className="flex flex-wrap items-center justify-end gap-3 border-t border-white/10 pt-4">
              <button
                type="button"
                onClick={closeQuestionEditor}
                className="rounded-lg border border-white/10 bg-white/5 px-5 py-2.5 text-xs font-semibold uppercase tracking-[0.18em] text-white/75 transition-all hover:border-white/20 hover:bg-white/10 hover:text-white"
              >
                Cancel
              </button>
              <button
                type="submit"
                disabled={questionSaving}
                className="rounded-lg bg-gradient-to-r from-[#701845]/90 via-[#9E4B63]/80 to-[#EFB078]/85 px-5 py-2.5 text-xs font-semibold uppercase tracking-[0.18em] text-white shadow-[0_16px_34px_rgba(136,32,82,0.45)] transition-all hover:scale-[1.01] disabled:opacity-50"
              >
                {questionSaving ? 'Saving...' : 'Save Question'}
              </button>
            </div>
          </form>
        </Modal>
      )}

      {activeQuestionDetail && (
        <Modal
          title={formatPreview(activeQuestionDetail.question_en, 60) || 'Question'}
          subtitle="Question Detail"
          icon={brandIcon}
          onClose={closeQuestionDetail}
          maxWidth="max-w-4xl"
        >
          <div className="space-y-6">
            {detailLoading && (
              <div className="h-1 w-full overflow-hidden rounded-full bg-white/10">
                <div className="h-full w-1/3 animate-pulse rounded-full bg-[#EFB078]/70" />
              </div>
            )}
            <div className="flex flex-wrap justify-end gap-2">
              <button
                type="button"
                onClick={() => {
                  openQuestionEditor(activeQuestionDetail);
                  closeQuestionDetail();
                }}
                className="inline-flex items-center gap-1.5 rounded-lg border border-white/12 bg-white/5 px-3 py-1.5 text-xs font-semibold text-white/80 hover:border-[#EFB078]/40 hover:text-[#EFB078]"
              >
                <FiEdit2 size={13} /> Edit
              </button>
              <button
                type="button"
                onClick={() => {
                  setQuestionDeleteTarget(activeQuestionDetail);
                  closeQuestionDetail();
                }}
                className="inline-flex items-center gap-1.5 rounded-lg border border-red-400/30 bg-red-500/10 px-3 py-1.5 text-xs font-semibold text-red-300 hover:border-red-300/60 hover:text-red-200"
              >
                <FiTrash2 size={13} /> Delete
              </button>
            </div>
            <div className="rounded-2xl border border-white/12 bg-black/25 p-5">
              <p className="text-xs font-semibold uppercase tracking-[0.2em] text-white/55 mb-3">Question (English)</p>
              <p className="text-base text-white/90">{activeQuestionDetail.question_en}</p>
              <p className="mt-4 text-xs font-semibold uppercase tracking-[0.2em] text-white/55">Question (Malayalam)</p>
              <p className="mt-2 text-sm text-white/85">{activeQuestionDetail.question_ml}</p>
            </div>
            <div className="grid gap-4 md:grid-cols-2">
              {['options_en', 'options_ml'].map((key) => {
                const options = parseOptionsList(activeQuestionDetail[key]).slice(0, 6);
                return (
                  <div key={key} className="rounded-2xl border border-white/10 bg-black/30 p-4">
                    <p className="text-[11px] uppercase tracking-[0.3em] text-white/40 mb-2">
                      {key === 'options_en' ? 'Options English' : 'Options Malayalam'}
                    </p>
                    <div className="flex flex-wrap gap-2">
                      {options.length === 0 ? (
                        <span className="text-xs text-white/40">NA</span>
                      ) : (
                        options.map((option) => (
                          <span key={option} className="rounded-xl border border-white/10 px-3 py-1 text-xs text-white/80">
                            {formatPreview(option, 50)}
                          </span>
                        ))
                      )}
                    </div>
                  </div>
                );
              })}
            </div>
            <div className="rounded-2xl border border-white/12 bg-black/30 p-4 text-sm text-white/80">
              <span className="text-white/40 text-[11px] uppercase tracking-[0.3em] block mb-2">Correct Answer</span>
              <p className="text-white font-semibold">{activeQuestionDetail.correct_answer}</p>
            </div>
          </div>
        </Modal>
      )}
    </div>
  );
};

export default QuizPage;
