import React, { useState, useEffect, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import { FiTrash2, FiMessageSquare, FiSearch, FiChevronLeft, FiChevronRight, FiHelpCircle, FiClock, FiCheckCircle, FiUser, FiBookOpen, FiEdit2, FiX, FiEyeOff, FiEye } from 'react-icons/fi';
import ConfirmDialog from '../components/dialogs/ConfirmDialog';
import Sidebar from '../components/Sidebar';
import ErrorState from '../components/ui/ErrorState';
import usePageTitle from '../hooks/usePageTitle';
import apiClient from '../api/client';
import brandIcon from '../assets/Icon.png';

// Q&A is admin-only here (this page is behind RequireAuth): list comes from
// GET /api/questions/admin?status=&page&limit -> {items,total,page,limit}
// per CONTRACT.md, which also adds hide/unhide (PUT /admin/:id/status) and
// delete (DELETE /admin/:id) on top of the existing answer routes.
const QuestionsPage = () => {
  usePageTitle('Q&A');
  const navigate = useNavigate();
  const [questions, setQuestions] = useState([]);
  const [filteredQuestions, setFilteredQuestions] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [statusActionLoading, setStatusActionLoading] = useState(false);
  const [deleteQuestionTarget, setDeleteQuestionTarget] = useState(null);
  const [answerLoading, setAnswerLoading] = useState(false);
  const [answerText, setAnswerText] = useState('');
  const [answerMode, setAnswerMode] = useState('create'); // 'create' | 'update'
  const [expandedQuestionId, setExpandedQuestionId] = useState(null);
  const [expandedQuestion, setExpandedQuestion] = useState(null);
  const [detailLoading, setDetailLoading] = useState(false);
  const [detailError, setDetailError] = useState('');
  const [deleteConfirmOpen, setDeleteConfirmOpen] = useState(false);
  const [deleteLoading, setDeleteLoading] = useState(false);
  const [isEditingAnswer, setIsEditingAnswer] = useState(false);
  
  // Pagination and search states
  const [currentPage, setCurrentPage] = useState(1);
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState('all'); // 'all', 'answered', 'pending'
  const [filterOpen, setFilterOpen] = useState(false);
  const [speakerFilterOpen, setSpeakerFilterOpen] = useState(false);
  const filterRef = useRef(null);
  const speakerFilterRef = useRef(null);
  const filterOptions = [
    { label: 'All Questions', value: 'all' },
    { label: 'Answered', value: 'answered' },
    { label: 'Pending', value: 'pending' },
  ];
  const [speakerOptions, setSpeakerOptions] = useState([]);
  const [speakerFilter, setSpeakerFilter] = useState('all');
  const itemsPerPage = 10;

  useEffect(() => {
    fetchQuestions();
  }, []);

  useEffect(() => {
    if (!expandedQuestionId) return;
    const previousOverflow = document.body.style.overflow;
    document.body.style.overflow = 'hidden';
    return () => {
      document.body.style.overflow = previousOverflow;
    };
  }, [expandedQuestionId]);

  useEffect(() => {
    if (!filterOpen && !speakerFilterOpen) return;
    const handleClickOutside = (event) => {
      if (filterRef.current && !filterRef.current.contains(event.target)) {
        setFilterOpen(false);
      }
      if (speakerFilterRef.current && !speakerFilterRef.current.contains(event.target)) {
        setSpeakerFilterOpen(false);
      }
    };
    document.addEventListener('mousedown', handleClickOutside);
    document.addEventListener('touchstart', handleClickOutside);
    return () => {
      document.removeEventListener('mousedown', handleClickOutside);
      document.removeEventListener('touchstart', handleClickOutside);
    };
  }, [filterOpen, speakerFilterOpen]);

  // Filter questions based on search term and status filter
  useEffect(() => {
    let filtered = [...questions];

    if (searchTerm) {
      filtered = filtered.filter((question) =>
        question.description?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        question.faculty?.name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        question.subject?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        question.user?.name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        question.user?.class?.toLowerCase().includes(searchTerm.toLowerCase())
      );
    }

    if (statusFilter !== 'all') {
      filtered = filtered.filter((question) =>
        statusFilter === 'answered' ? question.isAnswered : !question.isAnswered
      );
    }

    if (speakerFilter !== 'all') {
      filtered = filtered.filter((question) =>
        question.faculty?.name?.toLowerCase() === speakerFilter.toLowerCase()
      );
    }

    setFilteredQuestions(filtered);
    setCurrentPage(1);
  }, [questions, searchTerm, statusFilter, speakerFilter]);

  const fetchQuestions = async () => {
    try {
      setLoading(true);
      setError('');
      // A generous limit keeps the existing client-side search/pagination
      // working; the admin endpoint itself is still paginated server-side.
      const response = await apiClient.get('/questions/admin', { params: { limit: 500 } });
      const data = response.data?.items || [];
      setQuestions(data);
      return data;
    } catch (err) {
      setError(err.message || 'Failed to fetch questions');
      return [];
    } finally {
      setLoading(false);
    }
  };

  const fetchSpeakers = async () => {
    try {
      const response = await apiClient.get('/speakers');
      const names = Array.from(
        new Set(
          (response.data || [])
            .map((speaker) => speaker?.name)
            .filter((name) => name && name.trim() !== '')
        )
      ).sort((a, b) => a.localeCompare(b));
      setSpeakerOptions(names);
    } catch {
      // Non-critical: speaker filter just stays empty.
    }
  };

  useEffect(() => {
    fetchSpeakers();
  }, []);

  const resetExpandedState = () => {
    setExpandedQuestionId(null);
    setExpandedQuestion(null);
    setDetailError('');
    setAnswerText('');
    setAnswerMode('create');
    setDetailLoading(false);
    setDeleteConfirmOpen(false);
    setDeleteLoading(false);
    setIsEditingAnswer(false);
  };

  const loadQuestionDetail = async (questionSummary) => {
    if (!questionSummary?._id) return;
    setExpandedQuestionId(questionSummary._id);
    setExpandedQuestion(questionSummary);
    setAnswerMode(questionSummary.isAnswered ? 'update' : 'create');
    setAnswerText('');
    setDetailError('');
    setDetailLoading(true);
    setDeleteConfirmOpen(false);
    setDeleteLoading(false);
    setIsEditingAnswer(false);
    try {
      const response = await apiClient.get(`/questions/admin/${questionSummary._id}`);
      const detail = {
        ...questionSummary,
        ...response.data,
      };
      setExpandedQuestion(detail);
      const hasAnswer = Boolean(detail.answer && detail.answer.trim());
      setAnswerMode(hasAnswer ? 'update' : 'create');
      setIsEditingAnswer(!hasAnswer);
      setAnswerText(hasAnswer ? detail.answer : '');
    } catch (err) {
      console.error('Error fetching question details:', err);
      setDetailError('Failed to load question details');
    } finally {
      setDetailLoading(false);
    }
  };

  const handleSelectQuestion = (questionSummary) => {
    if (!questionSummary) return;
    if (expandedQuestionId === questionSummary._id) {
      resetExpandedState();
      return;
    }
    loadQuestionDetail(questionSummary);
  };

  const submitAnswer = async () => {
    if (!expandedQuestion) return;
    if (!answerText.trim()) {
      alert('Answer is required');
      return;
    }
    try {
      setAnswerLoading(true);
      const questionId = expandedQuestion._id;
      const url = `/questions/${questionId}/answer`;
      if (answerMode === 'create') {
        await apiClient.post(url, { answer: answerText.trim() });
      } else {
        await apiClient.put(url, { answer: answerText.trim() });
      }
      setAnswerText('');
      const updatedList = await fetchQuestions();
      const updatedQuestion = updatedList.find((item) => item._id === questionId);
      if (updatedQuestion) {
        await loadQuestionDetail(updatedQuestion);
      } else {
        resetExpandedState();
      }
      setIsEditingAnswer(false);
    } catch (err) {
      alert(err.message || 'Failed to submit answer');
    } finally {
      setAnswerLoading(false);
    }
  };

  const deleteAnswer = async () => {
    if (!expandedQuestion || deleteLoading) return;
    try {
      setDeleteLoading(true);
      await apiClient.delete(`/questions/${expandedQuestion._id}/answer`);
      setDeleteConfirmOpen(false);
      setAnswerText('');
      const updatedList = await fetchQuestions();
      if (expandedQuestionId === expandedQuestion._id) {
        const updatedQuestion = updatedList.find((item) => item._id === expandedQuestion._id);
        if (updatedQuestion) {
          await loadQuestionDetail(updatedQuestion);
        } else {
          resetExpandedState();
        }
      }
      setIsEditingAnswer(false);
    } catch (err) {
      alert(err.message || 'Failed to delete answer');
    } finally {
      setDeleteLoading(false);
    }
  };

  // Hide/unhide a question (status: 'open' | 'hidden') and delete it outright
  // (GAP-REPORT R11 / CONTRACT.md admin Q&A moderation routes).
  const toggleQuestionStatus = async () => {
    if (!expandedQuestion) return;
    const nextStatus = expandedQuestion.status === 'hidden' ? 'open' : 'hidden';
    try {
      setStatusActionLoading(true);
      await apiClient.put(`/questions/admin/${expandedQuestion._id}/status`, { status: nextStatus });
      setExpandedQuestion((prev) => (prev ? { ...prev, status: nextStatus } : prev));
      const updatedList = await fetchQuestions();
      const updatedQuestion = updatedList.find((item) => item._id === expandedQuestion._id);
      if (updatedQuestion) setExpandedQuestion((prev) => ({ ...prev, ...updatedQuestion }));
    } catch (err) {
      alert(err.message || 'Failed to update question status');
    } finally {
      setStatusActionLoading(false);
    }
  };

  const deleteQuestion = async () => {
    if (!deleteQuestionTarget) return;
    try {
      await apiClient.delete(`/questions/admin/${deleteQuestionTarget._id}`);
      setDeleteQuestionTarget(null);
      if (expandedQuestionId === deleteQuestionTarget._id) resetExpandedState();
      fetchQuestions();
    } catch (err) {
      alert(err.message || 'Failed to delete question');
      setDeleteQuestionTarget(null);
    }
  };

  const handleDeletePrompt = () => {
    setDeleteConfirmOpen(true);
  };

  const handleCancelDelete = () => {
    if (deleteLoading) return;
    setDeleteConfirmOpen(false);
  };

  const handleStartEditAnswer = () => {
    if (!expandedQuestion) return;
    setAnswerMode('update');
    setIsEditingAnswer(true);
    setAnswerText(expandedQuestion.answer || '');
    setDeleteConfirmOpen(false);
  };

  const handleCancelEditAnswer = () => {
    setIsEditingAnswer(false);
    if (expandedQuestion?.answer) {
      setAnswerMode('update');
      setAnswerText(expandedQuestion.answer);
    } else {
      setAnswerMode('create');
      setAnswerText('');
    }
  };

  // Pagination logic
  const totalPages = Math.ceil(filteredQuestions.length / itemsPerPage);
const startIndex = (currentPage - 1) * itemsPerPage;
const endIndex = startIndex + itemsPerPage;
const currentQuestions = filteredQuestions.slice(startIndex, endIndex);

  const handlePageChange = (page) => {
    setCurrentPage(page);
  };

  // Statistics
  const answeredCount = questions.filter(q => q.isAnswered).length;
  const pendingCount = questions.filter(q => !q.isAnswered).length;

  return (
    <div className="flex min-h-screen overflow-x-hidden bg-black">
      <Sidebar currentPage="questions" onNavigate={navigate} />
      
      <div className="flex-1 flex flex-col w-full pb-28 md:ml-64 md:pb-0">
        <main className="flex-1 p-4">
          {/* Header Section */}
          <div className="mb-4">
            <div className="flex flex-col lg:flex-row lg:items-center lg:justify-between gap-4">
              <div>
                <h2 className="text-2xl font-bold text-white mb-1">Questions Management</h2>
                {/* <p className="text-gray-400 text-sm">View and manage all submitted questions from users</p> */}
              </div>
              
              {/* Statistics Cards */}
              <div className="flex flex-wrap gap-3">
                <div className="relative overflow-hidden rounded-2xl border border-white/10 bg-gradient-to-br from-[#11060d]/80 via-[#1c0b18]/60 to-[#12060f]/80 px-4 py-3 shadow-[0_8px_32px_rgba(112,24,69,0.25)] backdrop-blur-xl min-w-[100px] flex-1 sm:flex-none sm:min-w-[120px]">
                  <div className="flex items-center gap-2">
                    <div className="flex h-8 w-8 shrink-0 items-center justify-center rounded-xl bg-gradient-to-br from-[#701845]/40 to-[#EFB078]/30 border border-white/10">
                      <FiHelpCircle className="text-[#EFB078]" size={16} />
                    </div>
                    <div>
                      <p className="text-lg font-bold text-white">{questions.length}</p>
                      <p className="text-xs uppercase tracking-wide text-slate-300/70">Total</p>
                    </div>
                  </div>
                </div>
                <div className="relative overflow-hidden rounded-2xl border border-white/10 bg-gradient-to-br from-[#11060d]/80 via-[#1c0b18]/60 to-[#12060f]/80 px-4 py-3 shadow-[0_8px_32px_rgba(112,24,69,0.25)] backdrop-blur-xl min-w-[100px] flex-1 sm:flex-none sm:min-w-[120px]">
                  <div className="flex items-center gap-2">
                    <div className="flex h-8 w-8 shrink-0 items-center justify-center rounded-xl bg-gradient-to-br from-[#701845]/40 to-[#EFB078]/30 border border-white/10">
                      <FiCheckCircle className="text-[#EFB078]" size={16} />
                    </div>
                    <div>
                      <p className="text-lg font-bold text-white">{answeredCount}</p>
                      <p className="text-xs uppercase tracking-wide text-slate-300/70">Answered</p>
                    </div>
                  </div>
                </div>
                <div className="relative overflow-hidden rounded-2xl border border-white/10 bg-gradient-to-br from-[#11060d]/80 via-[#1c0b18]/60 to-[#12060f]/80 px-4 py-3 shadow-[0_8px_32px_rgba(112,24,69,0.25)] backdrop-blur-xl min-w-[100px] flex-1 sm:flex-none sm:min-w-[120px]">
                  <div className="flex items-center gap-2">
                    <div className="flex h-8 w-8 shrink-0 items-center justify-center rounded-xl bg-gradient-to-br from-[#701845]/40 to-[#EFB078]/30 border border-white/10">
                      <FiClock className="text-[#EFB078]" size={16} />
                    </div>
                    <div>
                      <p className="text-lg font-bold text-white">{pendingCount}</p>
                      <p className="text-xs uppercase tracking-wide text-slate-300/70">Pending</p>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            {/* Search and Filter Section */}
            <div className="mt-4 flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
              <div className="relative w-full sm:w-auto sm:min-w-[320px]">
                <FiSearch className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400" size={16} />
                <input
                  type="text"
                  placeholder="Search questions by content, faculty, subject, or user..."
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  className="w-full pl-9 pr-4 py-3 bg-gradient-to-br from-[#11060d]/60 via-[#1c0b18]/40 to-[#12060f]/60 border border-white/10 rounded-2xl text-white placeholder-slate-400 backdrop-blur-xl focus:outline-none focus:border-[#701845]/50 focus:ring-2 focus:ring-[#701845]/30 transition-all text-sm"
                />
              </div>
              <div className="flex flex-col gap-3 sm:flex-row sm:items-center">
                <div ref={filterRef} className="relative sm:min-w-[220px]">
                  <button
                    type="button"
                    onClick={() => {
                      setFilterOpen((prev) => !prev);
                      setSpeakerFilterOpen(false);
                    }}
                    className="flex w-full items-center justify-between rounded-2xl border border-white/10 bg-gradient-to-br from-[#11060d]/70 via-[#1c0b18]/50 to-[#12060f]/70 px-4 py-3 text-sm font-medium text-white backdrop-blur-xl transition-all hover:border-[#701845]/50 hover:from-[#701845]/30 hover:to-[#EFB078]/20"
                  >
                    <span className="text-white/85">
                      {filterOptions.find((option) => option.value === statusFilter)?.label || 'All Questions'}
                    </span>
                    <div className="flex h-7 w-7 items-center justify-center rounded-full border border-white/15 bg-white/5">
                      <FiChevronRight
                        size={14}
                        className={`transition-transform ${filterOpen ? 'rotate-90 text-[#EFB078]' : 'text-white/70'}`}
                      />
                    </div>
                  </button>
                  {filterOpen && (
                    <div className="absolute right-0 z-20 mt-2 w-full overflow-hidden rounded-2xl border border-white/12 bg-gradient-to-br from-[#11060d]/95 via-[#1c0b18]/80 to-[#12060f]/95 shadow-[0_18px_48px_rgba(0,0,0,0.35)] backdrop-blur-xl">
                      <div className="pointer-events-none absolute inset-x-0 top-0 h-px bg-white/10" />
                      <ul className="relative divide-y divide-white/10">
                        {filterOptions.map((option) => {
                          const isActive = option.value === statusFilter;
                          return (
                            <li key={option.value}>
                              <button
                                type="button"
                                onClick={() => {
                                  setStatusFilter(option.value);
                                  setFilterOpen(false);
                                }}
                                className={`flex w-full items-center justify-between px-4 py-3 text-sm transition-all ${
                                  isActive
                                    ? 'bg-gradient-to-r from-[#701845]/70 to-[#EFB078]/40 text-white shadow-[0_6px_18px_rgba(112,24,69,0.35)]'
                                    : 'text-white/75 hover:bg-white/10 hover:text-white'
                                }`}
                              >
                                <span>{option.label}</span>
                                {isActive && (
                                  <FiCheckCircle size={16} className="text-[#EFB078]" />
                                )}
                              </button>
                            </li>
                          );
                        })}
                      </ul>
                    </div>
                  )}
                </div>

                <div ref={speakerFilterRef} className="relative sm:min-w-[220px]">
                  <button
                    type="button"
                    onClick={() => {
                      setSpeakerFilterOpen((prev) => !prev);
                      setFilterOpen(false);
                    }}
                    className="flex w-full items-center justify-between rounded-2xl border border-white/10 bg-gradient-to-br from-[#11060d]/70 via-[#1c0b18]/50 to-[#12060f]/70 px-4 py-3 text-sm font-medium text-white backdrop-blur-xl transition-all hover:border-[#701845]/50 hover:from-[#701845]/30 hover:to-[#EFB078]/20"
                  >
                    <div className="flex items-center gap-2 text-white/85">
                      <FiUser size={14} className="text-[#EFB078]" />
                      <span>{speakerFilter === 'all' ? 'All Speakers' : speakerFilter}</span>
                    </div>
                    <div className="flex h-7 w-7 items-center justify-center rounded-full border border-white/15 bg-white/5">
                      <FiChevronRight
                        size={14}
                        className={`transition-transform ${speakerFilterOpen ? 'rotate-90 text-[#EFB078]' : 'text-white/70'}`}
                      />
                    </div>
                  </button>
                  {speakerFilterOpen && (
                    <div className="absolute right-0 z-20 mt-2 w-full overflow-hidden rounded-2xl border border-white/12 bg-gradient-to-br from-[#11060d]/95 via-[#1c0b18]/80 to-[#12060f]/95 shadow-[0_18px_48px_rgba(0,0,0,0.35)] backdrop-blur-xl">
                      <div className="pointer-events-none absolute inset-x-0 top-0 h-px bg-white/10" />
                      <ul className="relative divide-y divide-white/10">
                        {[
                          { label: 'All Speakers', value: 'all' },
                          ...speakerOptions.map((name) => ({ label: name, value: name })),
                        ].map((option) => {
                          const isActive = option.value === speakerFilter;
                          return (
                            <li key={option.value}>
                              <button
                                type="button"
                                onClick={() => {
                                  setSpeakerFilter(option.value);
                                  setSpeakerFilterOpen(false);
                                }}
                                className={`flex w-full items-center justify-between px-4 py-3 text-sm transition-all ${
                                  isActive
                                    ? 'bg-gradient-to-r from-[#701845]/70 to-[#EFB078]/40 text-white shadow-[0_6px_18px_rgba(112,24,69,0.35)]'
                                    : 'text-white/75 hover:bg-white/10 hover:text-white'
                                }`}
                              >
                                <span>{option.label}</span>
                                {isActive && (
                                  <FiCheckCircle size={16} className="text-[#EFB078]" />
                                )}
                              </button>
                            </li>
                          );
                        })}
                      </ul>
                    </div>
                  )}
                </div>
              </div>
            </div>
          </div>
          {loading ? (
            <div className="flex justify-center items-center h-64">
              <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-400"></div>
            </div>
          ) : error ? (
            <ErrorState message={error} onRetry={fetchQuestions} />
          ) : (
            <div className="space-y-4">
              {filteredQuestions.length === 0 ? (
                <div className="text-center py-8">
                  <FiHelpCircle className="mx-auto text-gray-500 mb-3" size={36} />
                  <p className="text-gray-400">
                    {searchTerm || statusFilter !== 'all' ? 'No questions found matching your criteria' : 'No questions found'}
                  </p>
                  {(searchTerm || statusFilter !== 'all') && (
                    <button
                      onClick={() => {
                        setSearchTerm('');
                        setStatusFilter('all');
                      }}
                      className="mt-2 text-indigo-400 hover:text-indigo-300 transition-colors text-sm"
                    >
                      Clear filters
                    </button>
                  )}
                </div>
              ) : (
                <>
                  <div className="grid grid-cols-1 gap-3 md:grid-cols-2 xl:grid-cols-3">
                    {currentQuestions.map((question) => {
                      const isSelected = question._id === expandedQuestionId;
                      const userInitial = question.user?.name?.charAt(0)?.toUpperCase() || '?';
                      return (
                        <button
                          key={question._id}
                          type="button"
                          onClick={() => handleSelectQuestion(question)}
                          className={`group relative flex w-full flex-col items-start gap-3 rounded-2xl border border-white/10 bg-gradient-to-br from-[#11060d]/70 via-[#1c0b18]/50 to-[#12060f]/70 p-4 text-left shadow-[0_8px_24px_rgba(112,24,69,0.22)] backdrop-blur-xl transition-all duration-200 ${
                            isSelected
                              ? 'border-[#EFB078]/60 shadow-[0_12px_36px_rgba(239,176,120,0.28)]'
                              : 'hover:border-[#701845]/45 hover:shadow-[0_12px_36px_rgba(112,24,69,0.32)]'
                          }`}
                        >
                          <div className="flex w-full items-start justify-between text-xs font-medium">
                            <span
                              className={`inline-flex items-center gap-1 rounded-full border px-2 py-0.5 ${
                                question.isAnswered
                                  ? 'border-green-500/40 bg-green-900/30 text-green-300'
                                  : 'border-yellow-500/40 bg-yellow-900/30 text-yellow-200'
                              }`}
                            >
                              {question.isAnswered ? (
                                <>
                                  <FiCheckCircle size={12} />
                                  Answered
                                </>
                              ) : (
                                <>
                                  <FiClock size={12} />
                                  Pending
                                </>
                              )}
                            </span>
                            <span className="text-white/45">
                              {question.createdAt ? new Date(question.createdAt).toLocaleDateString() : '—'}
                            </span>
                          </div>

                          <div className="flex w-full items-center gap-3">
                            <div className="flex h-10 w-10 items-center justify-center rounded-full border border-white/15 bg-gradient-to-br from-[#701845]/80 to-[#EFB078]/70 text-sm font-semibold text-white shadow-[0_4px_14px_rgba(112,24,69,0.35)]">
                              {userInitial}
                            </div>
                            <div className="flex flex-col">
                              <span className="text-sm font-semibold text-white">
                                {question.faculty?.name || 'Unknown Faculty'}
                              </span>
                              {question.faculty?.designation && (
                                <span className="text-xs text-white/60">{question.faculty.designation}</span>
                              )}
                            </div>
                          </div>

                          <div className="flex items-center gap-2 text-xs text-white/75">
                            <FiUser className="text-[#EFB078]" size={14} />
                            <span className="font-medium text-white">
                              {question.user?.name || 'Anonymous'}
                              {question.user?.class ? ` · Class ${question.user.class}` : ''}
                            </span>
                          </div>

                          <div className="flex items-center gap-2 text-xs text-white/75">
                            <FiBookOpen className="text-[#EFB078]" size={14} />
                            <span>{question.subject || 'Unknown Subject'}</span>
                          </div>
                        </button>
                      );
                    })}
                  </div>

                  {expandedQuestionId && (
                    <div className="fixed inset-0 z-[120] flex items-start justify-center overflow-y-auto px-4 py-6 sm:px-6 sm:py-10 lg:px-8">
                      <div
                        className="absolute inset-0 bg-black/70 backdrop-blur-md transition-opacity"
                        onClick={resetExpandedState}
                      />
                      <div className="relative w-full max-w-4xl mx-auto overflow-hidden rounded-3xl border border-white/10 bg-gradient-to-br from-[#11060d]/85 via-[#1c0b18]/65 to-[#12060f]/85 shadow-[0_24px_68px_rgba(112,24,69,0.5)] backdrop-blur-2xl">
                        <div className="pointer-events-none absolute inset-0 bg-[radial-gradient(circle_at_top_right,rgba(136,32,82,0.45),transparent_62%)]" />
                        <div className="relative max-h-[85vh] overflow-y-auto p-4 space-y-6 sm:p-6">
                          <div className="flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
                             <div className="space-y-3">
                               <div className="flex items-center gap-3">
                                 <div className="flex h-11 w-11 items-center justify-center rounded-2xl border border-white/15 bg-black/45 p-2 shadow-[0_10px_22px_rgba(112,24,69,0.45)]">
                                   <img src={brandIcon} alt="QSpot icon" className="h-full w-full object-contain" />
                                 </div>
                                 <div>
                                   <p className="text-[11px] font-semibold uppercase tracking-[0.22em] text-white/50">
                                     Faculty
                                   </p>
                                   <h3 className="mt-1 text-xl font-semibold text-white">
                                     {expandedQuestion?.faculty?.name || 'Unknown Faculty'}
                                   </h3>
                                   {expandedQuestion?.faculty?.designation && (
                                     <p className="text-sm text-white/60">
                                       {expandedQuestion.faculty.designation}
                                     </p>
                                   )}
                                 </div>
                               </div>
                              <div className="flex flex-wrap gap-2">
                                <div className="rounded-full border border-white/12 bg-white/5 px-3 py-1 text-xs text-white/70">
                                  Subject:{' '}
                                  <span className="font-semibold text-white">
                                    {expandedQuestion?.subject || 'Unknown Subject'}
                                  </span>
                                </div>
                                <div className="flex items-center gap-2 rounded-full border border-white/12 bg-white/5 px-3 py-1 text-xs text-white/70">
                                  <FiUser size={12} className="text-[#EFB078]" />
                                  <span>
                                    {expandedQuestion?.user?.name || 'Anonymous'}
                                    {expandedQuestion?.user?.class ? ` · Class ${expandedQuestion.user.class}` : ''}
                                  </span>
                                </div>
                              </div>
                            </div>
                <div className="flex flex-col items-end gap-2 text-xs text-white/60">
                              <span
                                className={`inline-flex items-center gap-2 rounded-full border px-3 py-1 text-xs font-semibold ${
                                  expandedQuestion?.isAnswered
                                    ? 'border-green-500/40 bg-green-900/30 text-green-300'
                                    : 'border-yellow-500/40 bg-yellow-900/30 text-yellow-200'
                                }`}
                              >
                                {expandedQuestion?.isAnswered ? (
                                  <>
                                    <FiCheckCircle size={12} />
                                    Answered
                                  </>
                                ) : (
                                  <>
                                    <FiClock size={12} />
                                    Pending
                                  </>
                                )}
                              </span>
                              <span>
                                {expandedQuestion?.createdAt
                                  ? `${new Date(expandedQuestion.createdAt).toLocaleDateString()} · ${new Date(
                                      expandedQuestion.createdAt,
                                    ).toLocaleTimeString()}`
                                  : 'Created date unavailable'}
                              </span>
                  <div className="flex items-center gap-2">
                    <button
                      type="button"
                      onClick={toggleQuestionStatus}
                      disabled={statusActionLoading}
                      title={expandedQuestion?.status === 'hidden' ? 'Unhide question' : 'Hide question'}
                      className="inline-flex items-center gap-1.5 rounded-xl border border-white/12 bg-white/10 px-3 py-1 text-xs font-semibold text-white/70 transition-all hover:border-white/25 hover:bg-white/20 hover:text-white disabled:opacity-50"
                    >
                      {expandedQuestion?.status === 'hidden' ? <FiEye size={12} /> : <FiEyeOff size={12} />}
                      {expandedQuestion?.status === 'hidden' ? 'Unhide' : 'Hide'}
                    </button>
                    <button
                      type="button"
                      onClick={() => setDeleteQuestionTarget(expandedQuestion)}
                      title="Delete question"
                      className="inline-flex items-center gap-1.5 rounded-xl border border-red-400/30 bg-red-500/10 px-3 py-1 text-xs font-semibold text-red-300 transition-all hover:border-red-300/60 hover:text-red-200"
                    >
                      <FiTrash2 size={12} /> Delete
                    </button>
                    <button
                      type="button"
                      onClick={resetExpandedState}
                      className="rounded-xl border border-white/12 bg-white/10 px-3 py-1 text-xs font-semibold text-white/70 transition-all hover:border-white/25 hover:bg-white/20 hover:text-white"
                    >
                      Close
                    </button>
                  </div>
                            </div>
                          </div>

                          {detailLoading ? (
                            <div className="flex items-center justify-center py-10">
                              <div className="h-10 w-10 animate-spin rounded-full border-b-2 border-[#EFB078]" />
                            </div>
                          ) : detailError ? (
                            <div className="rounded-2xl border border-red-500/40 bg-red-900/20 px-4 py-5 text-sm text-red-200">
                              {detailError}
                            </div>
                          ) : expandedQuestion ? (
                            <div className="space-y-6">
                              <div className="rounded-2xl border border-white/12 bg-black/30 p-5 shadow-[0_12px_36px_rgba(0,0,0,0.35)] backdrop-blur-sm">
                                <div className="flex items-center gap-2 text-sm font-semibold uppercase tracking-[0.2em] text-[#EFB078]/80">
                                  <FiHelpCircle size={14} />
                                  Question
                                </div>
                                <p className="mt-3 text-sm leading-relaxed text-white/85">
                                  {expandedQuestion.description || 'Question text unavailable.'}
                                </p>
                              </div>

                            {expandedQuestion.answer && (
                              <div className="rounded-2xl border border-white/12 bg-black/25 p-5 shadow-[0_12px_32px_rgba(0,0,0,0.3)] backdrop-blur-sm">
                                <div className="flex items-center justify-between">
                                  <div className="flex items-center gap-2 text-sm font-semibold uppercase tracking-[0.2em] text-emerald-200/85">
                                    <FiMessageSquare size={14} />
                                    Answer
                                  </div>
                                  {(
                                    <div className="flex items-center gap-2">
                                      <button
                                        type="button"
                                        onClick={handleStartEditAnswer}
                                        className="inline-flex items-center gap-1 rounded-lg border border-white/12 bg-white/10 p-2 text-white/75 transition-all hover:border-[#EFB078]/40 hover:bg-[#EFB078]/20 hover:text-white"
                                      >
                                        <FiEdit2 size={14} />
                                      </button>
                                      <button
                                        type="button"
                                        onClick={handleDeletePrompt}
                                        className="inline-flex items-center gap-1 rounded-lg border border-red-500/30 bg-red-900/30 p-2 text-red-200 transition-all hover:border-red-400/40 hover:bg-red-800/40 hover:text-red-100"
                                      >
                                        <FiTrash2 size={14} />
                                      </button>
                                    </div>
                                  )}
                                </div>
                                <p className="mt-3 whitespace-pre-line text-sm leading-relaxed text-white/85">
                                  {expandedQuestion.answer}
                                </p>
                                {(expandedQuestion.answeredBy || expandedQuestion.answeredAt) && (
                                  <div className="mt-3 flex flex-wrap items-center gap-3 text-xs text-white/55">
                                    {expandedQuestion.answeredBy && (
                                      <span>Answered by {expandedQuestion.answeredBy}</span>
                                    )}
                                    {expandedQuestion.answeredAt && (
                                      <span>{new Date(expandedQuestion.answeredAt).toLocaleString()}</span>
                                    )}
                                  </div>
                                )}
                              </div>
                            )}
                            {!expandedQuestion.answer && (
                              <div className="rounded-2xl border border-dashed border-white/20 bg-black/20 p-6 text-center shadow-[0_10px_28px_rgba(0,0,0,0.25)] backdrop-blur-sm">
                                <p className="text-sm font-semibold text-white/80">No answer provided yet.</p>
                                <p className="mt-1 text-xs text-white/60">
                                  Click below to compose an answer for this question.
                                </p>
                                <button
                                  type="button"
                                  onClick={() => {
                                    setIsEditingAnswer(true);
                                    setAnswerMode('create');
                                    setAnswerText('');
                                    setDeleteConfirmOpen(false);
                                  }}
                                  className="mt-4 inline-flex items-center gap-2 rounded-xl bg-gradient-to-r from-[#701845]/80 via-[#9E4B63]/75 to-[#EFB078]/80 px-4 py-2 text-sm font-semibold text-white shadow-[0_8px_22px_rgba(112,24,69,0.35)] transition-all hover:from-[#5a1538] hover:to-[#d49a6a]"
                                >
                                  <FiMessageSquare size={15} />
                                  <span>Add Answer</span>
                                </button>
                              </div>
                            )}
                            </div>
                          ) : null}
                        </div>
                      </div>
                    </div>
                  )}

                  {totalPages > 1 && (
                    <div className="relative overflow-hidden rounded-2xl border border-white/10 bg-gradient-to-br from-[#11060d]/60 via-[#1c0b18]/40 to-[#12060f]/60 backdrop-blur-sm p-4">
                      <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
                        <div className="text-xs text-gray-400">
                          Showing {startIndex + 1} to {Math.min(endIndex, filteredQuestions.length)} of {filteredQuestions.length} questions
                        </div>
                        <div className="flex flex-wrap items-center gap-1">
                          <button
                            onClick={() => handlePageChange(currentPage - 1)}
                            disabled={currentPage === 1}
                            className="p-1.5 rounded-lg bg-gray-700 text-gray-300 hover:bg-gray-600 disabled:cursor-not-allowed disabled:opacity-50 transition-colors"
                          >
                            <FiChevronLeft size={14} />
                          </button>

                          {Array.from({ length: totalPages }, (_, i) => i + 1).map((page) => {
                            if (
                              page === 1 ||
                              page === totalPages ||
                              (page >= currentPage - 1 && page <= currentPage + 1)
                            ) {
                              return (
                                <button
                                  key={page}
                                  onClick={() => handlePageChange(page)}
                                  className={`px-2 py-1.5 rounded-lg text-xs font-medium transition-colors ${
                                    currentPage === page
                                      ? 'bg-indigo-600 text-white'
                                      : 'bg-gray-700 text-gray-300 hover:bg-gray-600'
                                  }`}
                                >
                                  {page}
                                </button>
                              );
                            }
                            if (page === currentPage - 2 || page === currentPage + 2) {
                              return (
                                <span key={page} className="text-gray-500 text-xs">
                                  ...
                                </span>
                              );
                            }
                            return null;
                          })}

                          <button
                            onClick={() => handlePageChange(currentPage + 1)}
                            disabled={currentPage === totalPages}
                            className="p-1.5 rounded-lg bg-gray-700 text-gray-300 hover:bg-gray-600 disabled:cursor-not-allowed disabled:opacity-50 transition-colors"
                          >
                            <FiChevronRight size={14} />
                          </button>
                        </div>
                      </div>
                    </div>
                  )}
                </>
              )}
            </div>
          )}
        </main>
      </div>
      {isEditingAnswer && expandedQuestion && (
        <div className="fixed inset-0 z-[160] flex items-center justify-center overflow-y-auto bg-black/10 px-4 py-6 backdrop-blur-md sm:py-10">
          <div className="relative w-full max-w-3xl mx-auto overflow-hidden rounded-3xl border border-white/12 bg-gradient-to-br from-[#100713]/80 via-[#190d23]/65 to-[#10060f]/80 shadow-[0_26px_70px_-24px_rgba(12,6,20,0.75)]">
            <div className="pointer-events-none absolute inset-0 bg-[radial-gradient(circle_at_top_right,rgba(136,32,82,0.45),transparent_65%)]" />
              <div className="relative max-h-[90vh] overflow-y-auto px-4 py-6 space-y-6 sm:px-8 sm:py-8">
                <div className="flex items-start justify-between gap-3 sm:gap-6">
                 <div className="flex items-start gap-3">
                   <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-2xl border border-white/15 bg-black/45 p-2 shadow-[0_10px_22px_rgba(112,24,69,0.45)]">
                     <img src={brandIcon} alt="QSpot icon" className="h-full w-full object-contain" />
                   </div>
                   <div>
                     <p className="text-xs font-semibold uppercase tracking-[0.24em] text-[#f3c5a0]/70">
                       {expandedQuestion.answer ? 'Update Answer' : 'New Answer'}
                     </p>
                     <h3 className="mt-2 text-xl font-semibold tracking-wide text-white sm:text-2xl">
                       {expandedQuestion.answer ? 'Edit the existing response' : 'Compose an answer'}
                     </h3>
                     <p className="mt-2 text-sm text-white/65 break-words">
                       Provide a clear response for <span className="font-semibold text-white">{expandedQuestion.user?.name || 'the user'}</span>'s question.
                     </p>
                   </div>
                 </div>
                <button
                  type="button"
                  onClick={handleCancelEditAnswer}
                  className="shrink-0 rounded-xl border border-white/12 bg-white/10 p-2 text-white/75 transition-all hover:border-white/25 hover:bg-white/20 hover:text-white"
                >
                  <FiX size={18} />
                </button>
              </div>

              <div className="rounded-2xl border border-white/12 bg-black/25 p-4 shadow-[0_14px_36px_rgba(0,0,0,0.28)] backdrop-blur-sm sm:p-6">
                <p className="text-xs font-semibold uppercase tracking-[0.2em] text-white/55">Question</p>
                <p className="mt-2 text-sm text-white/85 whitespace-pre-line">
                  {expandedQuestion.description || 'Question text unavailable.'}
                </p>
              </div>

              <div>
                <label className="text-xs font-semibold uppercase tracking-[0.2em] text-white/60">
                  {expandedQuestion.answer ? 'Updated Answer' : 'Answer'}
                </label>
                <textarea
                  className="mt-3 h-40 w-full resize-none rounded-2xl border border-white/12 bg-black/30 p-4 text-sm text-white placeholder-white/45 shadow-inner focus:border-[#EFB078]/60 focus:outline-none focus:ring-2 focus:ring-[#701845]/30"
                  placeholder={expandedQuestion.answer ? 'Type the updated answer...' : 'Type your answer here...'}
                  value={answerText}
                  onChange={(e) => setAnswerText(e.target.value)}
                  disabled={answerLoading}
                />
                <div className="mt-2 text-xs text-white/50">{answerText.length} characters</div>
              </div>

              <div className="flex flex-wrap items-center justify-end gap-3 pt-2">
                <button
                  type="button"
                  onClick={handleCancelEditAnswer}
                  disabled={answerLoading}
                  className="inline-flex items-center gap-2 rounded-xl border border-white/12 bg-white/10 px-5 py-2 text-sm font-semibold text-white/75 transition-all hover:border-white/25 hover:bg-white/20 hover:text-white"
                >
                  Cancel
                </button>
                <button
                  type="button"
                  onClick={submitAnswer}
                  disabled={answerLoading || !answerText.trim()}
                  className="inline-flex items-center gap-2 rounded-xl bg-gradient-to-r from-[#701845]/90 via-[#9E4B63]/80 to-[#EFB078]/85 px-5 py-2 text-sm font-semibold text-white shadow-[0_12px_30px_rgba(112,24,69,0.4)] transition-all hover:from-[#5a1538] hover:to-[#d49a6a] disabled:opacity-50 disabled:shadow-none"
                >
                  {answerLoading ? (
                    <div className="h-4 w-4 animate-spin rounded-full border-b-2 border-white" />
                  ) : (
                    <FiMessageSquare size={16} />
                  )}
                  <span>{expandedQuestion.answer ? 'Update Answer' : 'Submit Answer'}</span>
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {deleteConfirmOpen && (
        <ConfirmDialog
          title="Delete Answer"
          description="Are you sure you want to delete this answer? This action cannot be undone."
          confirmLabel={deleteLoading ? 'Deleting...' : 'Delete'}
          cancelLabel="Cancel"
          confirmVariant="danger"
          onCancel={handleCancelDelete}
          onConfirm={deleteAnswer}
        />
      )}

      {deleteQuestionTarget && (
        <ConfirmDialog
          title="Delete Question"
          description="Are you sure you want to permanently delete this question and its answer? This action cannot be undone."
          confirmLabel="Delete"
          cancelLabel="Cancel"
          confirmVariant="danger"
          onCancel={() => setDeleteQuestionTarget(null)}
          onConfirm={deleteQuestion}
        />
      )}
    </div>
  );
};
export default QuestionsPage;

