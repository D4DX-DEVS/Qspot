import React, { useCallback, useEffect, useMemo, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  FiBarChart2,
  FiBookOpen,
  FiCalendar,
  FiCheckCircle,
  FiChevronDown,
  FiChevronRight,
  FiClock,
  FiEdit2,
  FiExternalLink,
  FiLayers,
  FiMessageSquare,
  FiPlay,
  FiRefreshCw,
  FiSearch,
  FiVideo,
  FiEyeOff,
} from 'react-icons/fi';
import Sidebar from '../components/Sidebar';
import PageHeader from '../components/ui/PageHeader';
import EmptyState from '../components/ui/EmptyState';
import ErrorState from '../components/ui/ErrorState';
import Spinner from '../components/ui/Spinner';
import usePageTitle from '../hooks/usePageTitle';
import apiClient from '../api/client';
import { formatDuration } from '../utils/format';

const cardClass =
  'rounded-2xl border border-white/10 bg-gradient-to-br from-[#11060d]/75 via-[#1c0b18]/55 to-[#12060f]/75 shadow-[0_10px_32px_rgba(0,0,0,0.35)] backdrop-blur-xl';

const idOf = (value) => (value && typeof value === 'object' ? value._id : value);

const orderBy = (items) =>
  [...items].sort((a, b) => {
    const order = (Number(a.order) || 0) - (Number(b.order) || 0);
    if (order !== 0) return order;
    return String(a.title || a.name || '').localeCompare(String(b.title || b.name || ''));
  });

const dateLabel = (date) => {
  if (!date) return '';
  const parsed = new Date(date);
  return Number.isNaN(parsed.getTime())
    ? String(date)
    : parsed.toLocaleDateString(undefined, { month: 'short', day: 'numeric', year: 'numeric' });
};

const statusClass = (tone = 'muted') => {
  const classes = {
    green: 'border-emerald-300/25 bg-emerald-400/10 text-emerald-200',
    amber: 'border-amber-300/25 bg-amber-400/10 text-amber-200',
    red: 'border-red-300/25 bg-red-400/10 text-red-200',
    muted: 'border-white/10 bg-white/5 text-white/55',
  };
  return `inline-flex items-center gap-1 rounded-full border px-2 py-0.5 text-[10px] font-semibold uppercase tracking-[0.12em] ${classes[tone] || classes.muted}`;
};

const CurriculumPage = () => {
  usePageTitle('Curriculum');
  const navigate = useNavigate();
  const [courses, setCourses] = useState([]);
  const [subjects, setSubjects] = useState([]);
  const [videos, setVideos] = useState([]);
  const [expandedCourses, setExpandedCourses] = useState(() => new Set());
  const [expandedSubjects, setExpandedSubjects] = useState(() => new Set());
  const [search, setSearch] = useState('');
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  const load = useCallback(async () => {
    setLoading(true);
    setError('');
    try {
      const [courseResponse, subjectResponse, videoResponse] = await Promise.all([
        apiClient.get('/courses'),
        apiClient.get('/subjects'),
        apiClient.get('/videos'),
      ]);
      const nextCourses = Array.isArray(courseResponse.data) ? courseResponse.data : [];
      const nextSubjects = Array.isArray(subjectResponse.data) ? subjectResponse.data : [];
      const nextVideos = Array.isArray(videoResponse.data) ? videoResponse.data : [];
      setCourses(nextCourses);
      setSubjects(nextSubjects);
      setVideos(nextVideos);
      setExpandedCourses(new Set(nextCourses.map((course) => String(course._id))));
      setExpandedSubjects(new Set(nextSubjects.map((subject) => String(subject._id))));
    } catch (err) {
      setError(err.message || 'Could not load the curriculum. Check that the API is running.');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    load();
  }, [load]);

  const tree = useMemo(() => {
    const videosBySubject = new Map();
    videos.forEach((video) => {
      const subjectId = String(idOf(video.subject) || 'unassigned');
      const list = videosBySubject.get(subjectId) || [];
      list.push(video);
      videosBySubject.set(subjectId, list);
    });

    const subjectsByCourse = new Map();
    subjects.forEach((subject) => {
      const courseId = String(subject.courseId || 'unassigned');
      const list = subjectsByCourse.get(courseId) || [];
      list.push({ ...subject, videos: orderBy(videosBySubject.get(String(subject._id)) || []) });
      subjectsByCourse.set(courseId, list);
    });

    const buildCourse = (course) => {
      const courseSubjects = orderBy(subjectsByCourse.get(String(course._id)) || []);
      return {
        ...course,
        subjects: courseSubjects,
        videoCount: courseSubjects.reduce((total, subject) => total + subject.videos.length, 0),
      };
    };

    return {
      courses: orderBy(courses).map(buildCourse),
      unassigned: {
        subjects: orderBy(subjectsByCourse.get('unassigned') || []),
        videos: orderBy(videosBySubject.get('unassigned') || []),
        videoCount: (videosBySubject.get('unassigned') || []).length,
      },
    };
  }, [courses, subjects, videos]);

  const matchesSearch = useCallback((course) => {
    const term = search.trim().toLowerCase();
    if (!term) return true;
    return [course.title, course.subtitle, ...course.subjects.flatMap((subject) => [
      subject.name,
      ...subject.videos.map((video) => video.title),
    ])].some((value) => String(value || '').toLowerCase().includes(term));
  }, [search]);

  const matchingSubjects = useCallback((course) => {
    const term = search.trim().toLowerCase();
    if (!term) return course.subjects;
    return course.subjects.filter((subject) =>
      [subject.name, ...subject.videos.map((video) => video.title)].some((value) =>
        String(value || '').toLowerCase().includes(term)
      )
    );
  }, [search]);

  const toggle = (setter, id) => {
    setter((previous) => {
      const next = new Set(previous);
      const key = String(id);
      if (next.has(key)) next.delete(key);
      else next.add(key);
      return next;
    });
  };

  const summary = useMemo(() => ({
    courses: courses.length,
    subjects: subjects.length,
    videos: videos.length,
    upcoming: videos.filter((video) => video.isUpcoming || (video.releaseDate && new Date(video.releaseDate) > new Date())).length,
  }), [courses.length, subjects.length, videos]);

  const renderVideo = (video) => {
    const upcoming = Boolean(video.isUpcoming || (video.releaseDate && new Date(video.releaseDate) > new Date()));
    const published = video.isPublished !== false;
    return (
      <div key={video._id} className="group flex flex-col gap-3 border-t border-white/10 px-4 py-3 pl-12 transition hover:bg-white/[0.03] sm:flex-row sm:items-center sm:justify-between">
        <div className="flex min-w-0 items-start gap-3">
          <span className="mt-0.5 flex h-8 w-8 shrink-0 items-center justify-center rounded-lg border border-white/10 bg-white/5 text-[#EFB078]"><FiPlay size={14} /></span>
          <div className="min-w-0">
            <p className="truncate text-sm font-medium text-white" title={video.title}>{video.order ? `#${video.order} · ` : ''}{video.title}</p>
            <div className="mt-1.5 flex flex-wrap items-center gap-1.5">
              <span className={statusClass(published ? 'green' : 'muted')}>{published ? <FiCheckCircle /> : <FiEyeOff />} {published ? 'Published' : 'Draft'}</span>
              {upcoming && <span className={statusClass('amber')}><FiCalendar /> Upcoming</span>}
              {video.questionCount > 0 && <span className={statusClass('muted')}><FiMessageSquare /> {video.questionCount} question{video.questionCount === 1 ? '' : 's'}</span>}
              {video.durationSeconds > 0 && <span className="inline-flex items-center gap-1 text-[11px] text-white/45"><FiClock /> {formatDuration(video.durationSeconds)}</span>}
              {video.releaseDate && <span className="text-[11px] text-white/40">{dateLabel(video.releaseDate)}</span>}
            </div>
          </div>
        </div>
        <div className="flex shrink-0 flex-wrap items-center gap-1.5 sm:justify-end">
          <button type="button" onClick={() => navigate(`/admin/videos?video=${video._id}&view=edit`)} className="inline-flex items-center gap-1 rounded-lg border border-white/10 px-2.5 py-1.5 text-[11px] font-semibold text-white/70 transition hover:border-[#EFB078]/40 hover:text-white" title="Edit video"><FiEdit2 /> Edit</button>
          <button type="button" onClick={() => navigate(`/admin/video-questions?videoId=${video._id}`)} className="inline-flex items-center gap-1 rounded-lg border border-white/10 px-2.5 py-1.5 text-[11px] font-semibold text-white/70 transition hover:border-[#EFB078]/40 hover:text-white" title="Manage questions"><FiMessageSquare /> Q&A</button>
          <button type="button" onClick={() => navigate(`/admin/videos?video=${video._id}&view=stats`)} className="inline-flex items-center gap-1 rounded-lg border border-white/10 px-2.5 py-1.5 text-[11px] font-semibold text-white/70 transition hover:border-[#EFB078]/40 hover:text-white" title="Open video stats"><FiBarChart2 /> Stats</button>
        </div>
      </div>
    );
  };

  const renderSubject = (subject) => {
    const subjectOpen = expandedSubjects.has(String(subject._id));
    const published = subject.isPublished !== false;
    return (
      <div key={subject._id} className="border-t border-white/10">
        <div className="flex flex-col gap-2 px-4 py-3 sm:flex-row sm:items-center sm:justify-between">
          <button type="button" onClick={() => toggle(setExpandedSubjects, subject._id)} className="flex min-w-0 items-start gap-3 text-left">
            <span className="mt-0.5 text-white/45">{subjectOpen ? <FiChevronDown /> : <FiChevronRight />}</span>
            <span className="flex h-8 w-8 shrink-0 items-center justify-center rounded-lg border border-white/10 bg-white/5 text-[#EFB078]"><FiBookOpen size={15} /></span>
            <span className="min-w-0"><span className="block truncate text-sm font-semibold text-white" title={subject.name}>{subject.order ? `#${subject.order} · ` : ''}{subject.name}</span><span className="mt-1 block text-[11px] text-white/45">{subject.videos.length} video{subject.videos.length === 1 ? '' : 's'}</span></span>
          </button>
          <div className="flex flex-wrap items-center gap-1.5 pl-11 sm:pl-0">
            <span className={statusClass(published ? 'green' : 'muted')}>{published ? 'Published' : 'Hidden'}</span>
            <button type="button" onClick={() => navigate(`/admin/subjects?subject=${subject._id}`)} className="inline-flex items-center gap-1 rounded-lg border border-white/10 px-2.5 py-1.5 text-[11px] font-semibold text-white/70 transition hover:border-[#EFB078]/40 hover:text-white"><FiEdit2 /> Edit</button>
            <button type="button" onClick={() => navigate(`/admin/videos?subject=${subject._id}`)} className="inline-flex items-center gap-1 rounded-lg border border-white/10 px-2.5 py-1.5 text-[11px] font-semibold text-white/70 transition hover:border-[#EFB078]/40 hover:text-white"><FiVideo /> Videos</button>
          </div>
        </div>
        {subjectOpen && (subject.videos.length ? subject.videos.map(renderVideo) : <p className="border-t border-white/10 px-4 py-3 pl-20 text-xs text-white/40">No videos in this subject yet.</p>)}
      </div>
    );
  };

  return (
    <div className="flex min-h-screen overflow-x-hidden bg-black">
      <Sidebar currentPage="curriculum" onNavigate={navigate} />
      <div className="flex w-full flex-1 flex-col pb-28 md:ml-64 md:pb-0">
        <main className="flex-1 p-4 sm:p-6 lg:p-8">
          <PageHeader
            eyebrow="Admin Dashboard"
            title="Curriculum"
            description="Manage the full learning path in one place: courses, subjects, videos, publish state and learner-facing questions."
            actions={<><button type="button" onClick={load} className="inline-flex items-center gap-2 rounded-xl border border-white/10 bg-white/5 px-3.5 py-2.5 text-sm font-semibold text-white/80 transition hover:bg-white/10"><FiRefreshCw /> Refresh</button><button type="button" onClick={() => navigate('/admin/courses')} className="inline-flex items-center gap-2 rounded-xl bg-gradient-to-r from-[#701845]/90 via-[#9E4B63]/80 to-[#EFB078]/85 px-3.5 py-2.5 text-sm font-semibold text-white"><FiLayers /> Edit courses</button></>}
          />

          <div className="mb-6 grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
            {[
              ['Courses', summary.courses, FiLayers],
              ['Subjects', summary.subjects, FiBookOpen],
              ['Videos', summary.videos, FiVideo],
              ['Upcoming', summary.upcoming, FiCalendar],
            ].map(([label, value, Icon]) => <div key={label} className={`${cardClass} flex items-center gap-3 px-4 py-3`}><span className="flex h-9 w-9 items-center justify-center rounded-xl border border-white/10 bg-white/5 text-[#EFB078]">{React.createElement(Icon, { size: 16 })}</span><div><p className="text-[10px] uppercase tracking-[0.2em] text-white/45">{label}</p><p className="text-xl font-semibold text-white">{value}</p></div></div>)}
          </div>

          <div className="mb-5 flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
            <div className="relative w-full max-w-xl"><FiSearch className="pointer-events-none absolute left-3 top-1/2 -translate-y-1/2 text-white/35" /><input value={search} onChange={(event) => setSearch(event.target.value)} placeholder="Search courses, subjects or videos" className="w-full rounded-xl border border-white/10 bg-white/5 py-3 pl-9 pr-4 text-sm text-white placeholder-white/35 outline-none transition focus:border-[#EFB078]/60" /></div>
            <div className="flex items-center gap-2 text-xs text-white/45"><FiExternalLink /> Use the row actions to jump into existing editors and Q&A.</div>
          </div>

          {loading ? <Spinner /> : error ? <ErrorState message={error} onRetry={load} /> : tree.courses.filter(matchesSearch).length === 0 ? <div className={cardClass}><EmptyState icon={FiLayers} title={search ? 'No curriculum matches' : 'No courses yet'} description={search ? 'Try a different search term.' : 'Create a course, then add subjects and videos to build the learning path.'} action={!search && <button type="button" onClick={() => navigate('/admin/courses')} className="rounded-xl bg-[#EFB078] px-4 py-2 text-sm font-semibold text-black">Create a course</button>} /></div> : <div className="space-y-4">{tree.courses.filter(matchesSearch).map((course) => {
            const open = expandedCourses.has(String(course._id));
            const courseSubjects = matchingSubjects(course);
            return <section key={course._id} className={cardClass}>
              <div className="flex flex-col gap-3 px-4 py-4 sm:flex-row sm:items-center sm:justify-between">
                <button type="button" onClick={() => toggle(setExpandedCourses, course._id)} className="flex min-w-0 items-start gap-3 text-left"><span className="mt-1 text-white/45">{open ? <FiChevronDown /> : <FiChevronRight />}</span><span className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl border border-[#EFB078]/25 bg-[#EFB078]/10 text-[#EFB078]"><FiLayers /></span><span className="min-w-0"><span className="block truncate text-base font-semibold text-white" title={course.title}>{course.order ? `#${course.order} · ` : ''}{course.title}</span><span className="mt-1 block text-xs text-white/45">{courseSubjects.length} subject{courseSubjects.length === 1 ? '' : 's'} · {course.videoCount} video{course.videoCount === 1 ? '' : 's'}</span></span></button>
                <div className="flex flex-wrap items-center gap-1.5 pl-10 sm:pl-0"><span className={statusClass(course.isActive === false ? 'muted' : 'green')}>{course.isActive === false ? <FiEyeOff /> : <FiCheckCircle />} {course.isActive === false ? 'Hidden' : 'Active'}</span><button type="button" onClick={() => navigate(`/admin/courses?course=${course._id}`)} className="inline-flex items-center gap-1 rounded-lg border border-white/10 px-2.5 py-1.5 text-[11px] font-semibold text-white/70 transition hover:border-[#EFB078]/40 hover:text-white"><FiEdit2 /> Edit</button></div>
              </div>
              {open && <div className="border-t border-white/10">{courseSubjects.length ? courseSubjects.map(renderSubject) : <p className="px-4 py-4 pl-16 text-sm text-white/45">No subjects in this course yet. <button type="button" onClick={() => navigate('/admin/subjects')} className="font-semibold text-[#EFB078] hover:underline">Add a subject</button></p>}</div>}
            </section>;
          })}</div>}

          {!loading && !error && tree.unassigned.subjects.length > 0 && <section className={`${cardClass} mt-4`}><div className="flex items-center gap-3 px-4 py-4"><span className="flex h-10 w-10 items-center justify-center rounded-xl border border-amber-300/25 bg-amber-400/10 text-amber-200"><FiBookOpen /></span><div><h2 className="text-sm font-semibold text-white">Unassigned subjects</h2><p className="text-xs text-white/45">These subjects are not linked to a course yet.</p></div></div><div className="border-t border-white/10">{tree.unassigned.subjects.map(renderSubject)}</div></section>}
          {!loading && !error && tree.unassigned.videos.length > 0 && <section className={`${cardClass} mt-4`}><div className="px-4 py-4"><h2 className="text-sm font-semibold text-white">Unassigned videos</h2><p className="text-xs text-white/45">These videos need a valid subject link.</p></div><div className="border-t border-white/10">{tree.unassigned.videos.map(renderVideo)}</div></section>}
        </main>
      </div>
    </div>
  );
};

export default CurriculumPage;
