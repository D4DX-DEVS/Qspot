import React, { useEffect, useMemo, useState } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import { FiPlus, FiSearch, FiTrash2, FiSave, FiBookOpen, FiCheckCircle } from 'react-icons/fi';
import Sidebar from '../components/Sidebar';
import ErrorState from '../components/ui/ErrorState';
import usePageTitle from '../hooks/usePageTitle';
import apiClient from '../api/client';
import brandIcon from '../assets/Icon.png';

const ICON_OPTIONS = [
  { value: 'video', label: 'Video' },
  { value: 'quiz', label: 'Quiz' },
  { value: 'question', label: 'Ask a question' },
  { value: 'schedule', label: 'Schedule' },
  { value: 'progress', label: 'Progress' },
  { value: 'note', label: 'Notes' },
  { value: 'info', label: 'Info' },
];

const DEFAULT_POINTS = [
  { icon: 'video', text: '' },
  { icon: 'quiz', text: '' },
  { icon: 'progress', text: '' },
];

const cardClass =
  'rounded-2xl border border-white/10 bg-gradient-to-br from-[#11060d]/75 via-[#1c0b18]/55 to-[#12060f]/75 shadow-[0_10px_32px_rgba(0,0,0,0.35)] backdrop-blur-xl';

const inputClass =
  'w-full rounded-xl border border-white/10 bg-white/5 px-3 py-2 text-sm text-white placeholder-white/40 outline-none focus:border-[#EFB078]/60';

const ChapterGuidePage = () => {
  usePageTitle('Chapter Guide');
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();

  const [subjects, setSubjects] = useState([]);
  const [selected, setSelected] = useState(null);
  const [title, setTitle] = useState('');
  const [points, setPoints] = useState([]);
  const [search, setSearch] = useState('');
  const [onlyUnset, setOnlyUnset] = useState(false);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');
  const [savedAt, setSavedAt] = useState(null);

  useEffect(() => {
    loadSubjects();
  }, []);

  // Deep-link from a Subject's "Guide" cross-link (?subject=...).
  useEffect(() => {
    const subjectId = searchParams.get('subject');
    if (!subjectId || loading || !subjects.length || selected) return;
    const match = subjects.find((s) => s._id === subjectId);
    if (match) selectSubject(match);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [subjects, loading]);

  const loadSubjects = async () => {
    setLoading(true);
    setError('');
    try {
      const response = await apiClient.get('/subjects');
      setSubjects(Array.isArray(response.data) ? response.data : []);
    } catch (err) {
      setError(err.message || 'Could not load the chapters. Check that the API is running.');
    } finally {
      setLoading(false);
    }
  };

  const selectSubject = (subject) => {
    setSelected(subject);
    setTitle(subject.guideTitle || '');
    setPoints(
      Array.isArray(subject.guidePoints) && subject.guidePoints.length
        ? subject.guidePoints.map((point) => ({ icon: point.icon || 'info', text: point.text || '' }))
        : DEFAULT_POINTS.map((point) => ({ ...point }))
    );
    setSavedAt(null);
    setError('');
  };

  const filtered = useMemo(() => {
    const term = search.trim().toLowerCase();
    return subjects.filter((subject) => {
      const matchesTerm = !term || String(subject.name || '').toLowerCase().includes(term);
      const hasGuide = Array.isArray(subject.guidePoints) && subject.guidePoints.length > 0;
      return matchesTerm && (!onlyUnset || !hasGuide);
    });
  }, [subjects, search, onlyUnset]);

  const updatePoint = (index, field, value) => {
    setPoints((prev) => {
      const next = [...prev];
      next[index] = { ...next[index], [field]: value };
      return next;
    });
  };

  const addPoint = () => {
    setPoints((prev) => (prev.length >= 6 ? prev : [...prev, { icon: 'info', text: '' }]));
  };

  const removePoint = (index) => {
    setPoints((prev) => prev.filter((_, i) => i !== index));
  };

  const save = async () => {
    const filled = points
      .map((point) => ({ icon: point.icon, text: point.text.trim() }))
      .filter((point) => point.text.length > 0);

    if (filled.length === 0) {
      setError('Add at least one line describing what is inside this chapter.');
      return;
    }

    setSaving(true);
    setError('');
    try {
      const response = await apiClient.put(`/subjects/${selected._id}/guide`, {
        guideTitle: title.trim(),
        guidePoints: filled,
      });
      const updated = response.data.subject;
      setSubjects((prev) => prev.map((s) => (s._id === updated._id ? updated : s)));
      setSelected(updated);
      setSavedAt(new Date());
    } catch (err) {
      setError(err.message || 'Could not save the guide.');
    } finally {
      setSaving(false);
    }
  };

  const previewPoints = points.filter((point) => point.text.trim().length > 0);

  return (
    <div className="flex min-h-screen overflow-x-hidden bg-black">
      <Sidebar currentPage="subjects" onNavigate={navigate} />

      <div className="flex-1 flex flex-col w-full pb-28 md:ml-64 md:pb-0">
        <main className="flex-1 p-6 md:p-8 flex flex-col gap-6">
          <div className="flex flex-col gap-2">
            <p className="text-xs uppercase tracking-[0.35em] text-white/50">Admin Dashboard</p>
            <h1 className="text-2xl font-semibold text-white">Chapter Guide</h1>
            <p className="max-w-2xl text-sm text-white/60">
              The panel a student sees the first time they open a chapter — a heading and what is
              inside it. It is shown once per chapter, per device.
            </p>
          </div>

          {error && <ErrorState message={error} onRetry={loadSubjects} />}

          <div className="grid gap-6 lg:grid-cols-[minmax(0,320px)_1fr]">
            <div className={`${cardClass} flex max-h-[70vh] flex-col`}>
              <div className="space-y-3 border-b border-white/10 p-4">
                <div className="relative">
                  <FiSearch className="pointer-events-none absolute left-3 top-1/2 -translate-y-1/2 text-white/40" />
                  <input
                    value={search}
                    onChange={(event) => setSearch(event.target.value)}
                    placeholder="Search chapters"
                    className={`${inputClass} pl-9`}
                  />
                </div>
                <label className="flex items-center gap-2 text-xs text-white/70">
                  <input
                    type="checkbox"
                    checked={onlyUnset}
                    onChange={(event) => setOnlyUnset(event.target.checked)}
                    className="h-4 w-4 accent-[#EFB078]"
                  />
                  Only chapters without a guide
                </label>
              </div>

              <div className="flex-1 divide-y divide-white/10 overflow-y-auto">
                {loading && <p className="p-4 text-sm text-white/60">Loading chapters…</p>}
                {!loading && filtered.length === 0 && (
                  <p className="p-4 text-sm text-white/60">Nothing matches.</p>
                )}
                {filtered.map((subject) => {
                  const count = (subject.guidePoints || []).length;
                  const isSelected = selected?._id === subject._id;
                  return (
                    <button
                      key={subject._id}
                      onClick={() => selectSubject(subject)}
                      className={`w-full px-4 py-3 text-left transition ${
                        isSelected ? 'bg-white/10' : 'hover:bg-white/5'
                      }`}
                    >
                      <div className="flex items-start gap-2">
                        <FiBookOpen className="mt-0.5 shrink-0 text-[#EFB078]" />
                        <span className="flex-1 break-words text-sm font-medium text-white">
                          {subject.name}
                        </span>
                      </div>
                      <div className="mt-2">
                        {count > 0 ? (
                          <span className="inline-flex items-center gap-1 rounded-full border border-[#EFB078]/40 bg-[#EFB078]/10 px-2 py-0.5 text-[11px] font-semibold text-[#EFB078]">
                            <FiCheckCircle /> {count} point{count === 1 ? '' : 's'}
                          </span>
                        ) : (
                          <span className="text-[11px] text-white/40">No guide yet</span>
                        )}
                      </div>
                    </button>
                  );
                })}
              </div>
            </div>

            <div className={`${cardClass} p-5`}>
              {!selected && (
                <p className="text-sm text-white/60">Pick a chapter on the left to write its guide.</p>
              )}

              {selected && (
                <div className="grid gap-6 xl:grid-cols-[1fr_minmax(240px,280px)]">
                  <div className="space-y-4">
                    <div>
                      <p className="text-xs uppercase tracking-wide text-slate-300/70">Chapter</p>
                      <h2 className="break-words text-lg font-semibold text-white">{selected.name}</h2>
                    </div>

                    <label className="grid gap-2">
                      <span className="text-xs uppercase tracking-wide text-slate-300/70">Heading</span>
                      <input
                        value={title}
                        onChange={(event) => setTitle(event.target.value)}
                        placeholder="What is inside this chapter"
                        className={inputClass}
                      />
                    </label>

                    <div>
                      <p className="text-xs uppercase tracking-wide text-slate-300/70">
                        What is inside
                      </p>
                      <div className="mt-2 space-y-2">
                        {points.map((point, index) => (
                          <div key={index} className="flex items-center gap-2">
                            <select
                              value={point.icon}
                              onChange={(event) => updatePoint(index, 'icon', event.target.value)}
                              className={`${inputClass} max-w-[150px]`}
                            >
                              {ICON_OPTIONS.map((option) => (
                                <option key={option.value} value={option.value} className="bg-black">
                                  {option.label}
                                </option>
                              ))}
                            </select>
                            <input
                              value={point.text}
                              onChange={(event) => updatePoint(index, 'text', event.target.value)}
                              placeholder="One line about this chapter"
                              className={`${inputClass} flex-1`}
                            />
                            <button
                              onClick={() => removePoint(index)}
                              className="rounded-lg border border-white/15 p-2 text-white/70 transition hover:bg-white/10"
                              aria-label="Remove line"
                            >
                              <FiTrash2 />
                            </button>
                          </div>
                        ))}
                      </div>
                      {points.length < 6 && (
                        <button
                          onClick={addPoint}
                          className="mt-3 inline-flex items-center gap-2 rounded-lg border border-white/15 px-3 py-2 text-xs text-white/80 transition hover:bg-white/10"
                        >
                          <FiPlus /> Add line
                        </button>
                      )}
                    </div>

                    <div className="flex items-center gap-3">
                      <button
                        onClick={save}
                        disabled={saving}
                        className="inline-flex items-center gap-2 rounded-xl bg-[#EFB078] px-5 py-2 text-sm font-semibold text-black transition hover:brightness-110 disabled:opacity-60"
                      >
                        <FiSave /> {saving ? 'Saving…' : 'Save guide'}
                      </button>
                      {savedAt && <span className="text-xs text-emerald-300">Saved</span>}
                    </div>
                  </div>

                  {/* What the student will see */}
                  <div>
                    <div className="rounded-2xl border border-white/10 bg-white p-5">
                      <div className="flex items-center gap-2">
                        <img src={brandIcon} alt="" className="h-5 w-5 rounded object-contain" />
                        <span className="text-[10px] uppercase tracking-[0.2em] text-black/40">
                          Preview
                        </span>
                      </div>
                      <p className="mt-4 text-center text-base font-bold text-[#1A1216]">
                        {title.trim() || 'What is inside this chapter'}
                      </p>
                      <div className="mt-4 space-y-3">
                        {previewPoints.map((point, index) => (
                          <div key={index} className="flex items-start gap-3">
                            <span className="mt-0.5 grid h-8 w-8 shrink-0 place-items-center rounded-xl bg-[#F6E9EE] text-[10px] font-bold text-[#7A2048]">
                              {(ICON_OPTIONS.find((o) => o.value === point.icon)?.label || 'I')[0]}
                            </span>
                            <span className="text-xs leading-5 text-[#1A1216]">{point.text}</span>
                          </div>
                        ))}
                        {previewPoints.length === 0 && (
                          <p className="text-xs text-black/40">Lines you write appear here.</p>
                        )}
                      </div>
                      <div className="mt-6 rounded-full bg-[#7A2048] py-2.5 text-center text-xs font-bold text-white">
                        Got it
                      </div>
                      <p className="mt-3 text-center text-[10px] text-black/40">
                        Shown once, the first time the chapter is opened
                      </p>
                    </div>
                  </div>
                </div>
              )}
            </div>
          </div>
        </main>
      </div>
    </div>
  );
};

export default ChapterGuidePage;
