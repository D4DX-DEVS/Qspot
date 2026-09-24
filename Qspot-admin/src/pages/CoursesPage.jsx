import React, { useEffect, useState } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import {
  FiPlus,
  FiTrash2,
  FiSave,
  FiBookOpen,
  FiUploadCloud,
  FiX,
  FiVideo,
} from 'react-icons/fi';
import Sidebar from '../components/Sidebar';
import ConfirmDialog from '../components/dialogs/ConfirmDialog';
import usePageTitle from '../hooks/usePageTitle';
import apiClient from '../api/client';

const emptyCourse = () => ({
  title: '',
  subtitle: '',
  description: '',
  learnPointsText: '',
  image: '',
  order: 0,
  isActive: true,
});

const cardClass =
  'rounded-2xl border border-white/10 bg-gradient-to-br from-[#11060d]/75 via-[#1c0b18]/55 to-[#12060f]/75 shadow-[0_10px_32px_rgba(0,0,0,0.35)] backdrop-blur-xl';

const inputClass =
  'w-full rounded-xl border border-white/10 bg-white/5 px-3 py-2 text-sm text-white placeholder-white/40 outline-none focus:border-[#EFB078]/60';

const CoursesPage = () => {
  usePageTitle('Courses');
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();

  const [courses, setCourses] = useState([]);
  const [form, setForm] = useState(emptyCourse());
  const [selectedId, setSelectedId] = useState(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');
  const [saved, setSaved] = useState(false);
  const [deleteTarget, setDeleteTarget] = useState(null);
  const [linkedSubjects, setLinkedSubjects] = useState([]);
  const [linkedSubjectsLoading, setLinkedSubjectsLoading] = useState(false);

  // A cover picked from disk, uploaded with the save.
  const [coverFile, setCoverFile] = useState(null);
  const [coverPreview, setCoverPreview] = useState('');

  useEffect(() => {
    load();
  }, []);

  const load = async () => {
    setLoading(true);
    setError('');
    try {
      const response = await apiClient.get('/courses');
      const loadedCourses = Array.isArray(response.data) ? response.data : [];
      setCourses(loadedCourses);
      const target = loadedCourses.find((course) => course._id === searchParams.get('course'));
      if (target) select(target);
    } catch (err) {
      setError(err.message || 'Could not load courses. Check that the API is running.');
    } finally {
      setLoading(false);
    }
  };

  // Shows the subjects linked to this course, with their video counts
  // (CONTRACT.md: GET /api/courses/:id -> course + subjects:[{...,videoCount}]).
  const loadLinkedSubjects = async (courseId) => {
    setLinkedSubjectsLoading(true);
    try {
      const response = await apiClient.get(`/courses/${courseId}`);
      setLinkedSubjects(Array.isArray(response.data?.subjects) ? response.data.subjects : []);
    } catch {
      setLinkedSubjects([]);
    } finally {
      setLinkedSubjectsLoading(false);
    }
  };

  const select = (course) => {
    setSelectedId(course._id);
    setForm({
      title: course.title || '',
      subtitle: course.subtitle || '',
      description: course.description || '',
      learnPointsText: (course.learnPoints || []).join('\n'),
      image: course.image || '',
      order: course.order || 0,
      isActive: course.isActive !== false,
    });
    setCoverFile(null);
    setCoverPreview(course.image || '');
    setSaved(false);
    setError('');
    loadLinkedSubjects(course._id);
  };

  const startNew = () => {
    setSelectedId(null);
    setForm(emptyCourse());
    setCoverFile(null);
    setCoverPreview('');
    setSaved(false);
    setError('');
    setLinkedSubjects([]);
  };

  const pickCover = (event) => {
    const file = (event.target.files || [])[0];
    event.target.value = '';
    if (!file) return;

    setCoverFile(file);
    setCoverPreview(URL.createObjectURL(file));
    setSaved(false);
    setError('');
  };

  const clearCover = () => {
    setCoverFile(null);
    setCoverPreview('');
    setForm((prev) => ({ ...prev, image: '' }));
    setSaved(false);
  };

  const save = async () => {
    if (!form.title.trim()) {
      setError('A course needs a title.');
      return;
    }
    setSaving(true);
    setError('');
    const fields = {
      title: form.title.trim(),
      subtitle: form.subtitle.trim(),
      description: form.description.trim(),
      learnPoints: form.learnPointsText
        .split('\n')
        .map((line) => line.trim())
        .filter(Boolean),
      order: Number(form.order) || 0,
      isActive: form.isActive,
    };

    // A picked file goes up as multipart; otherwise the pasted URL is sent as
    // plain JSON.
    let payload = { ...fields, image: form.image.trim() };
    let headers = {};

    if (coverFile) {
      const body = new FormData();
      body.append('image', coverFile);
      Object.entries(fields).forEach(([key, value]) => {
        body.append(
          key,
          Array.isArray(value) ? JSON.stringify(value) : String(value)
        );
      });
      payload = body;
      headers = { 'Content-Type': 'multipart/form-data' };
    }

    try {
      const response = selectedId
        ? await apiClient.put(`/courses/${selectedId}`, payload, { headers })
        : await apiClient.post('/courses', payload, { headers });
      const course = response.data.course;
      setSelectedId(course._id);
      setCourses((prev) => [...prev.filter((item) => item._id !== course._id), course]);
      setForm((prev) => ({ ...prev, image: course.image || '' }));
      setCoverFile(null);
      setCoverPreview(course.image || '');
      setSaved(true);
    } catch (err) {
      setError(err.message || 'Could not save the course.');
    } finally {
      setSaving(false);
    }
  };

  const confirmDelete = async () => {
    try {
      await apiClient.delete(`/courses/${deleteTarget._id}`);
      setCourses((prev) => prev.filter((item) => item._id !== deleteTarget._id));
      if (selectedId === deleteTarget._id) startNew();
    } catch (err) {
      // 409 (course still has subjects) carries a counts message from the
      // server (CONTRACT.md); apiClient surfaces it as err.message.
      setError(err.message || 'Could not delete the course.');
    } finally {
      setDeleteTarget(null);
    }
  };

  return (
    <div className="flex min-h-screen overflow-x-hidden bg-black">
      <Sidebar currentPage="courses" onNavigate={(path) => navigate(path)} />

      <div className="flex-1 flex flex-col w-full pb-28 md:ml-64 md:pb-0">
        <main className="flex-1 p-6 md:p-8 flex flex-col gap-6">
          <div className="flex flex-col gap-2">
            <p className="text-xs uppercase tracking-[0.35em] text-white/50">Admin Dashboard</p>
            <h1 className="text-2xl font-semibold text-white">Courses</h1>
            <p className="max-w-2xl text-sm text-white/60">
              What the app says about the course it is running. Each active course appears on the
              Home screen, and tapping it opens the “About this course” popup.
            </p>
          </div>

          {error && (
            <div className="rounded-xl border border-red-500/30 bg-red-500/10 px-4 py-3 text-sm text-red-200">
              {error}
            </div>
          )}

          <div className="grid gap-6 lg:grid-cols-[minmax(0,300px)_1fr]">
            <div className={`${cardClass} flex max-h-[70vh] flex-col`}>
              <div className="flex items-center justify-between border-b border-white/10 p-4">
                <span className="text-xs uppercase tracking-wide text-slate-300/70">
                  {courses.length} course{courses.length === 1 ? '' : 's'}
                </span>
                <button
                  onClick={startNew}
                  className="inline-flex items-center gap-2 rounded-lg border border-white/15 px-3 py-1.5 text-xs text-white/80 transition hover:bg-white/10"
                >
                  <FiPlus /> New
                </button>
              </div>
              <div className="flex-1 divide-y divide-white/10 overflow-y-auto">
                {loading && <p className="p-4 text-sm text-white/60">Loading…</p>}
                {!loading && courses.length === 0 && (
                  <p className="p-4 text-sm text-white/60">No courses yet — add the first one.</p>
                )}
                {courses.map((course) => (
                  <button
                    key={course._id}
                    onClick={() => select(course)}
                    className={`w-full px-4 py-3 text-left transition ${
                      selectedId === course._id ? 'bg-white/10' : 'hover:bg-white/5'
                    }`}
                  >
                    <div className="flex items-start gap-2">
                      <FiBookOpen className="mt-0.5 shrink-0 text-[#EFB078]" />
                      <span className="flex-1 break-words text-sm font-medium text-white">
                        {course.title}
                      </span>
                    </div>
                    <div className="mt-2">
                      {course.isActive === false ? (
                        <span className="text-[11px] text-white/40">Hidden</span>
                      ) : (
                        <span className="inline-flex items-center rounded-full border border-[#EFB078]/40 bg-[#EFB078]/10 px-2 py-0.5 text-[11px] font-semibold text-[#EFB078]">
                          Active on Home
                        </span>
                      )}
                    </div>
                  </button>
                ))}
              </div>
            </div>

            <div className={`${cardClass} p-5`}>
              <div className="space-y-4">
                <label className="grid gap-2">
                  <span className="text-xs uppercase tracking-wide text-slate-300/70">Title</span>
                  <input
                    value={form.title}
                    onChange={(event) => setForm({ ...form, title: event.target.value })}
                    placeholder="QSPOT — Your Space for Qur’an Vibes"
                    className={inputClass}
                  />
                </label>

                <label className="grid gap-2">
                  <span className="text-xs uppercase tracking-wide text-slate-300/70">Subtitle</span>
                  <input
                    value={form.subtitle}
                    onChange={(event) => setForm({ ...form, subtitle: event.target.value })}
                    placeholder="A weekly Qur’an course with scholars"
                    className={inputClass}
                  />
                </label>

                <label className="grid gap-2">
                  <span className="text-xs uppercase tracking-wide text-slate-300/70">
                    About the course
                  </span>
                  <textarea
                    value={form.description}
                    onChange={(event) => setForm({ ...form, description: event.target.value })}
                    rows={7}
                    placeholder="Tell students what this course is and how it works."
                    className={inputClass}
                  />
                </label>

                <label className="grid gap-2">
                  <span className="text-xs uppercase tracking-wide text-slate-300/70">
                    What you will learn{' '}
                    <span className="normal-case tracking-normal text-white/40">(one per line)</span>
                  </span>
                  <textarea
                    value={form.learnPointsText}
                    onChange={(event) => setForm({ ...form, learnPointsText: event.target.value })}
                    rows={5}
                    placeholder={'Watch short episodes from scholars\nAnswer practice questions'}
                    className={inputClass}
                  />
                </label>

                {/* Cover: upload a file, or paste a URL if the image already
                    lives somewhere else. */}
                <div className="rounded-xl border border-dashed border-white/15 bg-white/[0.03] p-4">
                  <p className="text-xs uppercase tracking-wide text-slate-300/70">
                    Cover image (optional)
                  </p>

                  <div className="mt-3 flex flex-wrap items-center gap-3">
                    <div className="h-[72px] w-[128px] shrink-0 overflow-hidden rounded-lg border border-white/10 bg-white/5">
                      {coverPreview ? (
                        <img
                          src={coverPreview}
                          alt="Course cover preview"
                          className="h-full w-full object-cover"
                        />
                      ) : (
                        <div className="flex h-full w-full items-center justify-center text-white/30">
                          <FiBookOpen />
                        </div>
                      )}
                    </div>

                    <div className="flex flex-wrap items-center gap-2">
                      <label className="inline-flex cursor-pointer items-center gap-2 rounded-lg border border-white/15 px-3 py-2 text-xs text-white/80 transition hover:bg-white/10">
                        <FiUploadCloud /> {coverPreview ? 'Replace cover' : 'Upload cover'}
                        <input
                          type="file"
                          accept="image/png,image/jpeg,image/webp,image/gif"
                          onChange={pickCover}
                          className="hidden"
                        />
                      </label>
                      {coverPreview && (
                        <button
                          onClick={clearCover}
                          className="inline-flex items-center gap-2 rounded-lg border border-white/15 px-3 py-2 text-xs text-white/70 transition hover:bg-white/10"
                        >
                          <FiX /> Remove
                        </button>
                      )}
                    </div>
                  </div>

                  <label className="mt-3 grid gap-2">
                    <span className="text-[11px] text-white/40">
                      PNG, JPG, WEBP or GIF · up to 5 MB. A pasted URL is used as-is.
                    </span>
                    <input
                      value={form.image}
                      onChange={(event) => {
                        setForm({ ...form, image: event.target.value });
                        setCoverFile(null);
                        setCoverPreview(event.target.value);
                      }}
                      placeholder="…or paste an image URL"
                      className={inputClass}
                    />
                  </label>

                  {coverFile && (
                    <p className="mt-2 text-[11px] text-emerald-300">
                      {coverFile.name} will be uploaded when you save.
                    </p>
                  )}
                </div>

                <label className="grid max-w-[140px] gap-2">
                  <span className="text-xs uppercase tracking-wide text-slate-300/70">Order</span>
                  <input
                    type="number"
                    value={form.order}
                    onChange={(event) => setForm({ ...form, order: event.target.value })}
                    className={inputClass}
                  />
                </label>

                <label className="flex items-center gap-2 text-sm text-white/80">
                  <input
                    type="checkbox"
                    checked={form.isActive}
                    onChange={(event) => setForm({ ...form, isActive: event.target.checked })}
                    className="h-4 w-4 accent-[#EFB078]"
                  />
                  Show this course on the Home screen
                </label>

                <div className="flex items-center gap-3 pt-2">
                  <button
                    onClick={save}
                    disabled={saving}
                    className="inline-flex items-center gap-2 rounded-xl bg-[#EFB078] px-5 py-2 text-sm font-semibold text-black transition hover:brightness-110 disabled:opacity-60"
                  >
                    <FiSave /> {saving ? 'Saving…' : selectedId ? 'Save course' : 'Create course'}
                  </button>
                  {saved && <span className="text-xs text-emerald-300">Saved</span>}
                  {selectedId && (
                    <button
                      onClick={() => {
                        const course = courses.find((item) => item._id === selectedId);
                        if (course) setDeleteTarget(course);
                      }}
                      className="ml-auto inline-flex items-center gap-2 rounded-xl border border-red-400/30 px-4 py-2 text-sm text-red-300 transition hover:bg-red-500/10"
                    >
                      <FiTrash2 /> Delete
                    </button>
                  )}
                </div>

                {selectedId && (
                  <div className="mt-4 border-t border-white/10 pt-4">
                    <p className="mb-2 text-xs uppercase tracking-wide text-slate-300/70">Linked Subjects</p>
                    {linkedSubjectsLoading ? (
                      <p className="text-sm text-white/50">Loading…</p>
                    ) : linkedSubjects.length === 0 ? (
                      <p className="text-sm text-white/50">No subjects link to this course yet.</p>
                    ) : (
                      <div className="flex flex-wrap gap-2">
                        {linkedSubjects.map((subject) => (
                          <button
                            key={subject._id}
                            onClick={() => navigate(`/admin/videos?subject=${subject._id}`)}
                            className="inline-flex items-center gap-2 rounded-lg border border-white/10 bg-white/5 px-3 py-1.5 text-xs text-white/80 transition hover:border-[#EFB078]/40 hover:text-white"
                          >
                            <FiVideo size={12} /> {subject.name} · {subject.videoCount ?? 0}
                          </button>
                        ))}
                      </div>
                    )}
                  </div>
                )}
              </div>
            </div>
          </div>
        </main>
      </div>

      {deleteTarget && (
        <ConfirmDialog
          title="Delete Course"
          description="The course disappears from Home along with its “About this course” panel."
          confirmLabel="Delete"
          cancelLabel="Cancel"
          confirmVariant="danger"
          onCancel={() => setDeleteTarget(null)}
          onConfirm={confirmDelete}
        />
      )}
    </div>
  );
};

export default CoursesPage;
