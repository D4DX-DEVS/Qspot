import React, { useState } from 'react';
import {
  FaUsers,
  FaUserTie,
  FaQuestionCircle,
  FaCalendarAlt,
  FaVideo,
  FaBell,
  FaImage,
  FaSignOutAlt,
  FaBook,
  FaClipboardList,
  FaEllipsisH,
  FaTimes,
  FaGraduationCap,
  FaLayerGroup,
  FaTasks,
  FaChartLine
} from 'react-icons/fa';
import logo from '../assets/Logo 01.png';
import ConfirmDialog from './dialogs/ConfirmDialog';
import { clearToken } from '../api/client';

// Grouped per the admin IA regroup: Content / Learners / Quizzes / App.
// Each group renders as a labelled section on desktop; on mobile the first
// group's primary items stay on the bottom bar and everything else moves
// into the "More" sheet.
const menuGroups = [
  {
    label: 'Content',
    items: [
      { id: 'curriculum', label: 'Curriculum', icon: FaLayerGroup, path: '/admin/curriculum' },
      { id: 'courses', label: 'Courses', icon: FaGraduationCap, path: '/admin/courses' },
      { id: 'subjects', label: 'Subjects', icon: FaBook, path: '/admin/subjects' },
      { id: 'videos', label: 'Videos', icon: FaVideo, path: '/admin/videos' }
    ]
  },
  {
    label: 'Learners',
    items: [
      { id: 'assignments', label: 'Assignments', icon: FaTasks, path: '/admin/assignments' },
      { id: 'analytics', label: 'Learning analytics', icon: FaChartLine, path: '/admin/analytics' },
      { id: 'users', label: 'Users', icon: FaUsers, path: '/admin/dashboard' },
      { id: 'speakers', label: 'Speakers', icon: FaUserTie, path: '/admin/speakers' },
      { id: 'questions', label: 'Q&A', icon: FaQuestionCircle, path: '/admin/questions' },
      { id: 'schedules', label: 'Schedules', icon: FaCalendarAlt, path: '/admin/schedules' }
    ]
  },
  {
    label: 'Quizzes',
    items: [
      { id: 'quizzes', label: 'Quizzes', icon: FaClipboardList, path: '/admin/quizzes' },
      { id: 'quizAttempts', label: 'Attempts', icon: FaClipboardList, path: '/admin/quiz/attempts' }
    ]
  },
  {
    label: 'App',
    items: [
      { id: 'banner', label: 'Banner', icon: FaImage, path: '/admin/banner' },
      { id: 'notifications', label: 'Notifications', icon: FaBell, path: '/admin/notifications' }
    ]
  }
];

const menuItems = menuGroups.flatMap((group) => group.items);

const Sidebar = ({ currentPage, onNavigate }) => {
  const [showLogoutConfirm, setShowLogoutConfirm] = useState(false);
  const [isMoreOpen, setIsMoreOpen] = useState(false);

  // First 3 items stay on the mobile bottom bar; the rest live in the More sheet.
  const bottomNavItems = menuItems.slice(0, 3);
  const moreItems = menuItems.slice(3);
  const isMoreActive = moreItems.some((item) => item.id === currentPage);

  const handleLogout = () => {
    clearToken();
    onNavigate('/admin/login');
  };

  const handleNavigateClick = (path) => {
    setIsMoreOpen(false);
    onNavigate(path);
  };

  return (
    <>
      {/* Desktop sidebar (unchanged behavior, md and up) */}
      <aside className="fixed top-0 left-0 z-50 hidden h-screen w-64 md:block">
        <div className="relative flex h-full flex-col overflow-hidden rounded-r-3xl border border-white/10 bg-gradient-to-b from-[#0f0a14]/92 via-[#1a0f1f]/75 to-[#12060f]/88 text-white shadow-[0_22px_68px_-18px_rgba(14,12,35,0.85)] backdrop-blur-2xl">
          <div
            className="pointer-events-none absolute inset-0 bg-[radial-gradient(circle_at_top,rgba(136,32,82,0.7),transparent_65%)]"
            aria-hidden="true"
          />

          {/* Logo/Header */}
          <div className="relative flex items-center justify-center border-b border-white/10 px-6 py-5">
            <img
              className="h-10 w-auto drop-shadow-[0_6px_18px_rgba(112,24,69,0.3)]"
              src={logo}
              alt="QSpot Logo"
            />
          </div>

          {/* Navigation Menu */}
          <nav className="relative flex-1 overflow-y-auto px-4 py-5 [scrollbar-width:none] [&::-webkit-scrollbar]:hidden">
            <div className="space-y-5">
              {menuGroups.map((group) => (
                <div key={group.label}>
                  <p className="mb-2 px-1 text-[10px] font-semibold uppercase tracking-[0.28em] text-white/35">
                    {group.label}
                  </p>
                  <ul className="space-y-2">
                    {group.items.map((item) => {
                      const isActive = currentPage === item.id;
                      return (
                        <li key={item.id}>
                          <button
                            onClick={() => handleNavigateClick(item.path)}
                            className={`group relative flex w-full items-center gap-2.5 rounded-xl border border-white/5 bg-white/5 px-3.5 py-2.5 text-left text-sm font-medium text-slate-100/80 transition-all duration-200 ${
                              isActive
                                ? 'text-white'
                                : 'hover:-translate-y-[1px] hover:border-[#701845]/45 hover:bg-gradient-to-r hover:from-[#701845]/35 hover:via-[#9E4B63]/28 hover:to-[#EFB078]/30 hover:text-white hover:shadow-[0_14px_34px_rgba(112,24,69,0.28)]'
                            }`}
                          >
                            <span
                              className={`flex h-8 w-8 items-center justify-center rounded-lg border border-white/5 bg-white/5 text-base transition-all duration-200 ${
                                isActive
                                  ? 'border-white/10 bg-white/15 text-white shadow-[0_6px_18px_rgba(239,176,120,0.32)]'
                                  : 'text-[#f3c5a0]/80 group-hover:border-[#EFB078]/45 group-hover:bg-gradient-to-r group-hover:from-[#701845]/40 group-hover:to-[#EFB078]/45 group-hover:text-white'
                              }`}
                            >
                              <item.icon />
                            </span>
                            <span className="flex-1 tracking-wide">{item.label}</span>
                            <span
                              className={`h-1.5 w-1.5 rounded-full transition-opacity duration-200 ${
                                isActive
                                  ? 'bg-gradient-to-r from-[#701845] to-[#EFB078] opacity-100'
                                  : 'bg-[#EFB078]/70 opacity-0 group-hover:opacity-100'
                              }`}
                            />
                          </button>
                        </li>
                      );
                    })}
                  </ul>
                </div>
              ))}
            </div>
          </nav>

          {/* User Info & Logout */}
          <div className="relative border-t border-white/10 px-3.5 py-4">
            <button
              onClick={() => setShowLogoutConfirm(true)}
              className="flex w-full items-center justify-between gap-2 rounded-lg bg-gradient-to-r from-[#701845]/90 via-[#9E4B63]/78 to-[#EFB078]/82 px-3 py-2 text-xs font-semibold uppercase tracking-wide text-white transition-all duration-200 hover:scale-[1.01] hover:shadow-[0_18px_42px_rgba(112,24,69,0.35)] focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#EFB078]/70"
            >
              <span className="flex h-5 w-7 items-center justify-center rounded-md border border-white/25 bg-white/10 text-sm text-white/90 shadow-[0_6px_16px_rgba(239,176,120,0.32)]">
                <FaSignOutAlt />
              </span>
              <span className="flex-1 text-center">Logout</span>
            </button>
          </div>
        </div>
      </aside>

      {/* Mobile bottom navigation (below md) */}
      <nav
        className="fixed bottom-0 left-0 right-0 z-40 flex items-stretch justify-around border-t border-white/10 bg-[#12060f]/95 px-1 pb-[env(safe-area-inset-bottom)] shadow-[0_-12px_30px_rgba(5,3,10,0.55)] backdrop-blur-xl md:hidden"
        aria-label="Primary"
      >
        {bottomNavItems.map((item) => {
          const isActive = currentPage === item.id;
          return (
            <button
              key={item.id}
              type="button"
              onClick={() => handleNavigateClick(item.path)}
              className={`flex flex-1 flex-col items-center justify-center gap-1 py-3 text-xs font-medium transition-colors ${
                isActive ? 'text-[#EFB078]' : 'text-white/60'
              }`}
            >
              <item.icon size={21} />
              <span className="truncate">{item.label}</span>
            </button>
          );
        })}
        <button
          type="button"
          onClick={() => setIsMoreOpen(true)}
          aria-label="More navigation options"
          className={`flex flex-1 flex-col items-center justify-center gap-1 py-3 text-xs font-medium transition-colors ${
            isMoreActive ? 'text-[#EFB078]' : 'text-white/60'
          }`}
        >
          <FaEllipsisH size={21} />
          <span>More</span>
        </button>
      </nav>

      {/* Mobile "More" bottom sheet */}
      {isMoreOpen && (
        <div className="fixed inset-0 z-50 md:hidden">
          <div
            className="absolute inset-0 bg-black/60 backdrop-blur-sm"
            onClick={() => setIsMoreOpen(false)}
            aria-hidden="true"
          />
          <div className="absolute bottom-0 left-0 right-0 max-h-[75vh] overflow-y-auto rounded-t-3xl border-t border-white/10 bg-gradient-to-b from-[#1a0f1f] to-[#12060f] px-4 pb-[calc(1rem+env(safe-area-inset-bottom))] pt-4 text-white shadow-[0_-20px_60px_rgba(5,3,10,0.65)]">
            <div className="mb-3 flex items-center justify-between">
              <h2 className="text-sm font-semibold uppercase tracking-[0.2em] text-white/70">More</h2>
              <button
                type="button"
                onClick={() => setIsMoreOpen(false)}
                aria-label="Close menu"
                className="flex h-9 w-9 items-center justify-center rounded-lg border border-white/10 bg-white/5 text-white/80"
              >
                <FaTimes />
              </button>
            </div>
            <ul className="grid grid-cols-2 gap-2">
              {moreItems.map((item) => {
                const isActive = currentPage === item.id;
                return (
                  <li key={item.id}>
                    <button
                      type="button"
                      onClick={() => handleNavigateClick(item.path)}
                      className={`flex w-full items-center gap-2.5 rounded-xl border border-white/5 bg-white/5 px-3 py-3 text-left text-sm font-medium transition-colors ${
                        isActive ? 'border-[#EFB078]/40 bg-[#701845]/30 text-white' : 'text-slate-100/80'
                      }`}
                    >
                      <span className="flex h-8 w-8 shrink-0 items-center justify-center rounded-lg border border-white/5 bg-white/5 text-base text-[#f3c5a0]/80">
                        <item.icon />
                      </span>
                      <span className="flex-1 truncate">{item.label}</span>
                    </button>
                  </li>
                );
              })}
              <li>
                <button
                  type="button"
                  onClick={() => {
                    setIsMoreOpen(false);
                    setShowLogoutConfirm(true);
                  }}
                  className="flex w-full items-center gap-2.5 rounded-xl border border-[#701845]/40 bg-gradient-to-r from-[#701845]/70 to-[#EFB078]/40 px-3 py-3 text-left text-sm font-semibold text-white"
                >
                  <span className="flex h-8 w-8 shrink-0 items-center justify-center rounded-lg border border-white/20 bg-white/10 text-base">
                    <FaSignOutAlt />
                  </span>
                  <span className="flex-1">Logout</span>
                </button>
              </li>
            </ul>
          </div>
        </div>
      )}

      {showLogoutConfirm && (
        <ConfirmDialog
          title="Logout"
          description="Are you sure you want to log out? You will need to sign in again to access the dashboard."
          cancelLabel="Stay Logged In"
          confirmLabel="Logout"
          confirmVariant="danger"
          onCancel={() => setShowLogoutConfirm(false)}
          onConfirm={handleLogout}
        />
      )}
    </>
  );
};

export default Sidebar;
