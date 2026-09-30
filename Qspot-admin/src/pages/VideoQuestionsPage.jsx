import React, { useEffect, useMemo, useState } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import {
  FiPlus,
  FiSearch,
  FiTrash2,
  FiEdit2,
  FiX,
  FiCheckCircle,
  FiFilm,
  FiHelpCircle,
  FiSave,
  FiUploadCloud,
  FiPaperclip,
  FiArrowUp,
  FiArrowDown,
} from 'react-icons/fi';
import Sidebar from '../components/Sidebar';
import ConfirmDialog from '../components/dialogs/ConfirmDialog';
import ErrorState from '../components/ui/ErrorState';
import usePageTitle from '../hooks/usePageTitle';
import apiClient from '../api/client';
import useBodyScrollLock from '../hooks/useBodyScrollLock';
// Reuse the same correct-answer resolver QuizPage uses (text match, falling
// back to a numeric index) instead of the old text-only match that silently
// defaulted to option A (GAP-REPORT D4).
import { parseOptionsList, questionToFormShape, isTrueFalseType } from '../utils/quizQuestion';
import brandIcon from '../assets/Icon.png';

const DIFFICULTIES = ['Easy', 'Medium', 'Hard'];
const QUESTION_TYPES = ['Multiple Choice', 'True / False'];

const emptyQuestion = () => ({
  type: QUESTION_TYPES[0],
  question_en: '',
  question_ml: '',
  difficulty: 'Easy',
  order: 0,
  options: [
    { en: '', ml: '' },
    { en: '', ml: '' },
    { en: '', ml: '' },
    { en: '', ml: '' },
  ],
  correctIndex: 0,
});

const parseOptions = parseOptionsList;

const toForm = (question) => {
  const shape = questionToFormShape(question);
  return {
    _id: question._id,
    type: shape.type,
    question_en: shape.question_en,
    question_ml: shape.question_ml,
    difficulty: shape.difficulty,
    order: question.order ?? 0,
    options: shape.options,
    correctIndex: shape.correctIndex ?? 0,
  };
};

const cardClass =
  'rounded-2xl border border-white/10 bg-gradient-to-br from-[#11060d]/75 via-[#1c0b18]/55 to-[#12060f]/75 shadow-[0_10px_32px_rgba(0,0,0,0.35)] backdrop-blur-xl';

const inputClass =
  'w-full rounded-xl border border-white/10 bg-white/5 px-3 py-2 text-sm text-white placeholder-white/40 outline-none focus:border-[#EFB078]/60';

const VideoQuestionsPage = () => {
  usePageTitle('Video Content');
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();

  const [videos, setVideos] = useState([]);
  const [counts, setCounts] = useState({});
  const [selectedVideo, setSelectedVideo] = useState(null);
  const [questions, setQuestions] = useState([]);
  const [loadingVideos, setLoadingVideos] = useState(true);
  const [loadingQuestions, setLoadingQuestions] = useState(false);
  const [search, setSearch] = useState('');
  const [onlyWithQuestions, setOnlyWithQuestions] = useState(false);
  const [error, setError] = useState('');

  const [formOpen, setFormOpen] = useState(false);
  const [form, setForm] = useState(emptyQuestion());
  const [formError, setFormError] = useState('');
  const [saving, setSaving] = useState(false);
  const [deleteTarget, setDeleteTarget] = useState(null);
  const [deleting, setDeleting] = useState(false);

  // Episode content: the Learn note, its key points and the downloads.
  const [learnText, setLearnText] = useState('');
  const [learnPointsText, setLearnPointsText] = useState('');
  const [downloads, setDownloads] = useState([]);
  const [savingContent, setSavingContent] = useState(false);
  const [contentSaved, setContentSaved] = useState(false);

  // Handout files picked but not yet uploaded, each with an editable title.
  const [pendingFiles, setPendingFiles] = useState([]);
  const [uploading, setUploading] = useState(false);
  const [uploadNote, setUploadNote] = useState('');

  useBodyScrollLock(formOpen);

  useEffect(() => {
    loadVideos();
    loadCounts();
  }, []);

  // Deep-link from a Videos page card's "Content" button (?videoId=...).
  useEffect(() => {
    const videoId = searchParams.get('videoId');
    if (!videoId || loadingVideos || !videos.length || selectedVideo) return;
    const match = videos.find((v) => v._id === videoId);
    if (match) loadQuestions(match);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [videos, loadingVideos]);

  const loadVideos = async () => {
    setLoadingVideos(true);
    try {
      const response = await apiClient.get('/videos');
      setVideos(Array.isArray(response.data) ? response.data : response.data.items || []);
    } catch {
      setError('Could not load videos. Check that the API is running.');
    } finally {
      setLoadingVideos(false);
    }
  };

  const loadCounts = async () => {
    try {
      const response = await apiClient.get('/video-questions/counts');
      const map = {};
      (response.data || []).forEach((row) => {
        map[row.videoId] = row.count;
      });
      setCounts(map);
    } catch {
      // Badges are a nicety — a failure here should not block the page.
    }
  };

  const loadQuestions = async (video) => {
    setSelectedVideo(video);
    setLoadingQuestions(true);
    setError('');
    setContentSaved(false);
    setPendingFiles([]);
    setUploadNote('');
    setLearnText(video.learnText || '');
    setLearnPointsText((video.learnPoints || []).join('\n'));
    setDownloads(
      Array.isArray(video.downloads) && video.downloads.length
        ? video.downloads.map((item) => ({ title: item.title || '', url: item.url || '', key: item.key || '' }))
        : []
    );
    try {
      const response = await apiClient.get('/video-questions', { params: { videoId: video._id } });
      const items = response.data.items || [];
      items.sort((a, b) => (Number(a.order) || 0) - (Number(b.order) || 0));
      setQuestions(items);
    } catch {
      setError('Could not load the questions for this video.');
      setQuestions([]);
    } finally {
      setLoadingQuestions(false);
    }
  };

  const filteredVideos = useMemo(() => {
    const term = search.trim().toLowerCase();
    return videos.filter((video) => {
      const matchesTerm = !term || String(video.title || '').toLowerCase().includes(term);
      const matchesFilter = !onlyWithQuestions || (counts[video._id] || 0) > 0;
      return matchesTerm && matchesFilter;
    });
  }, [videos, search, onlyWithQuestions, counts]);

  const openCreate = () => {
    setForm({ ...emptyQuestion(), order: questions.length });
    setFormError('');
    setFormOpen(true);
  };

  const openEdit = (question) => {
    setForm(toForm(question));
    setFormError('');
    setFormOpen(true);
  };

  const handleTypeChange = (nextType) => {
    setForm((prev) => {
      if (isTrueFalseType(nextType)) {
        const alreadyTrueFalse =
          prev.options.length === 2 &&
          prev.options[0].en.trim().toLowerCase() === 'true' &&
          prev.options[1].en.trim().toLowerCase() === 'false';
        const options = alreadyTrueFalse ? prev.options : [{ en: 'True', ml: '' }, { en: 'False', ml: '' }];
        return { ...prev, type: nextType, options };
      }
      return {
        ...prev,
        type: nextType,
        options: [{ en: '', ml: '' }, { en: '', ml: '' }, { en: '', ml: '' }, { en: '', ml: '' }],
        correctIndex: 0,
      };
    });
  };

  const updateOption = (index, field, value) => {
    setForm((prev) => {
      const options = [...prev.options];
      options[index] = { ...options[index], [field]: value };
      return { ...prev, options };
    });
  };

  const addOption = () => {
    setForm((prev) =>
      prev.options.length >= 6 ? prev : { ...prev, options: [...prev.options, { en: '', ml: '' }] }
    );
  };

  const removeOption = (index) => {
    setForm((prev) => {
      if (prev.options.length <= 2) return prev;
      const options = prev.options.filter((_, i) => i !== index);
      const correctIndex = prev.correctIndex >= options.length ? 0 : prev.correctIndex;
      return { ...prev, options, correctIndex };
    });
  };

  const saveQuestion = async () => {
    const trimmed = form.options.map((option) => ({
      en: option.en.trim(),
      ml: option.ml.trim(),
    }));

    if (!form.question_en.trim() || !form.question_ml.trim()) {
      setFormError('Both the English and the Malayalam question text are required.');
      return;
    }
    const filled = trimmed.filter((option) => option.en);
    if (filled.length < 2) {
      setFormError('Add at least two options (English text is required for each).');
      return;
    }
    if (trimmed.some((option) => option.en && !option.ml)) {
      setFormError('Every option needs a Malayalam translation too.');
      return;
    }
    if (!trimmed[form.correctIndex]?.en) {
      setFormError('Mark one of the filled options as the correct answer.');
      return;
    }

    const payload = {
      videoId: selectedVideo._id,
      type: form.type,
      question_en: form.question_en.trim(),
      question_ml: form.question_ml.trim(),
      options_en: trimmed.map((option) => option.en),
      options_ml: trimmed.map((option) => option.ml),
      correct_answer: trimmed[form.correctIndex].en,
      difficulty: form.difficulty,
      order: Number(form.order) || 0,
    };

    setSaving(true);
    setFormError('');
    try {
      if (form._id) {
        await apiClient.put(`/video-questions/${form._id}`, payload);
      } else {
        await apiClient.post('/video-questions', payload);
      }
      setFormOpen(false);
      await loadQuestions(selectedVideo);
      await loadCounts();
    } catch (err) {
      setFormError(err.message || 'Could not save the question.');
    } finally {
      setSaving(false);
    }
  };

  const confirmDelete = async () => {
    if (!deleteTarget) return;
    setDeleting(true);
    try {
      await apiClient.delete(`/video-questions/${deleteTarget._id}`);
      setDeleteTarget(null);
      await loadQuestions(selectedVideo);
      await loadCounts();
    } catch {
      setError('Could not delete the question.');
    } finally {
      setDeleting(false);
    }
  };

  // Swaps `order` with the neighbouring question and saves both (GAP-REPORT
  // D5: "no order/reorder UI although API sorts by order"). PUT does not
  // accept a partial {order} body — it re-validates the full question — so
  // each swap resends every field with only `order` changed.
  const fullQuestionPayload = (question, overrides = {}) => ({
    videoId: selectedVideo._id,
    type: question.type || 'Multiple Choice',
    question_en: question.question_en,
    question_ml: question.question_ml,
    options_en: parseOptions(question.options_en),
    options_ml: parseOptions(question.options_ml),
    correct_answer: question.correct_answer,
    difficulty: question.difficulty || 'Easy',
    order: Number(question.order) || 0,
    ...overrides,
  });

  const reorderQuestion = async (index, direction) => {
    const targetIndex = index + direction;
    if (targetIndex < 0 || targetIndex >= questions.length) return;
    const current = questions[index];
    const target = questions[targetIndex];
    const currentOrder = Number(current.order) || 0;
    const targetOrder = Number(target.order) || 0;
    try {
      await Promise.all([
        apiClient.put(`/video-questions/${current._id}`, fullQuestionPayload(current, { order: targetOrder })),
        apiClient.put(`/video-questions/${target._id}`, fullQuestionPayload(target, { order: currentOrder })),
      ]);
      await loadQuestions(selectedVideo);
    } catch (err) {
      setError(err.message || 'Could not reorder questions.');
    }
  };

  const updateDownload = (index, field, value) => {
    setDownloads((prev) => {
      const next = [...prev];
      next[index] = { ...next[index], [field]: value };
      return next;
    });
  };

  const setPendingTitle = (index, value) => {
    setPendingFiles((prev) => {
      const next = [...prev];
      next[index] = { ...next[index], title: value };
      return next;
    });
  };

  const formatFileSize = (bytes) => {
    if (!bytes) return '';
    const mb = bytes / (1024 * 1024);
    if (mb >= 1) return `${mb.toFixed(1)} MB`;
    return `${Math.max(1, Math.round(bytes / 1024))} KB`;
  };

  // Stage the picked files so each one can be titled before it is uploaded.
  const pickFiles = (event) => {
    const picked = Array.from(event.target.files || []);
    event.target.value = '';
    if (picked.length === 0) return;

    setUploadNote('');
    setPendingFiles((prev) => [
      ...prev,
      ...picked.map((file) => ({
        file,
        title: file.name
          .replace(/\.[^.]+$/, '')
          .replace(/[_-]+/g, ' ')
          .trim(),
      })),
    ]);
  };

  // Handouts persist immediately: this POST appends to video.downloads
  // server-side (CONTRACT.md), so the files are safe even if the admin
  // navigates away before pressing "Save episode content".
  const uploadPendingFiles = async () => {
    if (!selectedVideo || pendingFiles.length === 0) return;

    setUploading(true);
    setError('');
    setUploadNote('');
    try {
      const body = new FormData();
      pendingFiles.forEach((item) => body.append('files', item.file));
      body.append(
        'titles',
        JSON.stringify(pendingFiles.map((item) => item.title.trim()))
      );

      const response = await apiClient.post(`/videos/${selectedVideo._id}/files`, body, {
        headers: { 'Content-Type': 'multipart/form-data' },
      });

      const updatedVideo = response.data?.video;
      if (updatedVideo) {
        setDownloads(
          (updatedVideo.downloads || []).map((item) => ({
            title: item.title || '',
            url: item.url || '',
            key: item.key || '',
          }))
        );
        setSelectedVideo(updatedVideo);
        setVideos((prev) => prev.map((v) => (v._id === updatedVideo._id ? updatedVideo : v)));
      }
      const uploadedCount = Array.isArray(response.data?.files) ? response.data.files.length : pendingFiles.length;
      setPendingFiles([]);
      setUploadNote(`${uploadedCount} file${uploadedCount === 1 ? '' : 's'} uploaded and saved.`);
    } catch (err) {
      setError(err.message || 'Could not upload the files.');
    } finally {
      setUploading(false);
    }
  };

  const saveContent = async () => {
    setSavingContent(true);
    setError('');
    try {
      const payload = {
        learnText: learnText.trim(),
        learnPoints: learnPointsText
          .split('\n')
          .map((line) => line.trim())
          .filter(Boolean),
        downloads: downloads
          .map((item) => ({ title: item.title.trim(), url: item.url.trim(), key: item.key || undefined }))
          .filter((item) => item.title || item.url),
      };
      const response = await apiClient.put(`/videos/${selectedVideo._id}/content`, payload);
      const updated = response.data.video;
      setSelectedVideo(updated);
      setVideos((prev) => prev.map((v) => (v._id === updated._id ? updated : v)));
      setContentSaved(true);
    } catch (err) {
      setError(err.message || 'Could not save the episode content.');
    } finally {
      setSavingContent(false);
    }
  };

  return (
    <div className="flex min-h-screen overflow-x-hidden bg-black">
      <Sidebar currentPage="videos" onNavigate={navigate} />

      <div className="flex-1 flex flex-col w-full pb-28 md:ml-64 md:pb-0">
        <main className="flex-1 p-6 md:p-8 flex flex-col gap-6">
          <div className="flex flex-col gap-2">
            <p className="text-xs uppercase tracking-[0.35em] text-white/50">Admin Dashboard</p>
            <h1 className="text-2xl font-semibold text-white">Video Content</h1>
            <p className="max-w-2xl text-sm text-white/60">
              What a student gets with each episode: a short Learn note, downloadable handouts, and
              the practice questions asked after they finish watching.
            </p>
          </div>

          {error && <ErrorState message={error} />}

          <div className="grid gap-6 lg:grid-cols-[minmax(0,340px)_1fr]">
            <div className={`${cardClass} flex max-h-[70vh] flex-col`}>
              <div className="space-y-3 border-b border-white/10 p-4">
                <div className="relative">
                  <FiSearch className="pointer-events-none absolute left-3 top-1/2 -translate-y-1/2 text-white/40" />
                  <input
                    value={search}
                    onChange={(event) => setSearch(event.target.value)}
                    placeholder="Search videos"
                    className={`${inputClass} pl-9`}
                  />
                </div>
                <label className="flex items-center gap-2 text-xs text-white/70">
                  <input
                    type="checkbox"
                    checked={onlyWithQuestions}
                    onChange={(event) => setOnlyWithQuestions(event.target.checked)}
                    className="h-4 w-4 accent-[#EFB078]"
                  />
                  Only videos that already have questions
                </label>
              </div>

              <div className="flex-1 divide-y divide-white/10 overflow-y-auto">
                {loadingVideos && <p className="p-4 text-sm text-white/60">Loading videos…</p>}
                {!loadingVideos && filteredVideos.length === 0 && (
                  <p className="p-4 text-sm text-white/60">No videos match.</p>
                )}
                {filteredVideos.map((video) => {
                  const count = counts[video._id] || 0;
                  const selected = selectedVideo?._id === video._id;
                  return (
                    <button
                      key={video._id}
                      onClick={() => loadQuestions(video)}
                      className={`w-full px-4 py-3 text-left transition ${
                        selected ? 'bg-white/10' : 'hover:bg-white/5'
                      }`}
                    >
                      <div className="flex items-start gap-2">
                        <FiFilm className="mt-0.5 shrink-0 text-[#EFB078]" />
                        <span className="flex-1 break-words text-sm font-medium text-white">
                          {video.title || 'Untitled video'}
                        </span>
                      </div>
                      <div className="mt-2">
                        {count > 0 ? (
                          <span className="inline-flex items-center gap-1 rounded-full border border-[#EFB078]/40 bg-[#EFB078]/10 px-2 py-0.5 text-[11px] font-semibold text-[#EFB078]">
                            <FiHelpCircle /> {count} question{count === 1 ? '' : 's'}
                          </span>
                        ) : (
                          <span className="text-[11px] text-white/40">No questions yet</span>
                        )}
                      </div>
                    </button>
                  );
                })}
              </div>
            </div>

            <div className={`${cardClass} p-5`}>
              {!selectedVideo && (
                <p className="text-sm text-white/60">Pick a video on the left to see its questions.</p>
              )}

              {selectedVideo && (
                <>
                  <div className="flex flex-wrap items-start justify-between gap-3">
                    <div className="min-w-0">
                      <p className="text-xs uppercase tracking-wide text-slate-300/70">Selected video</p>
                      <h2 className="break-words text-lg font-semibold text-white">
                        {selectedVideo.title}
                      </h2>
                    </div>
                    <button
                      onClick={openCreate}
                      className="inline-flex items-center gap-2 rounded-xl bg-[#EFB078] px-4 py-2 text-sm font-semibold text-black transition hover:brightness-110"
                    >
                      <FiPlus /> Add question
                    </button>
                  </div>

                  {/* Learn note, key points and downloads — the "Learn" and
                      "Downloads" tabs the student sees in the app. */}
                  <div className="mt-5 rounded-xl border border-white/10 bg-white/5 p-4">
                    <p className="text-xs uppercase tracking-wide text-slate-300/70">
                      Learn — quick note
                    </p>
                    <textarea
                      value={learnText}
                      onChange={(event) => setLearnText(event.target.value)}
                      rows={3}
                      placeholder="A short note about what this episode covers"
                      className={`${inputClass} mt-2`}
                    />

                    <p className="mt-4 text-xs uppercase tracking-wide text-slate-300/70">
                      Key points{' '}
                      <span className="normal-case tracking-normal text-white/40">(one per line)</span>
                    </p>
                    <textarea
                      value={learnPointsText}
                      onChange={(event) => setLearnPointsText(event.target.value)}
                      rows={3}
                      placeholder={'Belief means faith\nWhat stains it\nA clean heart shows in actions'}
                      className={`${inputClass} mt-2`}
                    />

                    <p className="mt-4 text-xs uppercase tracking-wide text-slate-300/70">Downloads</p>
                    <div className="mt-2 space-y-2">
                      {downloads.map((item, index) => (
                        <div key={index} className="flex items-center gap-2">
                          <input
                            value={item.title}
                            onChange={(event) => updateDownload(index, 'title', event.target.value)}
                            placeholder="Title"
                            className={`${inputClass} flex-1`}
                          />
                          <input
                            value={item.url}
                            onChange={(event) => updateDownload(index, 'url', event.target.value)}
                            placeholder="https://…"
                            className={`${inputClass} flex-1`}
                          />
                          <button
                            onClick={() =>
                              setDownloads((prev) => prev.filter((_, i) => i !== index))
                            }
                            className="rounded-lg border border-white/15 p-2 text-white/70 transition hover:bg-white/10"
                            aria-label="Remove download"
                          >
                            <FiTrash2 />
                          </button>
                        </div>
                      ))}
                    </div>
                    <button
                      onClick={() => setDownloads((prev) => [...prev, { title: '', url: '' }])}
                      className="mt-3 inline-flex items-center gap-2 rounded-lg border border-white/15 px-3 py-2 text-xs text-white/80 transition hover:bg-white/10"
                    >
                      <FiPlus /> Add download
                    </button>

                    {/* Upload handouts instead of pasting links: pick several
                        files, give each a title, then upload them together. */}
                    <div className="mt-4 rounded-lg border border-dashed border-white/15 bg-white/[0.03] p-3">
                      <p className="text-xs uppercase tracking-wide text-slate-300/70">
                        Upload files
                      </p>
                      <div className="mt-2 flex flex-wrap items-center gap-3">
                        <label className="inline-flex cursor-pointer items-center gap-2 rounded-lg border border-white/15 px-3 py-2 text-xs text-white/80 transition hover:bg-white/10">
                          <FiUploadCloud /> Choose files
                          <input
                            type="file"
                            multiple
                            accept=".pdf,application/pdf,image/png,image/jpeg,image/webp"
                            onChange={pickFiles}
                            className="hidden"
                          />
                        </label>
                        <span className="text-[11px] text-white/40">
                          PDF or image · up to 25 MB each · 10 at a time
                        </span>
                      </div>

                      {pendingFiles.length > 0 && (
                        <div className="mt-3 space-y-2">
                          {pendingFiles.map((item, index) => (
                            <div
                              key={`${item.file.name}-${index}`}
                              className="flex items-center gap-2"
                            >
                              <span className="flex min-w-0 flex-1 items-center gap-2 truncate text-xs text-white/60">
                                <FiPaperclip className="shrink-0" />
                                <span className="truncate">{item.file.name}</span>
                                <span className="shrink-0 text-white/30">
                                  {formatFileSize(item.file.size)}
                                </span>
                              </span>
                              <input
                                value={item.title}
                                onChange={(event) => setPendingTitle(index, event.target.value)}
                                placeholder="Title students see"
                                className={`${inputClass} flex-1`}
                              />
                              <button
                                onClick={() =>
                                  setPendingFiles((prev) =>
                                    prev.filter((_, i) => i !== index)
                                  )
                                }
                                className="rounded-lg border border-white/15 p-2 text-white/70 transition hover:bg-white/10"
                                aria-label="Remove file"
                              >
                                <FiX />
                              </button>
                            </div>
                          ))}

                          <button
                            onClick={uploadPendingFiles}
                            disabled={uploading}
                            className="inline-flex items-center gap-2 rounded-lg bg-[#EFB078] px-3 py-2 text-xs font-semibold text-black transition hover:brightness-110 disabled:opacity-60"
                          >
                            <FiUploadCloud />
                            {uploading
                              ? 'Uploading…'
                              : `Upload ${pendingFiles.length} file${
                                  pendingFiles.length === 1 ? '' : 's'
                                }`}
                          </button>
                        </div>
                      )}

                      {uploadNote && (
                        <p className="mt-2 text-[11px] text-emerald-300">{uploadNote}</p>
                      )}
                    </div>

                    <div className="mt-4 flex items-center gap-3">
                      <button
                        onClick={saveContent}
                        disabled={savingContent}
                        className="inline-flex items-center gap-2 rounded-xl bg-[#EFB078] px-4 py-2 text-sm font-semibold text-black transition hover:brightness-110 disabled:opacity-60"
                      >
                        <FiSave /> {savingContent ? 'Saving…' : 'Save episode content'}
                      </button>
                      {contentSaved && <span className="text-xs text-emerald-300">Saved</span>}
                    </div>
                  </div>

                  <p className="mt-6 text-xs uppercase tracking-wide text-slate-300/70">
                    Practice questions
                  </p>

                  <div className="mt-3 space-y-3">
                    {loadingQuestions && <p className="text-sm text-white/60">Loading questions…</p>}
                    {!loadingQuestions && questions.length === 0 && (
                      <p className="text-sm text-white/60">
                        No questions on this video yet — students just finish the video.
                      </p>
                    )}
                    {questions.map((question, index) => {
                      const options = parseOptions(question.options_en);
                      return (
                        <div key={question._id} className="rounded-xl border border-white/10 bg-white/5 p-4">
                          <div className="flex items-start justify-between gap-3">
                            <div className="min-w-0">
                              <p className="text-xs uppercase tracking-wide text-slate-300/70">
                                Question {index + 1} · {question.type || 'Multiple Choice'} · {question.difficulty}
                              </p>
                              <p className="mt-1 break-words font-medium text-white">
                                {question.question_en}
                              </p>
                              <p className="mt-1 break-words text-sm text-white/70">
                                {question.question_ml}
                              </p>
                            </div>
                            <div className="flex shrink-0 gap-2">
                              <button
                                onClick={() => reorderQuestion(index, -1)}
                                disabled={index === 0}
                                className="rounded-lg border border-white/15 p-2 text-white/80 transition hover:bg-white/10 disabled:opacity-30"
                                aria-label="Move question up"
                              >
                                <FiArrowUp />
                              </button>
                              <button
                                onClick={() => reorderQuestion(index, 1)}
                                disabled={index === questions.length - 1}
                                className="rounded-lg border border-white/15 p-2 text-white/80 transition hover:bg-white/10 disabled:opacity-30"
                                aria-label="Move question down"
                              >
                                <FiArrowDown />
                              </button>
                              <button
                                onClick={() => openEdit(question)}
                                className="rounded-lg border border-white/15 p-2 text-white/80 transition hover:bg-white/10"
                                aria-label="Edit question"
                              >
                                <FiEdit2 />
                              </button>
                              <button
                                onClick={() => setDeleteTarget(question)}
                                className="rounded-lg border border-red-400/30 p-2 text-red-300 transition hover:bg-red-500/10"
                                aria-label="Delete question"
                              >
                                <FiTrash2 />
                              </button>
                            </div>
                          </div>

                          <ul className="mt-3 space-y-1">
                            {options.map((option, optionIndex) => {
                              const isCorrect =
                                String(option).trim().toLowerCase() ===
                                String(question.correct_answer || '').trim().toLowerCase();
                              return (
                                <li
                                  key={optionIndex}
                                  className={`flex items-center gap-2 text-sm ${
                                    isCorrect ? 'font-semibold text-[#EFB078]' : 'text-white/70'
                                  }`}
                                >
                                  {isCorrect && <FiCheckCircle />}
                                  <span>
                                    {String.fromCharCode(65 + optionIndex)}. {option}
                                  </span>
                                </li>
                              );
                            })}
                          </ul>
                        </div>
                      );
                    })}
                  </div>
                </>
              )}
            </div>
          </div>
        </main>
      </div>

      {formOpen && (
        <div className="fixed inset-0 z-50 flex items-start justify-center overflow-y-auto bg-black/70 p-4 backdrop-blur-sm">
          <div className={`${cardClass} my-8 w-full max-w-3xl p-6`}>
            <div className="flex items-start justify-between gap-4">
              <div className="flex items-center gap-2">
                <img src={brandIcon} alt="" className="h-7 w-7 rounded object-contain" />
                <h2 className="text-lg font-semibold text-white">
                  {form._id ? 'Edit question' : 'New question'}
                </h2>
              </div>
              <button
                onClick={() => setFormOpen(false)}
                className="rounded-lg border border-white/15 p-2 text-white/70 hover:bg-white/10"
                aria-label="Close"
              >
                <FiX />
              </button>
            </div>

            <div className="mt-5 grid gap-4">
              <label className="grid gap-2">
                <span className="text-xs uppercase tracking-wide text-slate-300/70">
                  Question (English)
                </span>
                <textarea
                  value={form.question_en}
                  onChange={(event) => setForm({ ...form, question_en: event.target.value })}
                  rows={2}
                  className={inputClass}
                />
              </label>

              <label className="grid gap-2">
                <span className="text-xs uppercase tracking-wide text-slate-300/70">
                  Question (Malayalam)
                </span>
                <textarea
                  value={form.question_ml}
                  onChange={(event) => setForm({ ...form, question_ml: event.target.value })}
                  rows={2}
                  className={inputClass}
                />
              </label>

              <div className="grid gap-4 sm:grid-cols-2">
                <label className="grid gap-2">
                  <span className="text-xs uppercase tracking-wide text-slate-300/70">Type</span>
                  <select
                    value={form.type}
                    onChange={(event) => handleTypeChange(event.target.value)}
                    className={inputClass}
                  >
                    {QUESTION_TYPES.map((type) => (
                      <option key={type} value={type} className="bg-black">
                        {type}
                      </option>
                    ))}
                  </select>
                </label>
                <label className="grid gap-2">
                  <span className="text-xs uppercase tracking-wide text-slate-300/70">Difficulty</span>
                  <select
                    value={form.difficulty}
                    onChange={(event) => setForm({ ...form, difficulty: event.target.value })}
                    className={inputClass}
                  >
                    {DIFFICULTIES.map((level) => (
                      <option key={level} value={level} className="bg-black">
                        {level}
                      </option>
                    ))}
                  </select>
                </label>
                <label className="grid gap-2">
                  <span className="text-xs uppercase tracking-wide text-slate-300/70">Order</span>
                  <input
                    type="number"
                    value={form.order}
                    onChange={(event) => setForm({ ...form, order: event.target.value })}
                    className={inputClass}
                    min="0"
                  />
                </label>
              </div>

              <div>
                <p className="text-xs uppercase tracking-wide text-slate-300/70">
                  Options — pick the correct one (Malayalam required)
                </p>
                <div className="mt-2 space-y-2">
                  {form.options.map((option, index) => (
                    <div key={index} className="flex items-center gap-2">
                      <input
                        type="radio"
                        name="correct-option"
                        checked={form.correctIndex === index}
                        onChange={() => setForm({ ...form, correctIndex: index })}
                        className="h-4 w-4 accent-[#EFB078]"
                        aria-label={`Mark option ${index + 1} correct`}
                      />
                      <span className="w-5 text-sm text-white/60">
                        {String.fromCharCode(65 + index)}
                      </span>
                      <input
                        value={option.en}
                        onChange={(event) => updateOption(index, 'en', event.target.value)}
                        placeholder="English option"
                        disabled={isTrueFalseType(form.type)}
                        className={`${inputClass} flex-1 disabled:opacity-60`}
                      />
                      <input
                        value={option.ml}
                        onChange={(event) => updateOption(index, 'ml', event.target.value)}
                        placeholder="Malayalam option (required)"
                        className={`${inputClass} flex-1`}
                      />
                      {!isTrueFalseType(form.type) && (
                        <button
                          onClick={() => removeOption(index)}
                          disabled={form.options.length <= 2}
                          className="rounded-lg border border-white/15 p-2 text-white/70 transition hover:bg-white/10 disabled:opacity-30"
                          aria-label="Remove option"
                        >
                          <FiX />
                        </button>
                      )}
                    </div>
                  ))}
                </div>
                {!isTrueFalseType(form.type) && form.options.length < 6 && (
                  <button
                    onClick={addOption}
                    className="mt-3 inline-flex items-center gap-2 rounded-lg border border-white/15 px-3 py-2 text-xs text-white/80 transition hover:bg-white/10"
                  >
                    <FiPlus /> Add option
                  </button>
                )}
              </div>

              {formError && <ErrorState message={formError} />}
            </div>

            <div className="mt-6 flex justify-end gap-3">
              <button
                onClick={() => setFormOpen(false)}
                className="rounded-xl border border-white/15 px-4 py-2 text-sm text-white/80 transition hover:bg-white/10"
              >
                Cancel
              </button>
              <button
                onClick={saveQuestion}
                disabled={saving}
                className="rounded-xl bg-[#EFB078] px-5 py-2 text-sm font-semibold text-black transition hover:brightness-110 disabled:opacity-60"
              >
                {saving ? 'Saving…' : form._id ? 'Save changes' : 'Add question'}
              </button>
            </div>
          </div>
        </div>
      )}

      {deleteTarget && (
        <ConfirmDialog
          title="Delete Question"
          description="Students will no longer be asked this after finishing the video. This cannot be undone."
          confirmLabel={deleting ? 'Deleting…' : 'Delete'}
          cancelLabel="Cancel"
          confirmVariant="danger"
          onCancel={() => setDeleteTarget(null)}
          onConfirm={confirmDelete}
        />
      )}
    </div>
  );
};

export default VideoQuestionsPage;
