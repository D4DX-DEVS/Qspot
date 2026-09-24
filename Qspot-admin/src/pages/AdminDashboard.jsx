import React, { useState, useEffect, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import { FiEdit2, FiTrash2, FiSearch, FiUsers, FiEye } from 'react-icons/fi';
import Sidebar from '../components/Sidebar';
import ConfirmDialog from '../components/dialogs/ConfirmDialog';
import PageHeader from '../components/ui/PageHeader';
import Spinner from '../components/ui/Spinner';
import ErrorState from '../components/ui/ErrorState';
import EmptyState from '../components/ui/EmptyState';
import Pagination from '../components/ui/Pagination';
import usePageTitle from '../hooks/usePageTitle';
import apiClient from '../api/client';
import brandIcon from '../assets/Icon.png';

const ITEMS_PER_PAGE = 10;

const AdminDashboard = () => {
  usePageTitle('Users');
  const navigate = useNavigate();
  const [users, setUsers] = useState([]);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [editingUser, setEditingUser] = useState(null);
  const [showEditModal, setShowEditModal] = useState(false);
  const [deleteConfirm, setDeleteConfirm] = useState(null);

  const [page, setPage] = useState(1);
  const [searchTerm, setSearchTerm] = useState('');
  const [searchInput, setSearchInput] = useState('');

  // Debounce the search box into the server-side `search` param.
  useEffect(() => {
    const timer = setTimeout(() => {
      setSearchTerm(searchInput);
      setPage(1);
    }, 350);
    return () => clearTimeout(timer);
  }, [searchInput]);

  const fetchUsers = useCallback(async () => {
    try {
      setLoading(true);
      setError('');
      const response = await apiClient.get('/admin/users', {
        params: { page, limit: ITEMS_PER_PAGE, search: searchTerm || undefined }
      });
      const data = response.data;
      setUsers(data.items || []);
      setTotal(data.total || 0);
    } catch (err) {
      setError(err.message || 'Failed to fetch users');
      setUsers([]);
    } finally {
      setLoading(false);
    }
  }, [page, searchTerm]);

  useEffect(() => {
    fetchUsers();
  }, [fetchUsers]);

  const handleNavigate = (path) => navigate(path);

  const handleEditUser = (user) => {
    setEditingUser(user);
    setShowEditModal(true);
  };

  const handleUpdateUser = async (updatedData) => {
    try {
      await apiClient.put(`/admin/users/${editingUser._id}`, updatedData);
      setShowEditModal(false);
      setEditingUser(null);
      fetchUsers();
    } catch (err) {
      alert(err.message || 'Failed to update user');
    }
  };

  const handleDeleteUser = async (userId) => {
    try {
      await apiClient.delete(`/admin/users/${userId}`);
      setDeleteConfirm(null);
      fetchUsers();
    } catch (err) {
      alert(err.message || 'Failed to delete user');
    }
  };

  const totalPages = Math.max(1, Math.ceil(total / ITEMS_PER_PAGE));

  return (
    <div className="flex min-h-screen overflow-x-hidden bg-black">
      <Sidebar currentPage="users" onNavigate={handleNavigate} />

      <div className="flex-1 flex flex-col w-full pb-28 md:ml-64 md:pb-0">
        <main className="flex-1 p-4 sm:p-6">
          <PageHeader
            title="Users"
            description="Manage and view all registered students."
            actions={
              <div className="relative w-full sm:w-80">
                <FiSearch className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400" size={18} />
                <input
                  type="text"
                  placeholder="Search by name, email, phone, class…"
                  value={searchInput}
                  onChange={(e) => setSearchInput(e.target.value)}
                  className="w-full pl-12 pr-4 py-3 bg-white/5 border border-white/10 rounded-2xl text-white placeholder-[#f3c5a0]/55 focus:outline-none focus:border-[#701845]/50 focus:ring-2 focus:ring-[#701845]/30 transition-all"
                />
              </div>
            }
          />

          {loading ? (
            <Spinner />
          ) : error ? (
            <ErrorState message={error} onRetry={fetchUsers} />
          ) : (
            <div className="relative overflow-hidden rounded-3xl border border-white/10 bg-gradient-to-br from-[#11060d]/70 via-[#1c0b18]/50 to-[#12060f]/70 shadow-[0_20px_60px_-15px_rgba(112,24,69,0.4)] backdrop-blur-xl">
              {users.length === 0 ? (
                <EmptyState
                  icon={FiUsers}
                  title={searchTerm ? 'No users found matching your search' : 'No users found'}
                  action={
                    searchTerm && (
                      <button
                        onClick={() => setSearchInput('')}
                        className="text-indigo-400 hover:text-indigo-300 transition-colors"
                      >
                        Clear search
                      </button>
                    )
                  }
                />
              ) : (
                <>
                  <div className="overflow-x-auto">
                    <table className="w-full min-w-0 sm:min-w-[720px] divide-y divide-white/5">
                      <thead className="bg-gradient-to-r from-[#11060d]/60 to-[#1c0b18]/40">
                        <tr>
                          <th className="px-4 sm:px-6 py-4 text-left text-xs font-semibold text-slate-200 uppercase tracking-wider">
                            Name
                          </th>
                          <th className="hidden sm:table-cell px-6 py-4 text-left text-xs font-semibold text-slate-200 uppercase tracking-wider">
                            Contact
                          </th>
                          <th className="hidden sm:table-cell px-6 py-4 text-left text-xs font-semibold text-slate-200 uppercase tracking-wider">
                            Class
                          </th>
                          <th className="px-4 sm:px-6 py-4 text-left text-xs font-semibold text-slate-200 uppercase tracking-wider">
                            Actions
                          </th>
                        </tr>
                      </thead>
                      <tbody className="divide-y divide-white/5">
                        {users.map((user) => (
                          <tr key={user._id} className="hover:bg-white/5 transition-colors">
                            <td
                              className="px-4 sm:px-6 py-4 whitespace-nowrap cursor-pointer"
                              onClick={() => navigate(`/admin/users/${user._id}`)}
                            >
                              <div className="flex items-center">
                                <div className="h-10 w-10 rounded-full bg-gradient-to-br from-[#701845]/80 to-[#EFB078]/70 border border-white/20 flex items-center justify-center shadow-[0_4px_12px_rgba(112,24,69,0.3)]">
                                  <span className="text-sm font-semibold text-white">
                                    {user.name?.charAt(0)?.toUpperCase() || '?'}
                                  </span>
                                </div>
                                <div className="ml-3 sm:ml-4 min-w-0">
                                  <div className="text-sm font-medium text-white truncate">
                                    {user.name || 'No Name'}
                                  </div>
                                </div>
                              </div>
                            </td>
                            <td
                              className="hidden sm:table-cell px-6 py-4 whitespace-nowrap cursor-pointer"
                              onClick={() => navigate(`/admin/users/${user._id}`)}
                            >
                              {user.email && <div className="text-sm text-gray-300">{user.email}</div>}
                              <div className="text-sm text-gray-400">{user.phone || 'No phone'}</div>
                            </td>
                            <td
                              className="hidden sm:table-cell px-6 py-4 whitespace-nowrap cursor-pointer"
                              onClick={() => navigate(`/admin/users/${user._id}`)}
                            >
                              <span className="inline-flex items-center px-3 py-1 rounded-full text-xs font-semibold bg-gradient-to-r from-[#701845]/30 to-[#EFB078]/20 text-[#EFB078] border border-[#EFB078]/30">
                                {user.class || 'Not specified'}
                              </span>
                            </td>
                            <td className="px-2 sm:px-6 py-4 whitespace-nowrap text-sm font-medium">
                              <div className="flex items-center gap-1 sm:gap-2">
                                <button
                                  onClick={(e) => {
                                    e.stopPropagation();
                                    navigate(`/admin/users/${user._id}`);
                                  }}
                                  className="flex h-8 w-8 sm:h-9 sm:w-9 items-center justify-center text-[#EFB078] hover:text-white transition-all rounded-xl hover:bg-white/10 border border-transparent hover:border-[#EFB078]/30 sm:hidden"
                                  title="View user activity"
                                  aria-label="View user activity"
                                >
                                  <FiEye size={16} />
                                </button>
                                <button
                                  onClick={(e) => {
                                    e.stopPropagation();
                                    handleEditUser(user);
                                  }}
                                  className="flex h-8 w-8 sm:h-9 sm:w-9 items-center justify-center text-[#EFB078] hover:text-white transition-all rounded-xl hover:bg-white/10 border border-transparent hover:border-[#EFB078]/30"
                                  title="Edit user"
                                  aria-label="Edit user"
                                >
                                  <FiEdit2 size={16} />
                                </button>
                                <button
                                  onClick={(e) => {
                                    e.stopPropagation();
                                    setDeleteConfirm(user);
                                  }}
                                  className="flex h-8 w-8 sm:h-9 sm:w-9 items-center justify-center text-red-400 hover:text-white transition-all rounded-xl hover:bg-red-900/30 border border-transparent hover:border-red-400/40"
                                  title="Delete user"
                                  aria-label="Delete user"
                                >
                                  <FiTrash2 size={16} />
                                </button>
                              </div>
                            </td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>

                  <Pagination page={page} totalPages={totalPages} total={total} onChange={setPage} label="users" />
                </>
              )}
            </div>
          )}
        </main>
      </div>

      {showEditModal && editingUser && (
        <EditUserModal
          user={editingUser}
          onClose={() => {
            setShowEditModal(false);
            setEditingUser(null);
          }}
          onSave={handleUpdateUser}
        />
      )}

      {deleteConfirm && (
        <ConfirmDialog
          iconSrc={brandIcon}
          iconAlt="QSpot icon"
          title="Delete User"
          description={`Are you sure you want to delete ${
            deleteConfirm.name || 'this user'
          }? This action cannot be undone.`}
          cancelLabel="Cancel"
          confirmLabel="Delete"
          confirmVariant="danger"
          onCancel={() => setDeleteConfirm(null)}
          onConfirm={() => handleDeleteUser(deleteConfirm._id)}
        />
      )}
    </div>
  );
};

const EditUserModal = ({ user, onClose, onSave }) => {
  const [formData, setFormData] = useState({
    name: user.name || '',
    phone: user.phone || '',
    email: user.email || '',
    class: user.class || ''
  });
  const [loading, setLoading] = useState(false);

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
      <div className="relative w-full max-w-lg mx-auto max-h-[90vh] overflow-y-auto rounded-3xl border border-white/12 bg-gradient-to-br from-[#100713]/95 via-[#190d23]/85 to-[#10060f]/95 shadow-[0_28px_80px_-28px_rgba(12,6,20,0.92)]">
        <div className="relative px-5 sm:px-8 pt-8 sm:pt-10 pb-8">
          <div className="flex items-start justify-between gap-6">
            <div>
              <p className="text-xs font-semibold uppercase tracking-[0.24em] text-[#f3c5a0]/70">Profile</p>
              <h3 className="mt-2 text-2xl font-semibold tracking-wide text-white">Edit User</h3>
            </div>
          </div>

          <form onSubmit={handleSubmit} className="mt-8 space-y-5">
            <div>
              <label className="text-xs font-semibold uppercase tracking-[0.18em] text-white/65">Name</label>
              <input
                type="text"
                value={formData.name}
                onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                className="mt-2 block w-full rounded-2xl border border-white/10 bg-white/5 px-4 py-3 text-sm text-white placeholder-white/40 focus:border-[#EFB078]/60 focus:outline-none"
                placeholder="Enter full name"
                required
              />
            </div>
            <div>
              <label className="text-xs font-semibold uppercase tracking-[0.18em] text-white/65">Phone</label>
              <input
                type="text"
                value={formData.phone}
                onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
                className="mt-2 block w-full rounded-2xl border border-white/10 bg-white/5 px-4 py-3 text-sm text-white placeholder-white/40 focus:border-[#EFB078]/60 focus:outline-none"
                placeholder="Enter phone number"
                required
              />
            </div>
            <div>
              <label className="text-xs font-semibold uppercase tracking-[0.18em] text-white/65">Email</label>
              <input
                type="email"
                value={formData.email}
                onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                className="mt-2 block w-full rounded-2xl border border-white/10 bg-white/5 px-4 py-3 text-sm text-white placeholder-white/40 focus:border-[#EFB078]/60 focus:outline-none"
                placeholder="Enter email address"
              />
            </div>
            <div>
              <label className="text-xs font-semibold uppercase tracking-[0.18em] text-white/65">Class</label>
              <input
                type="text"
                value={formData.class}
                onChange={(e) => setFormData({ ...formData, class: e.target.value })}
                className="mt-2 block w-full rounded-2xl border border-white/10 bg-white/5 px-4 py-3 text-sm text-white placeholder-white/40 focus:border-[#EFB078]/60 focus:outline-none"
                placeholder="Enter class"
                required
              />
            </div>

            <div className="flex flex-col-reverse sm:flex-row items-stretch sm:items-center justify-end gap-3 pt-4">
              <button
                type="button"
                onClick={onClose}
                className="rounded-lg border border-white/10 bg-white/5 px-5 py-2.5 text-xs font-semibold uppercase tracking-[0.18em] text-white/75 hover:bg-white/10 hover:text-white"
              >
                Cancel
              </button>
              <button
                type="submit"
                disabled={loading}
                className="rounded-lg bg-gradient-to-r from-[#701845]/90 via-[#9E4B63]/80 to-[#EFB078]/85 px-5 py-2.5 text-xs font-semibold uppercase tracking-[0.18em] text-white shadow-[0_16px_34px_rgba(136,32,82,0.45)] disabled:opacity-50"
              >
                {loading ? 'Saving...' : 'Save Changes'}
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
};

export default AdminDashboard;
