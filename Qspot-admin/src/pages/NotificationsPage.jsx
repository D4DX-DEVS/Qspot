import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { FiEdit2, FiTrash2, FiPlus, FiCalendar } from 'react-icons/fi';
import Sidebar from '../components/Sidebar';
import ConfirmDialog from '../components/dialogs/ConfirmDialog';
import brandIcon from '../assets/Icon.png';

const NotificationsPage = () => {
  const [notifications, setNotifications] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [showEditModal, setShowEditModal] = useState(false);
  const [editingNotification, setEditingNotification] = useState(null);
  const [deleteConfirm, setDeleteConfirm] = useState(null);

  useEffect(() => {
    fetchNotifications();
  }, []);

  const fetchNotifications = async () => {
    try {
      setLoading(true);
      const baseURL = import.meta.env.VITE_API_BASE_URL;
      const response = await axios.get(`${baseURL}/notifications`);
      setNotifications(response.data || []);
    } catch (err) {
      console.error('Error fetching notifications:', err);
      setError('Failed to fetch notifications');
    } finally {
      setLoading(false);
    }
  };

  const handleCreateNotification = async (formData) => {
    try {
      const token = localStorage.getItem('adminToken');
      const baseURL = import.meta.env.VITE_API_BASE_URL;
      
      await axios.post(`${baseURL}/notifications`, formData, {
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json'
        }
      });
      
      setShowCreateModal(false);
      fetchNotifications();
    } catch (err) {
      console.error('Error creating notification:', err);
      alert('Failed to create notification');
    }
  };

  const handleEditNotification = (notification) => {
    setEditingNotification(notification);
    setShowEditModal(true);
  };

  const handleUpdateNotification = async (formData) => {
    try {
      const token = localStorage.getItem('adminToken');
      const baseURL = import.meta.env.VITE_API_BASE_URL;
      
      await axios.put(`${baseURL}/notifications/${editingNotification._id}`, formData, {
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json'
        }
      });
      
      setShowEditModal(false);
      setEditingNotification(null);
      fetchNotifications();
    } catch (err) {
      console.error('Error updating notification:', err);
      alert('Failed to update notification');
    }
  };

  const handleDeleteNotification = async (notificationId) => {
    try {
      const token = localStorage.getItem('adminToken');
      const baseURL = import.meta.env.VITE_API_BASE_URL;
      
      await axios.delete(`${baseURL}/notifications/${notificationId}`, {
        headers: {
          'Authorization': `Bearer ${token}`
        }
      });
      
      setDeleteConfirm(null);
      fetchNotifications();
    } catch (err) {
      console.error('Error deleting notification:', err);
      alert('Failed to delete notification');
    }
  };

  const handleNavigate = (path) => {
    window.location.href = path;
  };

  return (
    <div className="flex min-h-screen bg-black">
      <Sidebar currentPage="notifications" onNavigate={handleNavigate} />
      
      <div className="flex-1 flex flex-col ml-64">
        <main className="flex-1 p-6">
          <div className="mb-8 flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between">
            <div>
              <h2 className="text-2xl font-semibold text-white">Notifications Management</h2>
              <p className="text-sm text-gray-400">Manage announcements and app updates</p>
            </div>
            <button
              onClick={() => setShowCreateModal(true)}
              className="inline-flex items-center gap-2 rounded-2xl bg-gradient-to-r from-[#701845]/90 via-[#9E4B63]/80 to-[#EFB078]/85 px-4 py-2.5 text-sm font-semibold text-white shadow-[0_8px_20px_rgba(112,24,69,0.3)] transition-all hover:from-[#5a1538] hover:to-[#d49a6a]"
            >
              <FiPlus size={14} />
              <span>Add Notification</span>
            </button>
          </div>
          {loading ? (
            <div className="flex justify-center items-center h-64">
              <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-400"></div>
            </div>
          ) : error ? (
            <div className="bg-red-900/20 border border-red-500/30 text-red-400 px-4 py-3 rounded-md">
              {error}
              <button 
                onClick={fetchNotifications}
                className="ml-4 text-red-300 underline hover:text-red-200"
              >
                Retry
              </button>
            </div>
          ) : notifications.length === 0 ? (
            <div className="text-center py-12">
              <p className="text-gray-400">No notifications found</p>
            </div>
          ) : (
            <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
              {notifications.map((notification) => (
                <article
                  key={notification._id}
                  className="group relative flex flex-col gap-3 rounded-2xl border border-white/12 bg-gradient-to-br from-[#160812]/85 via-[#1e0d20]/70 to-[#0f060f]/85 p-4 shadow-[0_18px_46px_-26px_rgba(112,24,69,0.55)] transition-all duration-200 hover:-translate-y-1 hover:border-[#701845]/45 hover:shadow-[0_26px_60px_-28px_rgba(112,24,69,0.65)]"
                >
                  <header className="flex items-start justify-between gap-2">
                    <div className="flex-1 space-y-1.5">
                      <h3 className="text-base font-semibold text-white leading-snug line-clamp-2">
                        {notification.title}
                      </h3>
                      <p className="text-sm text-white/70 line-clamp-3">
                        {notification.description}
                      </p>
                    </div>
                    <div className="flex gap-1.5">
                      <button
                        onClick={() => handleEditNotification(notification)}
                        className="flex h-8 w-8 items-center justify-center rounded-xl border border-white/15 bg-white/5 text-white/75 transition-all hover:border-[#EFB078]/40 hover:text-white"
                        title="Edit notification"
                        aria-label="Edit notification"
                      >
                        <FiEdit2 size={12} />
                      </button>
                      <button
                        onClick={() => setDeleteConfirm(notification)}
                        className="flex h-8 w-8 items-center justify-center rounded-xl border border-white/15 bg-white/5 text-white/75 transition-all hover:border-red-400/60 hover:text-red-200"
                        title="Delete notification"
                        aria-label="Delete notification"
                      >
                        <FiTrash2 size={12} />
                      </button>
                    </div>
                  </header>
                  <footer className="mt-auto flex items-center justify-between gap-2 text-[11px] text-white/65">
                    <span className="inline-flex items-center gap-1.5 rounded-full bg-white/5 px-2.5 py-1">
                      <FiCalendar size={11} className="text-[#EFB078]" />
                      {notification.createdAt
                        ? new Date(notification.createdAt).toLocaleDateString(undefined, {
                            month: 'short',
                            day: 'numeric',
                            year: 'numeric',
                          })
                        : 'Unknown date'}
                    </span>
                  </footer>
                </article>
              ))}
            </div>
          )}
        </main>
      </div>

      {/* Create Notification Modal */}
      {showCreateModal && (
        <CreateNotificationModal
          onClose={() => setShowCreateModal(false)}
          onSave={handleCreateNotification}
        />
      )}

      {/* Edit Notification Modal */}
      {showEditModal && editingNotification && (
        <EditNotificationModal
          notification={editingNotification}
          onClose={() => {
            setShowEditModal(false);
            setEditingNotification(null);
          }}
          onSave={handleUpdateNotification}
        />
      )}

      {/* Delete Confirmation Modal */}
      {deleteConfirm && (
        <ConfirmDialog
          title="Delete Notification"
          description={`Are you sure you want to delete "${deleteConfirm.title}"? This action cannot be undone.`}
          confirmLabel="Delete"
          cancelLabel="Cancel"
          confirmVariant="danger"
          onCancel={() => setDeleteConfirm(null)}
          onConfirm={() => handleDeleteNotification(deleteConfirm._id)}
        />
      )}
    </div>
  );
};

// Create Notification Modal Component
const CreateNotificationModal = ({ onClose, onSave }) => {
  const [formData, setFormData] = useState({
    title: '',
    description: ''
  });
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    const previousOverflow = document.body.style.overflow;
    document.body.style.overflow = 'hidden';
    return () => {
      document.body.style.overflow = previousOverflow;
    };
  }, []);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    try {
      await onSave(formData);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 z-[120] flex h-full w-full items-center justify-center overflow-y-auto bg-black/70 px-4 py-10 backdrop-blur-md">
      <div className="relative w-full max-w-md overflow-visible rounded-3xl border border-white/12 bg-gradient-to-br from-[#100713]/92 via-[#190d23]/85 to-[#10060f]/92 shadow-[0_24px_64px_-28px_rgba(12,6,20,0.9)]">
        <div
          className="pointer-events-none absolute inset-0 rounded-3xl bg-[radial-gradient(circle_at_top_right,rgba(136,32,82,0.55),transparent_65%)]"
          aria-hidden="true"
        />

        <div className="relative px-7 pt-8 pb-7">
          <div className="absolute left-7 top-6 flex h-10 w-10 items-center justify-center rounded-2xl border border-white/12 bg-black/60 shadow-[0_12px_30px_rgba(136,32,82,0.4)]">
            <img src={brandIcon} alt="QSpot icon" className="h-6 w-6 object-contain" />
          </div>

          <div className="flex flex-col gap-1.5 pl-16">
            <p className="text-[10px] font-semibold uppercase tracking-[0.24em] text-[#f3c5a0]/70">
              Notification
            </p>
            <h3 className="text-xl font-semibold tracking-wide text-white">Add New Notification</h3>
            <p className="text-xs text-white/70">
              Share updates and announcements with the community.
            </p>
          </div>

          <form onSubmit={handleSubmit} className="mt-6 space-y-4.5">
            <div>
              <label className="text-[11px] font-semibold uppercase tracking-[0.2em] text-white/65">
                Title *
              </label>
              <input
                type="text"
                value={formData.title}
                onChange={(e) => setFormData({ ...formData, title: e.target.value })}
                placeholder="Enter notification title"
                className="mt-2 block w-full rounded-2xl border border-white/10 bg-white/5 px-3.5 py-2.5 text-[13px] text-white placeholder-white/40 backdrop-blur-sm transition-all duration-200 focus:border-[#EFB078]/60 focus:outline-none focus:ring-0"
                required
              />
            </div>
            <div>
              <label className="text-[11px] font-semibold uppercase tracking-[0.2em] text-white/65">
                Description *
              </label>
              <textarea
                value={formData.description}
                onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                placeholder="Enter notification description"
                className="mt-2 block w-full rounded-2xl border border-white/10 bg-white/5 px-3.5 py-2.5 text-[13px] text-white placeholder-white/40 backdrop-blur-sm transition-all duration-200 focus:border-[#EFB078]/60 focus:outline-none focus:ring-0 min-h-[120px] resize-none"
                required
              />
            </div>
            <div className="flex items-center justify-end gap-2.5 pt-3">
              <button
                type="button"
                onClick={onClose}
                className="rounded-lg border border-white/10 bg-white/5 px-4 py-2 text-[11px] font-semibold uppercase tracking-[0.18em] text-white/75 transition-all duration-200 hover:border-white/20 hover:bg-white/10 hover:text-white"
              >
                Cancel
              </button>
              <button
                type="submit"
                disabled={loading}
                className="rounded-lg bg-gradient-to-r from-[#701845]/90 via-[#9E4B63]/80 to-[#EFB078]/85 px-4.5 py-2 text-[11px] font-semibold uppercase tracking-[0.18em] text-white shadow-[0_16px_34px_rgba(136,32,82,0.45)] transition-all duration-200 hover:scale-[1.01] disabled:opacity-50 disabled:shadow-none"
              >
                {loading ? 'Creating...' : 'Create Notification'}
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
};

// Edit Notification Modal Component
const EditNotificationModal = ({ notification, onClose, onSave }) => {
  const [formData, setFormData] = useState({
    title: notification.title || '',
    description: notification.description || ''
  });
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    const previousOverflow = document.body.style.overflow;
    document.body.style.overflow = 'hidden';
    return () => {
      document.body.style.overflow = previousOverflow;
    };
  }, []);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    try {
      await onSave(formData);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 z-[120] flex h-full w-full items-center justify-center overflow-y-auto bg-black/70 px-4 py-10 backdrop-blur-md">
      <div className="relative w-full max-w-md overflow-visible rounded-3xl border border-white/12 bg-gradient-to-br from-[#100713]/92 via-[#190d23]/85 to-[#10060f]/92 shadow-[0_24px_64px_-28px_rgba(12,6,20,0.9)]">
        <div
          className="pointer-events-none absolute inset-0 rounded-3xl bg-[radial-gradient(circle_at_top_right,rgba(136,32,82,0.55),transparent_65%)]"
          aria-hidden="true"
        />

        <div className="relative px-7 pt-8 pb-7">
          <div className="absolute left-7 top-6 flex h-10 w-10 items-center justify-center rounded-2xl border border-white/12 bg-black/60 shadow-[0_12px_30px_rgba(136,32,82,0.4)]">
            <img src={brandIcon} alt="QSpot icon" className="h-6 w-6 object-contain" />
          </div>

          <div className="flex flex-col gap-1.5 pl-16">
            <p className="text-[10px] font-semibold uppercase tracking-[0.24em] text-[#f3c5a0]/70">
              Notification
            </p>
            <h3 className="text-xl font-semibold tracking-wide text-white">Edit Notification</h3>
            <p className="text-xs text-white/70">
              Update the notification details before saving.
            </p>
          </div>

          <form onSubmit={handleSubmit} className="mt-6 space-y-4.5">
            <div>
              <label className="text-[11px] font-semibold uppercase tracking-[0.2em] text-white/65">
                Title *
              </label>
              <input
                type="text"
                value={formData.title}
                onChange={(e) => setFormData({ ...formData, title: e.target.value })}
                placeholder="Enter notification title"
                className="mt-2 block w-full rounded-2xl border border-white/10 bg-white/5 px-3.5 py-2.5 text-[13px] text-white placeholder-white/40 backdrop-blur-sm transition-all duration-200 focus:border-[#EFB078]/60 focus:outline-none focus:ring-0"
                required
              />
            </div>
            <div>
              <label className="text-[11px] font-semibold uppercase tracking-[0.2em] text-white/65">
                Description *
              </label>
              <textarea
                value={formData.description}
                onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                placeholder="Enter notification description"
                className="mt-2 block w-full rounded-2xl border border-white/10 bg-white/5 px-3.5 py-2.5 text-[13px] text-white placeholder-white/40 backdrop-blur-sm transition-all duration-200 focus:border-[#EFB078]/60 focus:outline-none focus:ring-0 min-h-[120px] resize-none"
                required
              />
            </div>
            <div className="flex items-center justify-end gap-2.5 pt-3">
              <button
                type="button"
                onClick={onClose}
                className="rounded-lg border border-white/10 bg-white/5 px-4 py-2 text-[11px] font-semibold uppercase tracking-[0.18em] text-white/75 transition-all duration-200 hover:border-white/20 hover:bg-white/10 hover:text-white"
              >
                Cancel
              </button>
              <button
                type="submit"
                disabled={loading}
                className="rounded-lg bg-gradient-to-r from-[#701845]/90 via-[#9E4B63]/80 to-[#EFB078]/85 px-4.5 py-2 text-[11px] font-semibold uppercase tracking-[0.18em] text-white shadow-[0_16px_34px_rgba(136,32,82,0.45)] transition-all duration-200 hover:scale-[1.01] disabled:opacity-50 disabled:shadow-none"
              >
                {loading ? 'Updating...' : 'Update Notification'}
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
};

export default NotificationsPage;
