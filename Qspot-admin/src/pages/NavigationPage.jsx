import React, { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { FiCheck, FiEye, FiEyeOff, FiSave } from 'react-icons/fi';
import Sidebar from '../components/Sidebar';
import ErrorState from '../components/ui/ErrorState';
import Spinner from '../components/ui/Spinner';
import usePageTitle from '../hooks/usePageTitle';
import apiClient from '../api/client';

const TAB_DEFAULTS = [
  { key: 'today', label: 'Today', description: 'Daily plan and next actions' },
  { key: 'learn', label: 'Learn', description: 'Subjects, chapters, and lessons' },
  { key: 'practice', label: 'Practice', description: 'Quizzes, assignments, and exams' },
  { key: 'progress', label: 'Progress', description: 'Learning stats and activity' },
  { key: 'me', label: 'Me', description: 'Profile and learner preferences' },
];

const HOME_DEFAULTS = [
  ['hero', 'Today hero', 'The personalised next-step card'],
  ['banners', 'Announcements', 'Admin banners and campaigns'],
  ['stats', 'Learning stats', 'Streak, completed lessons, and focus'],
  ['shortcuts', 'Shortcuts', 'Ask, assignments, schedule, and questions'],
  ['attention', 'Needs attention', 'Overdue learning items'],
  ['todo', 'Your plan', 'Items to complete today'],
  ['jumpBackIn', 'Jump back in', 'Lessons already in progress'],
  ['comingUp', 'Coming up', 'Scheduled and upcoming items'],
  ['subjects', 'Subjects', 'Browse enrolled subjects'],
].map(([key, label, description]) => ({ key, label, description }));

const mergeItems = (items, defaults) => defaults.map((fallback, index) => {
  const saved = items?.find((item) => item.key === fallback.key);
  return { ...fallback, visible: saved?.visible !== false, order: saved?.order ?? index };
});

const NavigationPage = () => {
  usePageTitle('App navigation');
  const navigate = useNavigate();
  const [tabs, setTabs] = useState([]);
  const [homeSections, setHomeSections] = useState([]);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [saved, setSaved] = useState(false);
  const [error, setError] = useState('');

  const fetchConfig = async () => {
    try {
      setLoading(true);
      setError('');
      const response = await apiClient.get('/admin/navigation');
      setTabs(mergeItems(response.data?.items, TAB_DEFAULTS));
      setHomeSections(mergeItems(response.data?.homeSections, HOME_DEFAULTS));
    } catch (err) {
      setError(err.message || 'Failed to load navigation settings');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { fetchConfig(); }, []);

  const toggle = (setter, key) => setter((items) => items.map((item) => (
    item.key === key && key !== 'today' ? { ...item, visible: !item.visible } : item
  )));

  const saveConfig = async () => {
    try {
      setSaving(true);
      setSaved(false);
      await apiClient.put('/admin/navigation', {
        items: tabs.map(({ key, visible, order }) => ({ key, visible, order })),
        homeSections: homeSections.map(({ key, visible, order }) => ({ key, visible, order })),
      });
      setSaved(true);
    } catch (err) {
      setError(err.message || 'Failed to save navigation settings');
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="flex min-h-screen overflow-x-hidden bg-black">
      <Sidebar currentPage="navigation" onNavigate={navigate} />
      <div className="flex w-full flex-1 flex-col pb-28 md:ml-64 md:pb-0">
        <main className="flex-1 p-4 sm:p-6">
          <div className="mb-8 flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between">
            <div>
              <p className="text-xs font-semibold uppercase tracking-[0.24em] text-[#EFB078]/70">App experience</p>
              <h1 className="mt-2 text-2xl font-semibold text-white">Navigation & home sections</h1>
              <p className="mt-1 max-w-2xl text-sm text-white/55">Control what learners see without shipping a new mobile build. Changes apply when the app refreshes its configuration.</p>
            </div>
            <button type="button" onClick={saveConfig} disabled={saving || loading} className="inline-flex items-center justify-center gap-2 rounded-2xl bg-gradient-to-r from-[#701845] via-[#9E4B63] to-[#EFB078] px-5 py-3 text-sm font-semibold text-white shadow-[0_12px_28px_rgba(112,24,69,0.35)] transition hover:brightness-110 disabled:cursor-not-allowed disabled:opacity-50">
              {saved ? <FiCheck size={16} /> : <FiSave size={16} />}
              {saved ? 'Saved' : saving ? 'Saving…' : 'Save changes'}
            </button>
          </div>

          {loading ? <Spinner /> : error ? <ErrorState message={error} onRetry={fetchConfig} /> : (
            <div className="grid gap-6 xl:grid-cols-2">
              <SettingsCard title="Learner menu" description="Hide a destination when that area is not ready for learners. Today is always kept as the safe landing page." items={tabs} onToggle={(key) => toggle(setTabs, key)} />
              <SettingsCard title="Today home sections" description="Choose which personalised blocks appear below the greeting and hero card." items={homeSections} onToggle={(key) => toggle(setHomeSections, key)} />
            </div>
          )}
        </main>
      </div>
    </div>
  );
};

const SettingsCard = ({ title, description, items, onToggle }) => (
  <section className="rounded-3xl border border-white/10 bg-gradient-to-br from-[#170a18]/90 via-[#1b0d20]/75 to-[#0e060f]/90 p-5 shadow-[0_20px_60px_-30px_rgba(112,24,69,0.7)]">
    <header className="mb-4"><h2 className="text-lg font-semibold text-white">{title}</h2><p className="mt-1 text-sm leading-6 text-white/55">{description}</p></header>
    <div className="space-y-2">
      {items.map((item) => (
        <button key={item.key} type="button" onClick={() => onToggle(item.key)} className={`flex w-full items-center gap-3 rounded-2xl border px-3.5 py-3 text-left transition ${item.visible ? 'border-[#EFB078]/25 bg-white/7' : 'border-white/8 bg-black/15 opacity-55'}`} aria-pressed={item.visible}>
          <span className={`flex h-9 w-9 shrink-0 items-center justify-center rounded-xl ${item.visible ? 'bg-[#701845]/80 text-[#EFB078]' : 'bg-white/8 text-white/45'}`}>{item.visible ? <FiEye size={16} /> : <FiEyeOff size={16} />}</span>
          <span className="min-w-0 flex-1"><span className="block text-sm font-semibold text-white">{item.label}</span><span className="mt-0.5 block truncate text-xs text-white/45">{item.description}</span></span>
          <span className={`text-[10px] font-semibold uppercase tracking-[0.16em] ${item.key === 'today' || item.visible ? 'text-[#EFB078]' : 'text-white/35'}`}>{item.key === 'today' ? 'Required' : item.visible ? 'Shown' : 'Hidden'}</span>
        </button>
      ))}
    </div>
  </section>
);

export default NavigationPage;
