import React, { useEffect, useMemo, useRef, useState } from 'react';
import axios from 'axios';
import {
  FiClock,
  FiCalendar,
  FiSave,
  FiTrash2,
  FiX,
  FiPower,
  FiActivity,
  FiEdit2,
  FiPlus,
  FiChevronDown,
  FiChevronLeft,
  FiChevronRight,
  FiBookOpen,
  FiSearch,
  FiLayers
} from 'react-icons/fi';
import Sidebar from '../components/Sidebar';
import ConfirmDialog from '../components/dialogs/ConfirmDialog';
import brandIcon from '../assets/Icon.png';

const weekDays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

const padNumber = (value) => value.toString().padStart(2, '0');

const formatDatePart = (isoDateTime) => {
  if (!isoDateTime) return '';
  const date = new Date(isoDateTime);
  if (Number.isNaN(date.getTime())) return '';
  return `${date.getFullYear()}-${padNumber(date.getMonth() + 1)}-${padNumber(date.getDate())}`;
};

const formatTimePart = (isoDateTime) => {
  if (!isoDateTime) return '';
  const date = new Date(isoDateTime);
  if (Number.isNaN(date.getTime())) return '';
  return `${padNumber(date.getHours())}:${padNumber(date.getMinutes())}`;
};

const combineDateTimeParts = (datePart, timePart) => {
  if (!datePart || !timePart) return '';
  return `${datePart}T${timePart}`;
};

const formatTimeDisplay = (timePart) => {
  if (!timePart) return '';
  const [hourStr, minuteStr] = timePart.split(':');
  const hour = Number(hourStr);
  if (Number.isNaN(hour)) return '';
  const period = hour >= 12 ? 'PM' : 'AM';
  const displayHour = ((hour + 11) % 12) + 1;
  return `${displayHour}:${minuteStr} ${period}`;
};

const formatDateTime = (isoString) => {
  if (!isoString) return 'NA';
  const d = new Date(isoString);
  return `${d.toLocaleDateString()} ${d.toLocaleTimeString()}`;
};

const DEFAULT_QUESTION_FORM = {
  type: '',
  question_en: '',
  question_ml: '',
  options_en: '',
  options_ml: '',
  correct_answer: '',
  difficulty: ''
};

const parseOptionsList = (value) => {
  if (!value) return [];
  try {
    const parsed = JSON.parse(value);
    if (Array.isArray(parsed)) {
      return parsed.map((item) => item?.toString?.().trim()).filter(Boolean);
    }
  } catch (error) {
    // fall back to splitting string values
  }
  return value
    .split(/\r?\n|,/)
    .map((item) => item.trim())
    .filter(Boolean);
};

const formatPreview = (value, limit = 160) => {
  if (!value) return '';
  const trimmed = value.trim();
  if (trimmed.length <= limit) return trimmed;
  return `${trimmed.slice(0, limit)}…`;
};

const formatRelativeTime = (isoString) => {
  if (!isoString) return 'NA';
  const target = new Date(isoString);
  const now = new Date();
  const diff = now - target;
  if (Number.isNaN(diff)) return 'NA';
  const minutes = Math.floor(diff / 60000);
  if (minutes < 1) return 'Just now';
  if (minutes < 60) return `${minutes}m ago`;
  const hours = Math.floor(minutes / 60);
  if (hours < 24) return `${hours}h ago`;
  const days = Math.floor(hours / 24);
  if (days < 7) return `${days}d ago`;
  return target.toLocaleDateString();
};

const getHourDisplayFromValue = (timeValue) => {
  if (!timeValue) return '';
  const [hourStr] = timeValue.split(':');
  const hour24 = Number(hourStr);
  if (Number.isNaN(hour24)) return '';
  if (hour24 === 0) return '12';
  if (hour24 > 12) return String(hour24 - 12).padStart(2, '0');
  return padNumber(hour24);
};

const getMinuteDisplayFromValue = (timeValue) => {
  if (!timeValue) return '';
  const [, minuteStr] = timeValue.split(':');
  const minuteValue = Number(minuteStr);
  if (Number.isNaN(minuteValue)) return '';
  return padNumber(minuteValue);
};

const getPeriodDisplayFromValue = (timeValue) => {
  if (!timeValue) return 'AM';
  const [hourStr] = timeValue.split(':');
  const hour24 = Number(hourStr);
  if (Number.isNaN(hour24)) return 'AM';
  return hour24 >= 12 ? 'PM' : 'AM';
};

const QuizPage = () => {
  const baseURL = import.meta.env.VITE_API_BASE_URL;
  const token = useMemo(() => localStorage.getItem('adminToken'), []);
  const [configLoading, setConfigLoading] = useState(true);
  const [configError, setConfigError] = useState('');
  const [configMessage, setConfigMessage] = useState('');
  const [savingConfig, setSavingConfig] = useState(false);

  const [startDate, setStartDate] = useState('');
  const [startTime, setStartTime] = useState('');
  const [endDate, setEndDate] = useState('');
  const [endTime, setEndTime] = useState('');
  const [numberOfQuestions, setNumberOfQuestions] = useState('1');
  const [questionsRandomization, setQuestionsRandomization] = useState(false);
  const [isEnable, setIsEnable] = useState(false);
  const [showEditor, setShowEditor] = useState(false);
  const [showDeleteConfirm, setShowDeleteConfirm] = useState(false);

  const [questionsLoading, setQuestionsLoading] = useState(true);
  const [questionsError, setQuestionsError] = useState('');
  const [questions, setQuestions] = useState([]);
  const [questionSearch, setQuestionSearch] = useState('');
  const [difficultyFilter, setDifficultyFilter] = useState('all');
  const [showQuestionEditor, setShowQuestionEditor] = useState(false);
  const [editingQuestion, setEditingQuestion] = useState(null);
  const [questionForm, setQuestionForm] = useState(DEFAULT_QUESTION_FORM);
  const [questionSaving, setQuestionSaving] = useState(false);
  const [questionMessage, setQuestionMessage] = useState('');
  const [questionFormError, setQuestionFormError] = useState('');
  const [questionDeleteTarget, setQuestionDeleteTarget] = useState(null);
  const [activeQuestionDetail, setActiveQuestionDetail] = useState(null);
  const [successDialogOpen, setSuccessDialogOpen] = useState(false);
  const [successDialogMessage, setSuccessDialogMessage] = useState('');

  const handleNavigate = (path) => {
    window.location.href = path;
  };

  useEffect(() => {
    if (!baseURL) {
      setConfigError('Environment configuration error: API base URL not found');
      setConfigLoading(false);
      setQuestionsError('Environment configuration error: API base URL not found');
      setQuestionsLoading(false);
      return;
    }

    fetchConfig();
    fetchQuestions();
  }, [baseURL]);

  useEffect(() => {
    if (!configMessage) return;
    const timer = setTimeout(() => setConfigMessage(''), 4000);
    return () => clearTimeout(timer);
  }, [configMessage]);

  useEffect(() => {
    if (!questionMessage) return;
    const timer = setTimeout(() => setQuestionMessage(''), 4000);
    return () => clearTimeout(timer);
  }, [questionMessage]);

  useEffect(() => {
    if (!successDialogOpen) return undefined;
    const timer = setTimeout(() => {
      closeSuccessDialog();
    }, 2000);
    return () => clearTimeout(timer);
  }, [successDialogOpen]);

useEffect(() => {
  if (!showEditor) return;
  const previousOverflow = document.body.style.overflow;
  document.body.style.overflow = 'hidden';
  return () => {
    document.body.style.overflow = previousOverflow;
  };
}, [showEditor]);

useEffect(() => {
  if (!showQuestionEditor) return;
  const previousOverflow = document.body.style.overflow;
  document.body.style.overflow = 'hidden';
  return () => {
    document.body.style.overflow = previousOverflow;
  };
}, [showQuestionEditor]);

  const fetchConfig = async () => {
    if (!baseURL) return;
    try {
      setConfigLoading(true);
      setConfigError('');
      const response = await axios.get(`${baseURL}/quizzes/config`);
      const data = response.data;
      setStartDate(formatDatePart(data.startDate));
      setStartTime(formatTimePart(data.startDate));
      setEndDate(formatDatePart(data.endDate));
      setEndTime(formatTimePart(data.endDate));
      setNumberOfQuestions(String(data.numberOfQuestions ?? 1));
      setQuestionsRandomization(Boolean(data.questionsRandomization));
      setIsEnable(Boolean(data.isEnable));
    } catch (error) {
      if (error.response?.status === 404) {
        // No configuration yet
        setStartDate('');
        setStartTime('');
        setEndDate('');
        setEndTime('');
        setNumberOfQuestions('1');
        setQuestionsRandomization(false);
        setIsEnable(false);
        setConfigError('');
      } else {
        console.error('Error loading quiz configuration:', error);
        setConfigError('Failed to load quiz configuration');
      }
    } finally {
      setConfigLoading(false);
    }
  };

  const deleteQuizConfig = async () => {
    if (!baseURL) return;
    try {
      setConfigError('');
      setConfigMessage('');
      await axios.delete(`${baseURL}/quizzes/config`, {
        headers: {
          Authorization: `Bearer ${token}`
        }
      });

      setStartDate('');
      setStartTime('');
      setEndDate('');
      setEndTime('');
      setNumberOfQuestions('1');
      setQuestionsRandomization(false);
      setIsEnable(false);
      setShowEditor(false);
      setConfigMessage('Quiz configuration deleted.');
    } catch (error) {
      console.error('Error deleting quiz configuration:', error);
      setConfigError(error.response?.data?.message || 'Failed to delete quiz configuration');
    }
  };

  const fetchQuestions = async () => {
    if (!baseURL || !token) return;
    try {
      setQuestionsLoading(true);
      setQuestionsError('');
      const response = await axios.get(`${baseURL}/quiz-questions`, {
        headers: {
          Authorization: `Bearer ${token}`
        }
      });
      setQuestions(Array.isArray(response.data) ? response.data : []);
    } catch (error) {
      console.error('Error fetching quiz questions:', error);
      const message = error.response?.data?.message || 'Failed to load quiz questions';
      setQuestionsError(message);
      setQuestions([]);
    } finally {
      setQuestionsLoading(false);
    }
  };

  const handleSaveConfig = async (event) => {
    event.preventDefault();
    if (!baseURL) return;

    const startISO = combineDateTimeParts(startDate, startTime);
    const endISO = combineDateTimeParts(endDate, endTime);

    if (!startISO || !endISO) {
      setConfigError('Start and end date/time are required.');
      return;
    }

    if (new Date(startISO) >= new Date(endISO)) {
      setConfigError('Start date must be before end date.');
      return;
    }

    const totalQuestions = Number(numberOfQuestions);
    if (!totalQuestions || totalQuestions < 1) {
      setConfigError('Number of questions must be at least 1.');
      return;
    }

    try {
      setSavingConfig(true);
      setConfigError('');
      const payload = {
        startDate: startISO,
        endDate: endISO,
        numberOfQuestions: totalQuestions,
        questionsRandomization,
        isEnable
      };

      const response = await axios.post(`${baseURL}/quizzes/config`, payload, {
        headers: {
          Authorization: `Bearer ${token}`
        }
      });

      const successMessage = response.data?.message || 'Quiz configuration saved';
      setConfigMessage(successMessage);
      setShowEditor(false);
      openSuccessDialog(successMessage);
      fetchConfig();
      fetchQuestions();
    } catch (error) {
      console.error('Error saving quiz configuration:', error);
      const message = error.response?.data?.message || 'Failed to save configuration';
      setConfigError(message);
    } finally {
      setSavingConfig(false);
    }
  };

  const openSuccessDialog = (message) => {
    setSuccessDialogMessage(message);
    setSuccessDialogOpen(true);
  };

  const closeSuccessDialog = () => {
    setSuccessDialogOpen(false);
    setSuccessDialogMessage('');
  };

  const handleQuestionFieldChange = (field, value) => {
    setQuestionForm((prev) => ({
      ...prev,
      [field]: value
    }));
  };

  const openQuestionEditor = (question = null) => {
    if (question) {
      setQuestionForm({
        type: question.type || '',
        question_en: question.question_en || '',
        question_ml: question.question_ml || '',
        options_en: question.options_en || '',
        options_ml: question.options_ml || '',
        correct_answer: question.correct_answer || '',
        difficulty: question.difficulty || ''
      });
      setEditingQuestion(question);
    } else {
      setQuestionForm(DEFAULT_QUESTION_FORM);
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
    setQuestionForm(DEFAULT_QUESTION_FORM);
  };

  const handleSaveQuestion = async (event) => {
    event.preventDefault();
    if (!baseURL || !token) return;

    const payload = {
      type: questionForm.type.trim(),
      question_en: questionForm.question_en.trim(),
      question_ml: questionForm.question_ml.trim(),
      options_en: questionForm.options_en.trim(),
      options_ml: questionForm.options_ml.trim(),
      correct_answer: questionForm.correct_answer.trim(),
      difficulty: questionForm.difficulty.trim()
    };

    if (Object.values(payload).some((value) => !value)) {
      setQuestionFormError('All fields are required.');
      return;
    }

    try {
      setQuestionSaving(true);
      setQuestionFormError('');
      const url = editingQuestion
        ? `${baseURL}/quiz-questions/${editingQuestion._id}`
        : `${baseURL}/quiz-questions`;
      const method = editingQuestion ? axios.put : axios.post;
      const response = await method(url, payload, {
        headers: {
          Authorization: `Bearer ${token}`
        }
      });

      setQuestionMessage(
        response.data?.message ||
          `Quiz question ${editingQuestion ? 'updated' : 'created'} successfully`
      );
      setShowQuestionEditor(false);
      setEditingQuestion(null);
      setQuestionForm(DEFAULT_QUESTION_FORM);
      fetchQuestions();
    } catch (error) {
      console.error('Error saving quiz question:', error);
      const message = error.response?.data?.message || 'Failed to save quiz question';
      setQuestionFormError(message);
    } finally {
      setQuestionSaving(false);
    }
  };

  const handleDeleteQuestion = async (questionId) => {
    if (!baseURL || !token || !questionId) return;
    try {
      await axios.delete(`${baseURL}/quiz-questions/${questionId}`, {
        headers: {
          Authorization: `Bearer ${token}`
        }
      });
      setQuestionMessage('Quiz question deleted successfully');
      setQuestions((prev) => prev.filter((question) => question._id !== questionId));
    } catch (error) {
      console.error('Error deleting quiz question:', error);
      const message = error.response?.data?.message || 'Failed to delete quiz question';
      setQuestionsError(message);
    }
  };

  const openQuestionDetail = (question) => {
    setActiveQuestionDetail(question);
  };

  const closeQuestionDetail = () => {
    setActiveQuestionDetail(null);
  };


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

      const matchesDifficulty =
        difficulty === 'all' ||
        (question.difficulty || '').toLowerCase() === difficulty;

      return matchesSearch && matchesDifficulty;
    });
  }, [questionSearch, difficultyFilter, questions]);

  const questionSummary = useMemo(() => {
    const total = questions.length;
    const uniqueTypes = new Set(questions.map((question) => question.type || 'Unknown')).size;
    const difficultyCounts = questions.reduce((acc, question) => {
      const key = (question.difficulty || 'NA').toLowerCase();
      acc[key] = (acc[key] || 0) + 1;
      return acc;
    }, {});
    const [topDifficulty] =
      Object.entries(difficultyCounts).sort(([, aCount], [, bCount]) => bCount - aCount)[0] || [];
    const latestTimestamp = questions[0]?.updatedAt || questions[0]?.createdAt || null;

    return {
      total,
      uniqueTypes,
      topDifficulty: topDifficulty ? topDifficulty.toUpperCase() : 'NA',
      lastUpdated: latestTimestamp
    };
  }, [questions]);

  const startISO = useMemo(() => combineDateTimeParts(startDate, startTime), [startDate, startTime]);
  const endISO = useMemo(() => combineDateTimeParts(endDate, endTime), [endDate, endTime]);

  const hasConfig = Boolean(startISO && endISO);

  return (
    <div className="flex min-h-screen bg-black">
      <Sidebar currentPage="quiz" onNavigate={handleNavigate} />

      <div className="flex-1 flex flex-col ml-64">
        <main className="flex-1 p-6 md:p-8 flex flex-col items-center gap-10">
          <div className="w-full px-2 md:px-0 flex flex-col gap-8">
            <div className="space-y-2">
              <p className="text-xs uppercase tracking-[0.35em] text-white/50">Admin Dashboard</p>
              <h1 className="text-3xl font-semibold text-white">Quiz Management</h1>
            </div>

            <div className="w-full grid gap-5 lg:grid-cols-[minmax(240px,1fr)_minmax(0,1.5fr)] items-stretch">
              <div className="flex flex-col gap-4 h-full">
                <div className="rounded-2xl border border-white/10 bg-gradient-to-br from-[#0d050d]/85 via-[#190816]/60 to-[#080309]/75 px-4 py-3 shadow-[0_10px_24px_rgba(0,0,0,0.35)]">
                  <p className="text-[10px] uppercase tracking-[0.4em] text-white/45">Top Difficulty</p>
                  <p className="mt-1 text-3xl font-semibold text-white">{questionSummary.topDifficulty}</p>
                </div>

                <div className="rounded-2xl border border-white/10 bg-gradient-to-br from-[#0d050d]/80 via-[#190816]/60 to-[#080309]/75 p-4 shadow-[0_12px_34px_rgba(0,0,0,0.35)] space-y-3">
                  <p className="text-xs font-semibold uppercase tracking-[0.25em] text-white/60">
                    Question Filters
                  </p>
                  <div className="relative">
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
                        <label
                          key={option}
                          className={`inline-flex items-center gap-2 rounded-full border px-3 py-1.5 text-[11px] font-semibold uppercase tracking-[0.2em] cursor-pointer transition ${
                            checked
                              ? 'border-[#EFB078]/70 bg-[#EFB078]/15 text-white'
                              : 'border-white/15 bg-white/5 text-white/60 hover:border-white/30 hover:text-white'
                          }`}
                        >
                          <input
                            type="radio"
                            name="difficulty-filter"
                            value={option}
                            checked={checked}
                            onChange={() => setDifficultyFilter(option)}
                            className="sr-only"
                          />
                          <span
                            className={`h-2.5 w-2.5 rounded-full border ${
                              checked ? 'border-white bg-[#EFB078]' : 'border-white/40'
                            }`}
                          />
                          {option}
                        </label>
                      );
                    })}
                  </div>
                </div>

                <div className="rounded-2xl border border-white/10 bg-gradient-to-br from-[#0d050d]/80 via-[#190816]/60 to-[#080309]/75 p-4 shadow-[0_12px_34px_rgba(0,0,0,0.35)] space-y-3">
                  <p className="text-xs font-semibold uppercase tracking-[0.25em] text-white/60">Actions</p>
                  <button
                    onClick={() => openQuestionEditor()}
                    className="w-full inline-flex items-center justify-center gap-2 rounded-xl bg-gradient-to-r from-[#701845]/80 via-[#9E4B63]/75 to-[#EFB078]/80 px-4 py-2 text-sm font-semibold uppercase tracking-[0.2em] text-white shadow-[0_10px_28px_rgba(112,24,69,0.35)] transition hover:from-[#5a1538] hover:to-[#d49a6a]"
                  >
                    <FiPlus /> Add Question
                  </button>
                </div>
              </div>

               <div className="w-full max-w-2xl mx-auto">
                <section className="relative overflow-hidden rounded-[24px] border border-white/12 bg-gradient-to-br from-[#12060f]/78 via-[#1a0815]/65 to-[#10050c]/78 shadow-[0_12px_38px_-18px_rgba(112,24,69,0.55)] backdrop-blur-xl p-4 min-h-[360px] flex flex-col h-full">
                  <div className="flex flex-col md:flex-row md:items-start md:justify-between gap-3">
                    <div className="space-y-1">
                      <h1 className="text-2xl font-semibold text-white">
                        Quiz Configuration
                      </h1>
                      <p className="text-xs text-gray-400 uppercase tracking-[0.25em]">Live schedule overview</p>
                    </div>
                    <div className="flex items-center gap-2 self-start">
                      {hasConfig ? (
                        <>
                          <button
                            type="button"
                            onClick={() => setShowEditor(true)}
                            aria-label="Edit configuration"
                            className="inline-flex items-center justify-center h-9 w-9 rounded-xl border border-white/15 bg-white/5 text-white hover:border-[#EFB078]/40 hover:text-[#EFB078] transition"
                          >
                            <FiEdit2 />
                          </button>
                          <button
                            type="button"
                            onClick={() => setShowDeleteConfirm(true)}
                            aria-label="Delete quiz configuration"
                            className="inline-flex items-center justify-center h-9 w-9 rounded-xl border border-red-400/40 bg-red-500/10 text-red-300 hover:border-red-300/70 hover:text-red-200 transition"
                          >
                            <FiTrash2 />
                          </button>
                        </>
                      ) : (
                        <button
                          type="button"
                          onClick={() => setShowEditor(true)}
                          className="inline-flex items-center gap-2 rounded-xl border border-white/15 bg-white/5 px-3 py-2 text-sm font-semibold uppercase tracking-[0.25em] text-white hover:border-[#EFB078]/50 hover:text-[#EFB078] transition"
                        >
                          <FiPlus /> Add
                        </button>
                      )}
                    </div>
                  </div>

                  {configLoading ? (
                    <div className="flex flex-1 items-center justify-center py-10">
                      <div className="animate-spin rounded-full h-10 w-10 border-b-2 border-indigo-400"></div>
                    </div>
                  ) : hasConfig ? (
                    <dl className="mt-5 space-y-2 flex-1 overflow-y-auto pr-1">
                      <div className="flex items-center justify-between rounded-2xl border border-white/12 bg-gradient-to-r from-[#701845]/18 via-transparent to-transparent px-4 py-2.5">
                        <dt className="flex items-center gap-2 text-[11px] uppercase tracking-[0.3em] text-gray-400">
                          <FiCalendar className="text-[#EFB078]" /> Start
                        </dt>
                        <dd className="text-sm font-semibold text-white">{formatDateTime(startISO)}</dd>
                      </div>
                      <div className="flex items-center justify-between rounded-2xl border border-white/12 bg-gradient-to-r from-[#701845]/18 via-transparent to-transparent px-4 py-2.5">
                        <dt className="flex items-center gap-2 text-[11px] uppercase tracking-[0.3em] text-gray-400">
                          <FiClock className="text-[#EFB078]" /> End
                        </dt>
                        <dd className="text-sm font-semibold text-white">{formatDateTime(endISO)}</dd>
                      </div>
                      <div className="flex items-center justify-between rounded-2xl border border-white/12 bg-gradient-to-r from-[#701845]/18 via-transparent to-transparent px-4 py-2.5">
                        <dt className="flex items-center gap-2 text-[11px] uppercase tracking-[0.3em] text-gray-400">
                          <FiActivity className="text-[#EFB078]" /> Questions
                        </dt>
                        <dd className="text-sm font-semibold text-white">{numberOfQuestions}</dd>
                      </div>
                      <div className="flex items-center justify-between rounded-2xl border border-white/12 bg-gradient-to-r from-[#701845]/18 via-transparent to-transparent px-4 py-2.5">
                        <dt className="flex items-center gap-2 text-[11px] uppercase tracking-[0.3em] text-gray-400">
                          <FiPower className="text-[#EFB078]" /> Availability
                        </dt>
                        <dd className={`text-sm font-semibold ${isEnable ? 'text-green-300' : 'text-red-300'}`}>
                          {isEnable ? 'Enabled' : 'Disabled'}
                        </dd>
                      </div>
                      <div className="flex items-center justify-between rounded-2xl border border-white/12 bg-gradient-to-r from-[#701845]/18 via-transparent to-transparent px-4 py-2.5">
                        <dt className="text-[11px] uppercase tracking-[0.3em] text-gray-400">
                          Randomization
                        </dt>
                        <dd className="text-sm font-semibold text-white">
                          {questionsRandomization ? 'Enabled' : 'Disabled'}
                        </dd>
                      </div>
                    </dl>
                  ) : (
                    <div className="mt-6 flex flex-1 flex-col items-center justify-center gap-4 rounded-2xl border border-dashed border-white/15 bg-white/5 px-6 py-8 text-center text-gray-300">
                      <p className="text-sm">No quiz configuration yet. Click add to schedule the next quiz.</p>
                      <button
                        onClick={() => setShowEditor(true)}
                        className="inline-flex items-center gap-2 rounded-xl border border-white/15 bg-white/5 px-4 py-2 text-sm font-semibold uppercase tracking-[0.25em] text-white hover:border-[#EFB078]/45 hover:text-[#EFB078] transition"
                      >
                        <FiPlus /> Add configuration
                      </button>
                    </div>
                  )}
                  
                  {hasConfig && !showEditor && configError && (
                    <div className="mt-4 bg-red-900/20 border border-red-500/30 text-red-300 px-4 py-3 rounded-xl">
                      {configError}
                    </div>
                  )}
                </section>
              </div>
            </div>
          </div>

          <div className="w-full max-w-6xl px-2 md:px-0 space-y-4">
            {questionsError && (
              <div className="mb-4 rounded-2xl border border-red-500/30 bg-red-500/10 px-4 py-3 text-sm text-red-200">
                {questionsError}
              </div>
            )}

            {questionsLoading ? (
              <div className="flex justify-center items-center h-48">
                <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-[#EFB078]"></div>
              </div>
            ) : filteredQuestions.length === 0 ? (
              <div className="rounded-3xl border border-dashed border-white/15 bg-white/5 px-8 py-12 text-center text-white/70">
                <p className="text-lg font-semibold">No questions yet</p>
                <p className="text-sm text-white/50 mt-2">
                  Add your first entry to get the quiz preparation started.
                </p>
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
                      if (level === 'medium')
                        return 'border-amber-500/40 bg-amber-900/30 text-amber-200';
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
          </div>
        </main>
      </div>

      {showDeleteConfirm && (
        <ConfirmDialog
          title="Delete Quiz Configuration"
          description="This will remove the current quiz schedule and attempts will no longer be accepted. This action cannot be undone."
          confirmLabel="Delete"
          cancelLabel="Cancel"
          confirmVariant="danger"
          onConfirm={() => {
            setShowDeleteConfirm(false);
            deleteQuizConfig();
          }}
          onCancel={() => setShowDeleteConfirm(false)}
        />
      )}

      {questionDeleteTarget && (
        <ConfirmDialog
          title="Delete Quiz Question"
          description="This will permanently remove the selected question from the quiz bank. This action cannot be undone."
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

      {showEditor && (
        <div className="fixed inset-0 z-[140] flex items-center justify-center px-4 py-8 sm:px-6 lg:px-8">
          <div
            className="absolute inset-0 bg-black/70 backdrop-blur-md"
            onClick={() => setShowEditor(false)}
            aria-hidden="true"
          />
          <section
            className="relative z-[150] w-full max-w-2xl rounded-[32px] border border-white/10 bg-gradient-to-br from-[#0d0711]/90 via-[#160b19]/75 to-[#0e0611]/88 shadow-[0_26px_64px_-18px_rgba(112,24,69,0.55)] backdrop-blur-2xl p-5 sm:p-6 overflow-visible"
            onClick={(event) => event.stopPropagation()}
          >
            <div className="flex items-start justify-between gap-3">
              <div className="flex items-center gap-4">
                <div className="flex h-12 w-12 flex-shrink-0 items-center justify-center rounded-2xl border border-white/12 bg-black/60 shadow-[0_14px_32px_rgba(136,32,82,0.45)]">
                  <img src={brandIcon} alt="QSpot icon" className="h-7 w-7 object-contain" />
                </div>
                <div>
                  <p className="text-[11px] font-semibold uppercase tracking-[0.22em] text-white/50">
                    Quiz Schedule
                  </p>
                  <h2 className="mt-1 text-xl font-semibold text-white flex items-center gap-2">
                    {hasConfig ? 'Edit Configuration' : 'Create Configuration'}
                  </h2>
                </div>
              </div>
              <button
                type="button"
                onClick={() => setShowEditor(false)}
                className="inline-flex h-8 w-8 items-center justify-center rounded-full border border-white/15 bg-white/5 text-white/70 hover:border-white/30 hover:text-white transition"
                aria-label="Close configuration form"
              >
                <FiX size={16} />
              </button>
            </div>

            <form onSubmit={handleSaveConfig} className="mt-4 space-y-5">
              <div className="flex flex-col gap-4">
                <div className="flex flex-wrap gap-4">
                  <div className="flex-1 min-w-[200px] space-y-2">
                    <label className="text-xs font-semibold uppercase tracking-[0.2em] text-white/65">
                      Start Date *
                    </label>
                    <QuizDatePicker value={startDate} onChange={setStartDate} />
                  </div>
                  <div className="w-full sm:w-auto flex-1 min-w-[220px] space-y-2">
                    <label className="text-xs font-semibold uppercase tracking-[0.2em] text-white/65">
                      Start Time *
                    </label>
                    <QuizTimePicker value={startTime} onChange={setStartTime} />
                  </div>
                </div>
                <div className="flex flex-wrap gap-4">
                  <div className="flex-1 min-w-[200px] space-y-2">
                    <label className="text-xs font-semibold uppercase tracking-[0.2em] text-white/65">
                      End Date *
                    </label>
                    <QuizDatePicker value={endDate} onChange={setEndDate} />
                  </div>
                  <div className="w-full sm:w-auto flex-1 min-w-[220px] space-y-2">
                    <label className="text-xs font-semibold uppercase tracking-[0.2em] text-white/65">
                      End Time *
                    </label>
                    <QuizTimePicker value={endTime} onChange={setEndTime} />
                  </div>
                </div>
              </div>

              <div className="flex flex-wrap gap-6">
                <label className="text-xs font-semibold uppercase tracking-[0.2em] text-white/65 flex flex-col gap-2">
                  Number of Questions
                  <input
                    type="text"
                    inputMode="numeric"
                    pattern="[0-9]*"
                    autoComplete="off"
                    value={numberOfQuestions}
                    placeholder="e.g. 15"
                    onChange={(event) => {
                      const digits = event.target.value.replace(/\D/g, '').slice(0, 3);
                      setNumberOfQuestions(digits);
                    }}
                    className="w-32 rounded-2xl border border-white/15 bg-white/5 px-3 py-1.5 text-base font-semibold tracking-wide text-white placeholder:text-white/30 focus:border-[#EFB078]/60 focus:outline-none focus:ring-0"
                    required
                  />
                </label>
                <div className="text-xs font-semibold uppercase tracking-[0.2em] text-white/65 flex flex-col gap-2">
                  Availability
                  <div className="flex items-center gap-3">
                    <span className={`w-20 text-sm font-semibold text-center ${isEnable ? 'text-green-200' : 'text-white/50'}`}>
                      {isEnable ? 'Enabled' : 'Disabled'}
                    </span>
                    <button
                      type="button"
                      aria-pressed={isEnable}
                      onClick={() => setIsEnable((prev) => !prev)}
                      className={`relative inline-flex h-7 w-12 items-center rounded-full border border-white/15 transition ${
                        isEnable ? 'bg-green-500/70' : 'bg-gray-700'
                      }`}
                    >
                      <span
                        className={`inline-block h-5 w-5 transform rounded-full bg-white shadow transition ${
                          isEnable ? 'translate-x-5' : 'translate-x-1'
                        }`}
                      />
                    </button>
                  </div>
                </div>
                <div className="text-xs font-semibold uppercase tracking-[0.2em] text-white/65 flex flex-col gap-2">
                  Randomization
                  <div className="flex items-center gap-3">
                    <span className={`w-20 text-sm font-semibold text-center ${questionsRandomization ? 'text-indigo-200' : 'text-white/50'}`}>
                      {questionsRandomization ? 'Enabled' : 'Disabled'}
                    </span>
                    <button
                      type="button"
                      aria-pressed={questionsRandomization}
                      onClick={() => setQuestionsRandomization((prev) => !prev)}
                      className={`relative inline-flex h-7 w-12 items-center rounded-full border border-white/15 transition ${
                        questionsRandomization ? 'bg-indigo-500/70' : 'bg-gray-700'
                      }`}
                    >
                      <span
                        className={`inline-block h-5 w-5 transform rounded-full bg-white shadow transition ${
                          questionsRandomization ? 'translate-x-5' : 'translate-x-1'
                        }`}
                      />
                    </button>
                  </div>
                </div>
              </div>

              <div className="space-y-3">
                {configError && (
                  <div className="bg-red-900/20 border border-red-500/30 text-red-300 px-4 py-3 rounded-xl">
                    {configError}
                  </div>
                )}
                <div className="flex items-center justify-end gap-3">
                  <button
                    type="button"
                    onClick={() => setShowEditor(false)}
                    className="inline-flex items-center gap-2 px-4 py-2 rounded-xl border border-white/15 text-white hover:border-white/30 transition"
                  >
                    Cancel
                  </button>
                  <button
                    type="submit"
                    disabled={savingConfig || configLoading}
                    className="inline-flex items-center gap-2 rounded-xl bg-gradient-to-r from-[#8C2852] via-[#B74A6D] to-[#F0B47F] px-5 py-2.5 text-sm font-semibold text-white shadow-[0_8px_20px_rgba(112,24,69,0.25)] transition-all hover:scale-[1.01] disabled:opacity-50"
                  >
                    <FiSave size={16} /> {savingConfig ? 'Saving...' : 'Save Configuration'}
                  </button>
                </div>
              </div>
            </form>
          </section>
        </div>
      )}

      {activeQuestionDetail && (
        <div className="fixed inset-0 z-[150] flex items-start justify-center px-4 py-10 sm:px-6 lg:px-8">
          <div
            className="absolute inset-0 bg-black/70 backdrop-blur-md"
            onClick={closeQuestionDetail}
            aria-hidden="true"
          />
          <section className="relative z-[160] w-full max-w-4xl overflow-hidden rounded-[32px] border border-white/12 bg-gradient-to-br from-[#0a050d]/95 via-[#160717]/85 to-[#0a040d]/95 shadow-[0_26px_64px_-18px_rgba(112,24,69,0.55)]">
            <div className="flex items-start justify-between gap-4 px-6 py-5 border-b border-white/10">
              <div className="flex items-center gap-3">
                <img src={brandIcon} alt="Qspot logo" className="h-10 w-10 rounded-2xl border border-white/15 bg-black/40 p-1" />
                <div>
                  <p className="text-[11px] font-semibold uppercase tracking-[0.25em] text-white/50">
                    Question Detail
                  </p>
                  <h3 className="mt-1 text-2xl font-semibold text-white">
                    {activeQuestionDetail.type || 'General'}
                  </h3>
                </div>
              </div>
              <div className="flex items-center gap-1 text-white/70">
                <button
                  type="button"
                  onClick={() => {
                    openQuestionEditor(activeQuestionDetail);
                    closeQuestionDetail();
                  }}
                  className="p-2 hover:text-[#EFB078] transition"
                  aria-label="Edit question"
                >
                  <FiEdit2 size={18} />
                </button>
                <button
                  type="button"
                  onClick={() => {
                    setQuestionDeleteTarget(activeQuestionDetail);
                    closeQuestionDetail();
                  }}
                  className="p-2 hover:text-red-300 transition"
                  aria-label="Delete question"
                >
                  <FiTrash2 size={18} />
                </button>
                <button
                  type="button"
                  onClick={closeQuestionDetail}
                  className="p-2 hover:text-white transition"
                  aria-label="Close detail"
                >
                  <FiX size={20} />
                </button>
              </div>
            </div>
            <div className="max-h-[75vh] overflow-y-auto px-6 py-6 space-y-6">
              <div className="flex flex-wrap items-center gap-3 text-xs uppercase tracking-[0.3em] text-white/60">
                <span className="inline-flex items-center gap-1 rounded-full border border-white/20 bg-black/30 px-3 py-1 text-[10px] font-semibold">
                  <FiLayers /> {activeQuestionDetail.type || 'General'}
                </span>
                <span className="inline-flex items-center gap-2 rounded-full border border-white/15 bg-white/5 px-3 py-1 text-[10px] font-semibold">
                  {activeQuestionDetail.difficulty || 'NA'}
                </span>
              </div>
              <div className="rounded-2xl border border-white/12 bg-black/25 p-5 shadow-[0_12px_36px_rgba(0,0,0,0.35)]">
                <p className="text-xs font-semibold uppercase tracking-[0.2em] text-white/55 mb-3">
                  Question (English)
                </p>
                <p className="text-base text-white/90">{activeQuestionDetail.question_en}</p>
                <p className="mt-4 text-xs font-semibold uppercase tracking-[0.2em] text-white/55">
                  Question (Malayalam)
                </p>
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
                            <span
                              key={option}
                              className="rounded-xl border border-white/10 px-3 py-1 text-xs text-white/80"
                            >
                              {formatPreview(option, 50)}
                            </span>
                          ))
                        )}
                      </div>
                    </div>
                  );
                })}
              </div>
              <div className="grid gap-4 sm:grid-cols-2 text-sm text-white/80">
                <div className="rounded-2xl border border-white/12 bg-black/30 p-4">
                  <span className="text-white/40 text-[11px] uppercase tracking-[0.3em] block mb-2">
                    Correct Answer
                  </span>
                  <p className="text-white font-semibold">{activeQuestionDetail.correct_answer}</p>
                </div>
                <div className="rounded-2xl border border-white/12 bg-black/30 p-4">
                  <span className="text-white/40 text-[11px] uppercase tracking-[0.3em] block mb-2">
                    Difficulty
                  </span>
                  <p className="text-white font-semibold">{activeQuestionDetail.difficulty || 'NA'}</p>
                </div>
              </div>
            </div>
          </section>
        </div>
      )}

      {successDialogOpen && (
        <div className="fixed inset-0 z-[180] flex items-center justify-center bg-black/70 backdrop-blur-sm">
          <div className="relative w-full max-w-sm overflow-hidden rounded-[28px] border border-white/10 bg-gradient-to-br from-[#150612]/95 via-[#1f0918]/90 to-[#150612]/95 shadow-[0_24px_70px_rgba(0,0,0,0.55)] px-6 py-6 text-white">
            <div className="flex items-center gap-3">
              <div className="flex h-10 w-10 items-center justify-center rounded-2xl border border-white/12 bg-black/50">
                <img src={brandIcon} alt="QSpot icon" className="h-6 w-6 object-contain" />
              </div>
              <div>
                <p className="text-sm font-semibold uppercase tracking-[0.22em] text-white/60">
                  Success
                </p>
                <h4 className="text-lg font-semibold">Configuration Saved</h4>
              </div>
            </div>
            <p className="mt-4 text-sm text-white/80">
              {successDialogMessage || 'Quiz configuration created successfully.'}
            </p>
            <span className="absolute top-6 right-6 inline-flex h-1.5 w-1.5 rounded-full bg-gradient-to-r from-[#701845] to-[#EFB078]" />
          </div>
        </div>
      )}

      {showQuestionEditor && (
        <div className="fixed inset-0 z-[150] flex items-center justify-center px-4 py-10">
          <div
            className="absolute inset-0 bg-black/70 backdrop-blur-md"
            onClick={closeQuestionEditor}
            aria-hidden="true"
          />
          <section
            className="relative z-[160] w-full max-w-4xl overflow-hidden rounded-[32px] border border-white/12 bg-gradient-to-br from-[#0a050d]/95 via-[#160717]/85 to-[#0a040d]/95 p-6 shadow-[0_26px_64px_-18px_rgba(112,24,69,0.55)]"
            onClick={(event) => event.stopPropagation()}
          >
            <div className="flex items-start justify-between gap-6">
              <div className="flex items-center gap-4">
                <div className="flex h-12 w-12 items-center justify-center rounded-2xl border border-white/12 bg-black/50 shadow-[0_14px_36px_rgba(136,32,82,0.45)]">
                  <img src={brandIcon} alt="QSpot icon" className="h-7 w-7 object-contain" />
                </div>
                <div>
                  <p className="text-[11px] font-semibold uppercase tracking-[0.25em] text-white/50">
                    Question Manager
                  </p>
                  <h3 className="mt-1 text-2xl font-semibold text-white">
                    {editingQuestion ? 'Edit Question' : 'Create Question'}
                  </h3>
                </div>
              </div>
              <button
                type="button"
                onClick={closeQuestionEditor}
                className="inline-flex h-10 w-10 items-center justify-center rounded-full border border-white/15 bg-white/5 text-white/70 hover:border-white/30 hover:text-white transition"
                aria-label="Close question editor"
              >
                <FiX size={18} />
              </button>
            </div>

            <form onSubmit={handleSaveQuestion} className="mt-6 space-y-5">
              <div className="grid gap-4 sm:grid-cols-2">
                <label className="text-xs font-semibold uppercase tracking-[0.18em] text-white/60 flex flex-col gap-2">
                  Type *
                  <input
                    type="text"
                    value={questionForm.type}
                    onChange={(event) => handleQuestionFieldChange('type', event.target.value)}
                    className="w-full rounded-2xl border border-white/15 bg-transparent px-4 py-3 text-white placeholder:text-white/40 focus:border-[#EFB078] focus:outline-none"
                    placeholder="MCQ, True/False, etc."
                    required
                  />
                </label>
                <label className="text-xs font-semibold uppercase tracking-[0.18em] text-white/60 flex flex-col gap-2">
                  Difficulty *
                  <input
                    type="text"
                    value={questionForm.difficulty}
                    onChange={(event) => handleQuestionFieldChange('difficulty', event.target.value)}
                    className="w-full rounded-2xl border border-white/15 bg-transparent px-4 py-3 text-white placeholder:text-white/40 focus:border-[#EFB078] focus:outline-none"
                    placeholder="Easy, Medium, Hard"
                    required
                  />
                </label>
              </div>

              <div className="grid gap-4 sm:grid-cols-2">
                <label className="text-xs font-semibold uppercase tracking-[0.18em] text-white/60 flex flex-col gap-2">
                  Question (English) *
                  <textarea
                    value={questionForm.question_en}
                    onChange={(event) => handleQuestionFieldChange('question_en', event.target.value)}
                    className="h-28 w-full rounded-2xl border border-white/15 bg-transparent px-4 py-3 text-white placeholder:text-white/40 focus:border-[#EFB078] focus:outline-none"
                    required
                  />
                </label>
                <label className="text-xs font-semibold uppercase tracking-[0.18em] text-white/60 flex flex-col gap-2">
                  Question (Malayalam) *
                  <textarea
                    value={questionForm.question_ml}
                    onChange={(event) => handleQuestionFieldChange('question_ml', event.target.value)}
                    className="h-28 w-full rounded-2xl border border-white/15 bg-transparent px-4 py-3 text-white placeholder:text-white/40 focus:border-[#EFB078] focus:outline-none"
                    required
                  />
                </label>
              </div>

              <div className="grid gap-4 sm:grid-cols-2">
                <label className="text-xs font-semibold uppercase tracking-[0.18em] text-white/60 flex flex-col gap-2">
                  Options (English) *
                  <textarea
                    value={questionForm.options_en}
                    onChange={(event) => handleQuestionFieldChange('options_en', event.target.value)}
                    className="h-32 w-full rounded-2xl border border-white/15 bg-transparent px-4 py-3 text-white placeholder:text-white/40 focus:border-[#EFB078] focus:outline-none"
                    placeholder='One per line or JSON array e.g. ["A","B"]'
                    required
                  />
                </label>
                <label className="text-xs font-semibold uppercase tracking-[0.18em] text-white/60 flex flex-col gap-2">
                  Options (Malayalam) *
                  <textarea
                    value={questionForm.options_ml}
                    onChange={(event) => handleQuestionFieldChange('options_ml', event.target.value)}
                    className="h-32 w-full rounded-2xl border border-white/15 bg-transparent px-4 py-3 text-white placeholder:text-white/40 focus:border-[#EFB078] focus:outline-none"
                    required
                  />
                </label>
              </div>

              <label className="text-xs font-semibold uppercase tracking-[0.18em] text-white/60 flex flex-col gap-2">
                Correct Answer *
                <input
                  type="text"
                  value={questionForm.correct_answer}
                  onChange={(event) => handleQuestionFieldChange('correct_answer', event.target.value)}
                  className="w-full rounded-2xl border border-white/15 bg-transparent px-4 py-3 text-white placeholder:text-white/40 focus:border-[#EFB078] focus:outline-none"
                  required
                />
              </label>

              {questionFormError && (
                <div className="rounded-2xl border border-red-500/30 bg-red-500/10 px-4 py-3 text-sm text-red-200">
                  {questionFormError}
                </div>
              )}

              <div className="flex flex-wrap items-center justify-end gap-3 pt-2">
                <button
                  type="button"
                  onClick={closeQuestionEditor}
                  className="rounded-lg border border-white/10 bg-white/5 px-5 py-2.5 text-xs font-semibold uppercase tracking-[0.18em] text-white/75 transition-all duration-200 hover:border-white/20 hover:bg-white/10 hover:text-white focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-white/30"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={questionSaving}
                  className="rounded-lg bg-gradient-to-r from-[#701845]/90 via-[#9E4B63]/80 to-[#EFB078]/85 px-5 py-2.5 text-xs font-semibold uppercase tracking-[0.18em] text-white shadow-[0_16px_34px_rgba(136,32,82,0.45)] transition-all duration-200 hover:scale-[1.01] disabled:opacity-50 disabled:shadow-none focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#EFB078]/70"
                >
                  {questionSaving ? 'Saving...' : 'Save Question'}
                </button>
              </div>
            </form>
          </section>
        </div>
      )}
    </div>
  );
};

export default QuizPage;

const QuizDatePicker = ({ value, onChange }) => {
  const [open, setOpen] = useState(false);
  const containerRef = useRef(null);
  const selectedDate = value ? new Date(`${value}T00:00:00`) : null;
  const [viewDate, setViewDate] = useState(() => selectedDate || new Date());

  useEffect(() => {
    if (value) {
      const next = new Date(`${value}T00:00:00`);
      if (!Number.isNaN(next.getTime())) {
        setViewDate(next);
      }
    }
  }, [value]);

  useEffect(() => {
    const handleClickOutside = (event) => {
      if (containerRef.current && !containerRef.current.contains(event.target)) {
        setOpen(false);
      }
    };
    if (open) {
      document.addEventListener('mousedown', handleClickOutside);
      document.addEventListener('touchstart', handleClickOutside);
    }
    return () => {
      document.removeEventListener('mousedown', handleClickOutside);
      document.removeEventListener('touchstart', handleClickOutside);
    };
  }, [open]);

  const daysInMonth = useMemo(
    () => new Date(viewDate.getFullYear(), viewDate.getMonth() + 1, 0).getDate(),
    [viewDate],
  );

  const firstDayIndex = useMemo(
    () => new Date(viewDate.getFullYear(), viewDate.getMonth(), 1).getDay(),
    [viewDate],
  );

  const displayLabel = selectedDate
    ? selectedDate.toLocaleDateString(undefined, {
        month: 'short',
        day: 'numeric',
        year: 'numeric',
      })
    : 'Select date';

  const handleSelectDay = (day) => {
    const nextDate = new Date(viewDate.getFullYear(), viewDate.getMonth(), day, 0, 0, 0, 0);
    const dateStr = `${nextDate.getFullYear()}-${padNumber(nextDate.getMonth() + 1)}-${padNumber(
      nextDate.getDate(),
    )}`;
    onChange(dateStr);
    setOpen(false);
  };

  const handleClear = () => {
    onChange('');
    setOpen(false);
  };

  return (
    <div ref={containerRef} className="relative">
      <button
        type="button"
        onClick={() => setOpen((prev) => !prev)}
        className="flex w-full items-center justify-between rounded-2xl border border-white/10 bg-white/5 px-4 py-3 text-left text-sm text-white backdrop-blur-sm transition-all duration-200 hover:border-[#EFB078]/40 focus:outline-none focus:ring-0"
      >
        <span className={selectedDate ? 'text-white' : 'text-white/50'}>{displayLabel}</span>
        <div className="ml-3 flex items-center gap-2 text-white/60">
          <FiCalendar size={16} />
          <FiChevronDown
            size={16}
            className={`transition-transform ${open ? 'rotate-180 text-[#EFB078]' : ''}`}
          />
        </div>
      </button>

      {open && (
        <div className="absolute left-0 top-full z-[180] mt-2 w-fit min-w-[260px] overflow-hidden rounded-2xl border border-white/10 bg-gradient-to-br from-[#11060d]/95 via-[#1c0b18]/85 to-[#12060f]/95 shadow-[0_16px_48px_rgba(12,6,20,0.55)] backdrop-blur-xl">
          <div className="space-y-3 p-4">
            <div className="flex items-center justify-between">
              <button
                type="button"
                onClick={() =>
                  setViewDate((prev) => new Date(prev.getFullYear(), prev.getMonth() - 1, 1))
                }
                className="flex h-8 w-8 items-center justify-center rounded-full border border-white/10 bg-white/5 text-white/70 transition-all hover:border-[#EFB078]/30 hover:text-white"
              >
                <FiChevronLeft size={14} />
              </button>
              <div className="text-sm font-semibold text-white">
                {viewDate.toLocaleDateString(undefined, { month: 'long', year: 'numeric' })}
              </div>
              <button
                type="button"
                onClick={() =>
                  setViewDate((prev) => new Date(prev.getFullYear(), prev.getMonth() + 1, 1))
                }
                className="flex h-8 w-8 items-center justify-center rounded-full border border-white/10 bg-white/5 text-white/70 transition-all hover:border-[#EFB078]/30 hover:text-white"
              >
                <FiChevronRight size={14} />
              </button>
            </div>

            <div className="grid grid-cols-7 gap-0.5 text-center text-[10px] font-semibold text-white/50">
              {weekDays.map((day) => (
                <div key={day} className="py-1">
                  {day}
                </div>
              ))}
              {Array.from({ length: firstDayIndex }).map((_, index) => (
                <div key={`empty-${index}`} className="py-1" />
              ))}
              {Array.from({ length: daysInMonth }, (_, index) => {
                const day = index + 1;
                const isActive =
                  selectedDate &&
                  selectedDate.getFullYear() === viewDate.getFullYear() &&
                  selectedDate.getMonth() === viewDate.getMonth() &&
                  selectedDate.getDate() === day;
                return (
                  <button
                    type="button"
                    key={day}
                    onClick={() => handleSelectDay(day)}
                    className={`rounded-xl px-1.5 py-1.5 text-xs transition-all duration-150 ${
                      isActive
                        ? 'bg-gradient-to-r from-[#701845]/70 to-[#EFB078]/40 text-white shadow-[0_8px_22px_rgba(112,24,69,0.35)]'
                        : 'text-white/80 hover:bg-white/10 hover:text-white'
                    }`}
                  >
                    {day}
                  </button>
                );
              })}
            </div>

            <div className="flex items-center justify-between pt-1">
              <button
                type="button"
                onClick={handleClear}
                className="rounded-xl border border-white/10 bg-white/5 px-3 py-1.5 text-[10px] font-semibold uppercase tracking-[0.18em] text-white/65 transition-all hover:border-white/20 hover:bg-white/10 hover:text-white"
              >
                Clear
              </button>
              <button
                type="button"
                onClick={() => setOpen(false)}
                className="rounded-xl bg-gradient-to-r from-[#701845]/90 via-[#9E4B63]/80 to-[#EFB078]/85 px-4 py-1.5 text-[11px] font-semibold uppercase tracking-[0.18em] text-white shadow-[0_16px_34px_rgba(136,32,82,0.45)] transition-all duration-200 hover:scale-[1.01]"
              >
                Done
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

const QuizTimePicker = ({ value, onChange }) => {
  const [hour, setHour] = useState(() => getHourDisplayFromValue(value));
  const [minute, setMinute] = useState(() => getMinuteDisplayFromValue(value));
  const [period, setPeriod] = useState(() => getPeriodDisplayFromValue(value));

  useEffect(() => {
    setHour(getHourDisplayFromValue(value));
    setMinute(getMinuteDisplayFromValue(value));
    setPeriod(getPeriodDisplayFromValue(value));
  }, [value]);

  useEffect(() => {
    const hourNumber = Number(hour);
    const minuteNumber = Number(minute);

    if (
      !hour ||
      Number.isNaN(hourNumber) ||
      hourNumber < 1 ||
      hourNumber > 12 ||
      minute === '' ||
      Number.isNaN(minuteNumber) ||
      minuteNumber < 0 ||
      minuteNumber > 59
    ) {
      onChange('');
      return;
    }

    const hour24 =
      period === 'PM'
        ? hourNumber === 12
          ? 12
          : hourNumber + 12
        : hourNumber === 12
          ? 0
          : hourNumber;
    const nextValue = `${padNumber(hour24)}:${padNumber(minuteNumber)}`;
    onChange(nextValue);
  }, [hour, minute, period, onChange]);

  const handleHourInput = (event) => {
    const raw = event.target.value.replace(/\D/g, '');
    const digits = raw.slice(-2);
    if (digits === '') {
      setHour('');
      return;
    }
    const numeric = Number(digits);
    if (numeric < 1 || numeric > 12) return;
    setHour(digits);
  };

  const handleMinuteInput = (event) => {
    const raw = event.target.value.replace(/\D/g, '');
    const digits = raw.slice(-2);
    if (digits === '') {
      setMinute('');
      return;
    }
    const numeric = Number(digits);
    if (numeric > 59) return;
    setMinute(digits);
  };

  const buttonClasses = (active) =>
    active
      ? 'bg-gradient-to-r from-[#701845]/70 to-[#EFB078]/40 text-white shadow-[0_6px_18px_rgba(112,24,69,0.35)]'
      : 'bg-black/30 text-white/75 hover:bg-white/10 hover:text-white';

  return (
    <div className="flex w-full items-center gap-3 rounded-2xl border border-white/10 bg-white/5 px-4 py-1 text-sm text-white backdrop-blur-sm min-w-[220px] sm:min-w-[260px] flex-nowrap">
      <div className="flex items-center gap-3 flex-1">
        <input
          type="text"
          inputMode="numeric"
          pattern="[0-9]*"
          autoComplete="off"
          value={hour}
          placeholder="HH"
          onFocus={(event) => event.target.select()}
          onChange={handleHourInput}
          className="w-14 rounded-xl border border-white/12 bg-black/40 px-3 py-1 text-center text-base font-semibold text-white placeholder:text-white/30 focus:border-[#EFB078]/60 focus:outline-none focus:ring-0"
        />
        <span className="text-white/60 text-base font-semibold">:</span>
        <input
          type="text"
          inputMode="numeric"
          pattern="[0-9]*"
          autoComplete="off"
          value={minute}
          placeholder="MM"
          onFocus={(event) => event.target.select()}
          onChange={handleMinuteInput}
          className="w-14 rounded-xl border border-white/12 bg-black/40 px-3 py-1 text-center text-base font-semibold text-white placeholder:text-white/30 focus:border-[#EFB078]/60 focus:outline-none focus:ring-0"
        />
      </div>
      <div className="flex items-center gap-2 flex-none">
        <button
          type="button"
          onClick={() => setPeriod('AM')}
          className={`rounded-lg px-3 py-1 text-xs font-semibold uppercase tracking-[0.18em] transition-all ${buttonClasses(period === 'AM')}`}
        >
          AM
        </button>
        <button
          type="button"
          onClick={() => setPeriod('PM')}
          className={`rounded-lg px-3 py-1 text-xs font-semibold uppercase tracking-[0.18em] transition-all ${buttonClasses(period === 'PM')}`}
        >
          PM
        </button>
      </div>
    </div>
  );
};
