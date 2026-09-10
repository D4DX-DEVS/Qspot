import React, { useMemo, useState } from 'react';
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
  FaClipboardList
} from 'react-icons/fa';
import logo from '../assets/Logo 01.png';
import ConfirmDialog from './dialogs/ConfirmDialog';

const Sidebar = ({ currentPage, onNavigate }) => {
  const [showLogoutConfirm, setShowLogoutConfirm] = useState(false);

  const menuItems = [
    {
      id: 'users',
      label: 'Users',
      icon: FaUsers,
      path: '/admin/dashboard'
    },
    {
      id: 'speakers',
      label: 'Speakers',
      icon: FaUserTie,
      path: '/admin/speakers'
    },
    {
      id: 'subjects',
      label: 'Subjects',
      icon: FaBook,
      path: '/admin/subjects'
    },
    {
      id: 'questions',
      label: 'Questions',
      icon: FaQuestionCircle,
      path: '/admin/questions'
    },
    {
      id: 'quiz',
      label: 'Quiz',
      icon: FaClipboardList,
      path: '/admin/quiz'
    },
    {
      id: 'quizAttempts',
      label: 'Quiz Attempts',
      icon: FaClipboardList,
      path: '/admin/quiz/attempts',
      parent: 'quiz'
    },
    {
      id: 'schedules',
      label: 'Schedules',
      icon: FaCalendarAlt,
      path: '/admin/schedules'
    },
    {
      id: 'videos',
      label: 'Videos',
      icon: FaVideo,
      path: '/admin/videos'
    },
    {
      id: 'notifications',
      label: 'Notifications',
      icon: FaBell,
      path: '/admin/notifications'
    },
    {
      id: 'banner',
      label: 'Banner',
      icon: FaImage,
      path: '/admin/banner'
    }
  ];

  const childLookup = useMemo(() => {
    return menuItems.reduce((acc, item) => {
      if (item.parent) {
        acc[item.parent] = acc[item.parent] || [];
        acc[item.parent].push(item.id);
      }
      return acc;
    }, {});
  }, [menuItems]);

  const handleLogout = () => {
    localStorage.removeItem('adminToken');
    window.location.href = '/admin/login';
  };

  return (
    <aside className="fixed top-0 left-0 z-50 h-screen w-64">
      <div className="relative flex h-full flex-col overflow-hidden rounded-r-3xl border border-white/10 bg-gradient-to-b from-[#0f0a14]/92 via-[#1a0f1f]/75 to-[#12060f]/88 text-white shadow-[0_22px_68px_-18px_rgba(14,12,35,0.85)] backdrop-blur-2xl">
        <div
          className="pointer-events-none absolute inset-0 bg-[radial-gradient(circle_at_top,rgba(136,32,82,0.7),transparent_65%)]"
          aria-hidden="true"
        />

      {/* Logo/Header */}
        <div className="flex items-center justify-center border-b border-white/10 px-6 py-5">
        <img 
            className="h-10 w-auto drop-shadow-[0_6px_18px_rgba(112,24,69,0.3)]"
            src={logo}
          alt="QSpot Logo" 
        />
      </div>

      {/* Navigation Menu */}
        <nav className="relative flex-1 overflow-y-auto px-4 py-5 [scrollbar-width:none] [&::-webkit-scrollbar]:hidden">
        <ul className="space-y-2">
            {menuItems.map((item) => {
              if (item.parent) {
                return (
                  <li key={item.id} className="pl-8">
                    <button
                      onClick={() => onNavigate(item.path)}
                      className={`group flex w-full items-center gap-2 rounded-xl border border-white/5 px-3 py-2 text-left text-xs font-medium tracking-wide transition-all duration-200 ${
                        currentPage === item.id
                          ? 'bg-gradient-to-r from-[#701845]/45 to-[#EFB078]/30 text-white shadow-[0_12px_32px_rgba(112,24,69,0.25)]'
                          : 'bg-white/5 text-slate-100/80 hover:border-[#701845]/45 hover:bg-gradient-to-r hover:from-[#701845]/20 hover:to-[#EFB078]/30 hover:text-white'
                      }`}
                    >
                      <span className="flex h-6 w-6 items-center justify-center rounded-md border border-white/5 bg-white/5 text-xs">
                        <item.icon />
                      </span>
                      <span className="flex-1">{item.label}</span>
                    </button>
                  </li>
                );
              }
              const childIds = childLookup[item.id] || [];
              const isActive = currentPage === item.id || childIds.includes(currentPage);
              return (
            <li key={item.id}>
              <button
                onClick={() => onNavigate(item.path)}
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
    </aside>
  );
};

export default Sidebar;
