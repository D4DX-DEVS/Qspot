import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { FiEdit2, FiTrash2, FiSearch, FiChevronLeft, FiChevronRight, FiUsers, FiFilter, FiX } from 'react-icons/fi';
import Sidebar from '../components/Sidebar';
import ConfirmDialog from '../components/dialogs/ConfirmDialog';
import brandIcon from '../assets/Icon.png';

const AdminDashboard = () => {
  const [adminInfo, setAdminInfo] = useState(null);
  const [users, setUsers] = useState([]);
  const [filteredUsers, setFilteredUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [editingUser, setEditingUser] = useState(null);
  const [showEditModal, setShowEditModal] = useState(false);
  const [deleteConfirm, setDeleteConfirm] = useState(null);
  const [selectedUser, setSelectedUser] = useState(null);
  const [detailLoading, setDetailLoading] = useState(false);
  
  // Pagination and search states
  const [currentPage, setCurrentPage] = useState(1);
  const [searchTerm, setSearchTerm] = useState('');
  const sortBy = 'createdAt';
  const sortOrder = 'desc';
  const itemsPerPage = 10;

  useEffect(() => {
    // Check if environment variable is available
    if (!import.meta.env.VITE_API_BASE_URL) {
      setError('Environment configuration error: API base URL not found');
      setLoading(false);
      return;
    }
    
    // Get admin info from token (you can decode JWT or make an API call)
    const token = localStorage.getItem('adminToken');
    if (token) {
      try {
        // Simple JWT decode (in production, use a proper JWT library)
        const payload = JSON.parse(atob(token.split('.')[1]));
        setAdminInfo(payload);
      } catch (error) {
        console.error('Error decoding token:', error);
      }
    }

    // Fetch users
    fetchUsers();
  }, []);

  // Filter and sort users based on search term
  useEffect(() => {
    let filtered = [...users];

    // Apply search filter
    if (searchTerm) {
      filtered = filtered.filter(user => 
        user.name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        user.email?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        user.phone?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        user.class?.toLowerCase().includes(searchTerm.toLowerCase())
      );
    }

    // Apply sorting
    filtered.sort((a, b) => {
      let aValue = a[sortBy];
      let bValue = b[sortBy];

      if (sortBy === 'createdAt') {
        aValue = new Date(aValue);
        bValue = new Date(bValue);
      } else {
        aValue = aValue?.toString().toLowerCase() || '';
        bValue = bValue?.toString().toLowerCase() || '';
      }

      if (sortOrder === 'asc') {
        return aValue > bValue ? 1 : -1;
      } else {
        return aValue < bValue ? 1 : -1;
      }
    });

    setFilteredUsers(filtered);
    setCurrentPage(1); // Reset to first page when filtering
  }, [users, searchTerm]);

  const fetchUsers = async () => {
    try {
      setLoading(true);
      const token = localStorage.getItem('adminToken');
      const baseURL = import.meta.env.VITE_API_BASE_URL;
      
      if (!baseURL) {
        throw new Error('API base URL not configured');
      }
      
      const response = await axios.get(`${baseURL}/admin/users`, {
        headers: {
          'Authorization': `Bearer ${token}`
        }
      });
      
      setUsers(response.data.users || []);
    } catch (err) {
      console.error('Error fetching users:', err);
      setError('Failed to fetch users');
    } finally {
      setLoading(false);
    }
  };

  const handleNavigate = (path) => {
    window.location.href = path;
  };

  // Pagination logic
  const totalPages = Math.ceil(filteredUsers.length / itemsPerPage);
  const startIndex = (currentPage - 1) * itemsPerPage;
  const endIndex = startIndex + itemsPerPage;
  const currentUsers = filteredUsers.slice(startIndex, endIndex);

  const handlePageChange = (page) => {
    setCurrentPage(page);
  };

  const handleEditUser = (user) => {
    setEditingUser(user);
    setShowEditModal(true);
  };

  const handleUpdateUser = async (updatedData) => {
    try {
      const token = localStorage.getItem('adminToken');
      const baseURL = import.meta.env.VITE_API_BASE_URL;
      
      if (!baseURL) {
        throw new Error('API base URL not configured');
      }
      
      await axios.put(`${baseURL}/admin/users/${editingUser._id}`, updatedData, {
        headers: {
          'Authorization': `Bearer ${token}`
        }
      });
      
      setShowEditModal(false);
      setEditingUser(null);
      fetchUsers(); // Refresh the list
    } catch (err) {
      console.error('Error updating user:', err);
      alert('Failed to update user');
    }
  };

  const handleDeleteUser = async (userId) => {
    try {
      const token = localStorage.getItem('adminToken');
      const baseURL = import.meta.env.VITE_API_BASE_URL;
      
      if (!baseURL) {
        throw new Error('API base URL not configured');
      }
      
      await axios.delete(`${baseURL}/admin/users/${userId}`, {
        headers: {
          'Authorization': `Bearer ${token}`
        }
      });
      
      setDeleteConfirm(null);
      fetchUsers(); // Refresh the list
    } catch (err) {
      console.error('Error deleting user:', err);
      alert('Failed to delete user');
    }
  };

  const handleUserClick = async (userId) => {
    try {
      setDetailLoading(true);
      setSelectedUser({ _id: userId }); // Show modal with loading state
      const token = localStorage.getItem('adminToken');
      const baseURL = import.meta.env.VITE_API_BASE_URL;
      const response = await axios.get(`${baseURL}/admin/users/${userId}`, {
        headers: {
          'Authorization': `Bearer ${token}`
        }
      });
      setSelectedUser(response.data.user);
    } catch (err) {
      console.error('Error fetching user details:', err);
      alert('Failed to load user details');
      setSelectedUser(null);
    } finally {
      setDetailLoading(false);
    }
  };

  const handleEditFromDetail = () => {
    setEditingUser(selectedUser);
    setSelectedUser(null);
    setShowEditModal(true);
  };

  const handleDeleteFromDetail = () => {
    setDeleteConfirm(selectedUser);
    setSelectedUser(null);
  };

  return (
    <div className="flex min-h-screen bg-black">
      <Sidebar currentPage="users" onNavigate={handleNavigate} />
      
      <div className="flex-1 flex flex-col ml-64">
        <main className="flex-1 p-6">
          {/* Header Section */}
          <div className="mb-8 space-y-6">
            <div className="flex flex-col gap-6 lg:flex-row lg:items-center lg:justify-between">
              <div>
                <h2 className="text-3xl font-bold text-white mb-2">Users Management</h2>
                {/* <p className="text-gray-400">Manage and view all registered users</p> */}
              </div>

              <div className="flex flex-col gap-4 lg:flex-row lg:items-center lg:gap-6 w-full lg:w-auto">
                {/* Search Section */}
                <div className="relative w-full max-w-xl lg:max-w-lg order-2 lg:order-1">
                  <FiSearch className="absolute left-4 top-1/2 transform -translate-y-1/2 text-slate-400" size={18} />
                  <input
                    type="text"
                    placeholder="Search users by name, email, phone, or class..."
                    value={searchTerm}
                    onChange={(e) => setSearchTerm(e.target.value)}
                    className="w-full pl-12 pr-4 py-3 bg-gradient-to-br from-[#11060d]/60 via-[#1c0b18]/40 to-[#12060f]/60 border border-white/10 rounded-2xl text-white placeholder-[#f3c5a0]/55 backdrop-blur-xl focus:outline-none focus:border-[#701845]/50 focus:ring-2 focus:ring-[#701845]/30 transition-all"
                  />
                </div>

                {/* Statistics Card */}
                <div className="relative overflow-hidden rounded-2xl border border-white/10 bg-gradient-to-br from-[#11060d]/80 via-[#1c0b18]/60 to-[#12060f]/80 px-5 py-4 shadow-[0_8px_32px_rgba(112,24,69,0.25)] backdrop-blur-xl min-w-[200px] order-1 lg:order-2">
                  <div className="flex items-center gap-3">
                    <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-gradient-to-br from-[#701845]/40 to-[#EFB078]/30 border border-white/10">
                      <FiUsers className="text-[#EFB078]" size={20} />
                    </div>
                    <div>
                      <p className="text-2xl font-bold text-white">{users.length}</p>
                      <p className="text-xs uppercase tracking-wide text-slate-300/70">Total Users</p>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>

          {loading ? (
            <div className="flex justify-center items-center h-64">
              <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-400"></div>
            </div>
          ) : error ? (
            <div className="bg-red-900/20 border border-red-500/30 text-red-400 px-4 py-3 rounded-md">
              {error}
              <button 
                onClick={fetchUsers}
                className="ml-4 text-red-300 underline hover:text-red-200"
              >
                Retry
              </button>
            </div>
          ) : (
            <div className="relative overflow-hidden rounded-3xl border border-white/10 bg-gradient-to-br from-[#11060d]/70 via-[#1c0b18]/50 to-[#12060f]/70 shadow-[0_20px_60px_-15px_rgba(112,24,69,0.4)] backdrop-blur-xl">
              
              {filteredUsers.length === 0 ? (
                <div className="text-center py-12">
                  <FiUsers className="mx-auto text-gray-500 mb-4" size={48} />
                  <p className="text-gray-400 text-lg">
                    {searchTerm ? 'No users found matching your search' : 'No users found'}
                  </p>
                  {searchTerm && (
                    <button
                      onClick={() => setSearchTerm('')}
                      className="mt-2 text-indigo-400 hover:text-indigo-300 transition-colors"
                    >
                      Clear search
                    </button>
                  )}
                </div>
              ) : (
                <>
                  <div className="overflow-x-auto">
                    <table className="min-w-full divide-y divide-white/5">
                      <thead className="bg-gradient-to-r from-[#11060d]/60 to-[#1c0b18]/40 backdrop-blur-sm">
                        <tr>
                          <th 
                            className="px-6 py-4 text-left text-xs font-semibold text-slate-200 uppercase tracking-wider"
                          >
                            User
                          </th>
                          <th className="px-6 py-4 text-left text-xs font-semibold text-slate-200 uppercase tracking-wider">
                            Contact
                          </th>
                          <th 
                            className="px-6 py-4 text-left text-xs font-semibold text-slate-200 uppercase tracking-wider"
                          >
                            Class
                          </th>
                          <th className="px-6 py-4 text-left text-xs font-semibold text-slate-200 uppercase tracking-wider">
                            Actions
                          </th>
                        </tr>
                      </thead>
                      <tbody className="divide-y divide-white/5">
                        {currentUsers.map((user, index) => (
                          <tr 
                            key={user._id || index} 
                            className="hover:bg-white/5 transition-colors"
                          >
                            <td 
                              className="px-6 py-4 whitespace-nowrap cursor-pointer"
                              onClick={() => handleUserClick(user._id)}
                            >
                              <div className="flex items-center">
                                <div className="flex-shrink-0 h-10 w-10">
                                  <div className="h-10 w-10 rounded-full bg-gradient-to-br from-[#701845]/80 to-[#EFB078]/70 border border-white/20 flex items-center justify-center shadow-[0_4px_12px_rgba(112,24,69,0.3)]">
                                    <span className="text-sm font-semibold text-white">
                                      {user.name?.charAt(0)?.toUpperCase() || '?'}
                                    </span>
                                  </div>
                                </div>
                                <div className="ml-4">
                                  <div className="text-sm font-medium text-white">
                                    {user.name || 'No Name'}
                                  </div>
                                </div>
                              </div>
                            </td>
                            <td 
                              className="px-6 py-4 whitespace-nowrap cursor-pointer"
                              onClick={() => handleUserClick(user._id)}
                            >
                              {user.email && (
                                <div className="text-sm text-gray-300">
                                  {user.email}
                                </div>
                              )}
                              <div className="text-sm text-gray-400">
                                {user.phone || 'No phone'}
                              </div>
                            </td>
                            <td 
                              className="px-6 py-4 whitespace-nowrap cursor-pointer"
                              onClick={() => handleUserClick(user._id)}
                            >
                              <span className="inline-flex items-center px-3 py-1 rounded-full text-xs font-semibold bg-gradient-to-r from-[#701845]/30 to-[#EFB078]/20 text-[#EFB078] border border-[#EFB078]/30 shadow-[0_2px_8px_rgba(239,176,120,0.15)]">
                                {user.class || 'Not specified'}
                              </span>
                            </td>
                            <td className="px-6 py-4 whitespace-nowrap text-sm font-medium">
                              <div className="flex space-x-2">
                                <button
                                  onClick={(e) => {
                                    e.stopPropagation();
                                    handleEditUser(user);
                                  }}
                                  className="text-[#EFB078] hover:text-white transition-all p-2 rounded-xl hover:bg-gradient-to-br hover:from-[#701845]/30 hover:to-[#EFB078]/20 border border-transparent hover:border-[#EFB078]/30"
                                  title="Edit user"
                                >
                                  <FiEdit2 size={16} />
                                </button>
                                <button
                                  onClick={(e) => {
                                    e.stopPropagation();
                                    setDeleteConfirm(user);
                                  }}
                                  className="text-red-400 hover:text-white transition-all p-2 rounded-xl hover:bg-gradient-to-br hover:from-red-900/40 hover:to-red-600/30 border border-transparent hover:border-red-400/40"
                                  title="Delete user"
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

                  {/* Pagination */}
                  {totalPages > 1 && (
                    <div className="bg-gradient-to-r from-[#11060d]/40 to-[#1c0b18]/30 px-6 py-4 border-t border-white/5 backdrop-blur-sm">
                      <div className="flex items-center justify-between">
                        <div className="text-sm text-gray-400">
                          Showing {startIndex + 1} to {Math.min(endIndex, filteredUsers.length)} of {filteredUsers.length} users
                        </div>
                        <div className="flex items-center space-x-2">
                          <button
                            onClick={() => handlePageChange(currentPage - 1)}
                            disabled={currentPage === 1}
                            className="p-2 rounded-xl bg-gradient-to-br from-[#11060d]/60 to-[#1c0b18]/40 border border-white/10 text-slate-300 hover:border-[#701845]/50 hover:text-white disabled:opacity-50 disabled:cursor-not-allowed transition-all backdrop-blur-sm"
                          >
                            <FiChevronLeft size={16} />
                          </button>
                          
                          {Array.from({ length: totalPages }, (_, i) => i + 1).map((page) => {
                            // Show first page, last page, current page, and pages around current page
                            if (
                              page === 1 ||
                              page === totalPages ||
                              (page >= currentPage - 1 && page <= currentPage + 1)
                            ) {
                              return (
                                <button
                                  key={page}
                                  onClick={() => handlePageChange(page)}
                                  className={`px-3 py-2 rounded-xl text-sm font-semibold transition-all backdrop-blur-sm ${
                                    currentPage === page
                                      ? 'bg-gradient-to-r from-[#701845]/90 to-[#EFB078]/80 text-white border border-transparent shadow-[0_4px_12px_rgba(112,24,69,0.3)]'
                                      : 'bg-gradient-to-br from-[#11060d]/60 to-[#1c0b18]/40 border border-white/10 text-slate-300 hover:border-[#701845]/50 hover:text-white'
                                  }`}
                                >
                                  {page}
                                </button>
                              );
                            } else if (
                              page === currentPage - 2 ||
                              page === currentPage + 2
                            ) {
                              return <span key={page} className="text-gray-500">...</span>;
                            }
                            return null;
                          })}
                          
                          <button
                            onClick={() => handlePageChange(currentPage + 1)}
                            disabled={currentPage === totalPages}
                            className="p-2 rounded-xl bg-gradient-to-br from-[#11060d]/60 to-[#1c0b18]/40 border border-white/10 text-slate-300 hover:border-[#701845]/50 hover:text-white disabled:opacity-50 disabled:cursor-not-allowed transition-all backdrop-blur-sm"
                          >
                            <FiChevronRight size={16} />
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

      {/* User Detail Modal */}
      {selectedUser && (
        <UserDetailModal
          user={selectedUser}
          loading={detailLoading}
          onClose={() => setSelectedUser(null)}
          onEdit={handleEditFromDetail}
          onDelete={handleDeleteFromDetail}
        />
      )}

      {/* Edit User Modal */}
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

      {/* Delete Confirmation Modal */}
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

// User Detail Modal Component
const UserDetailModal = ({ user, loading, onClose, onEdit, onDelete }) => {
  useEffect(() => {
    const previousOverflow = document.body.style.overflow;
    document.body.style.overflow = 'hidden';
    return () => {
      document.body.style.overflow = previousOverflow;
    };
  }, []);

  return (
    <div className="fixed inset-0 z-[120] flex items-center justify-center bg-black/70 p-4 backdrop-blur-md">
      <div className="relative w-full max-w-3xl max-h-[95vh] overflow-hidden rounded-3xl border border-white/10 bg-gradient-to-br from-[#11060d]/70 via-[#1c0b18]/50 to-[#12060f]/70 shadow-[0_25px_70px_-25px_rgba(112,24,69,0.6)] backdrop-blur-xl">
        <div
          className="pointer-events-none absolute inset-0 bg-[radial-gradient(circle_at_top_right,rgba(136,32,82,0.45),transparent_60%)]"
          aria-hidden="true"
        />

        {/* Header with Icon and Close Button */}
        <div className="relative flex items-center justify-between border-b border-white/10 px-6 py-4">
          <div className="flex items-center gap-3">
            <div className="flex h-12 w-12 items-center justify-center rounded-xl border border-white/12 bg-black/40 shadow-[0_8px_24px_rgba(136,32,82,0.4)] backdrop-blur-sm">
              <img src={brandIcon} alt="QSpot" className="h-7 w-7 object-contain" />
            </div>
            <div>
              <p className="text-[15px] font-semibold uppercase tracking-[0.2em] text-[#f3c5a0]/60">User Profile</p>
            </div>
          </div>
          <button
            onClick={onClose}
            className="rounded-xl border border-white/10 bg-white/5 p-2 text-white/75 transition-all duration-200 hover:border-white/25 hover:bg-white/10 hover:text-white backdrop-blur-sm"
          >
            <FiX size={18} />
          </button>
        </div>

        {/* Content */}
        <div className="relative px-6 py-5 overflow-y-auto max-h-[calc(95vh-80px)]">
          {loading ? (
            <div className="flex justify-center items-center py-12">
              <div className="animate-spin rounded-full h-10 w-10 border-b-2 border-[#EFB078]"></div>
            </div>
          ) : (
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-5">
              {/* Left Column - User Avatar */}
              <div className="flex items-start justify-center">
                <div className="relative overflow-hidden rounded-2xl border border-white/10 bg-gradient-to-br from-[#11060d]/50 via-[#1c0b18]/30 to-[#12060f]/50 backdrop-blur-xl shadow-[0_12px_40px_-10px_rgba(112,24,69,0.35)] p-8 w-full flex items-center justify-center">
                  <div className="h-48 w-48 rounded-full bg-gradient-to-br from-[#701845]/80 to-[#EFB078]/70 border-4 border-white/20 flex items-center justify-center shadow-[0_8px_24px_rgba(112,24,69,0.4)]">
                    <span className="text-6xl font-bold text-white">
                      {user.name?.charAt(0)?.toUpperCase() || '?'}
                    </span>
                  </div>
                </div>
              </div>

              {/* Right Column - User Information */}
              <div className="flex flex-col justify-between space-y-4">
                <div className="space-y-3">
                  <div className="rounded-xl border border-white/10 bg-gradient-to-br from-[#11060d]/50 via-[#1c0b18]/30 to-[#12060f]/50 backdrop-blur-xl p-4 shadow-[0_8px_24px_rgba(0,0,0,0.2)]">
                    <label className="text-[10px] font-semibold uppercase tracking-[0.15em] text-white/45">Name</label>
                    <p className="mt-1.5 text-base font-semibold text-white">{user.name || 'N/A'}</p>
                  </div>

                  {user.email && (
                    <div className="rounded-xl border border-white/10 bg-gradient-to-br from-[#11060d]/50 via-[#1c0b18]/30 to-[#12060f]/50 backdrop-blur-xl p-4 shadow-[0_8px_24px_rgba(0,0,0,0.2)]">
                      <label className="text-[10px] font-semibold uppercase tracking-[0.15em] text-white/45">Email</label>
                      <p className="mt-1.5 text-base text-white/90">{user.email}</p>
                    </div>
                  )}

                  <div className="rounded-xl border border-white/10 bg-gradient-to-br from-[#11060d]/50 via-[#1c0b18]/30 to-[#12060f]/50 backdrop-blur-xl p-4 shadow-[0_8px_24px_rgba(0,0,0,0.2)]">
                    <label className="text-[10px] font-semibold uppercase tracking-[0.15em] text-white/45">Phone</label>
                    <p className="mt-1.5 text-base text-white/90">{user.phone || 'No phone'}</p>
                  </div>

                  <div className="rounded-xl border border-white/10 bg-gradient-to-br from-[#11060d]/50 via-[#1c0b18]/30 to-[#12060f]/50 backdrop-blur-xl p-4 shadow-[0_8px_24px_rgba(0,0,0,0.2)]">
                    <label className="text-[10px] font-semibold uppercase tracking-[0.15em] text-white/45">Class</label>
                    <p className="mt-1.5 text-base font-semibold text-white">{user.class || 'Not specified'}</p>
                  </div>

                  <div className="rounded-xl border border-white/10 bg-gradient-to-br from-[#11060d]/50 via-[#1c0b18]/30 to-[#12060f]/50 backdrop-blur-xl p-4 shadow-[0_8px_24px_rgba(0,0,0,0.2)]">
                    <label className="text-[10px] font-semibold uppercase tracking-[0.15em] text-white/45">User ID</label>
                    <p className="mt-1.5 text-sm font-mono text-white/80">{user._id || 'Unknown'}</p>
                  </div>
                </div>

                {/* Action Buttons */}
                <div className="flex items-center justify-end gap-2.5 pt-3 border-t border-white/10">
                  <button
                    onClick={onEdit}
                    className="flex items-center gap-2 rounded-xl border border-white/10 bg-gradient-to-r from-[#701845]/30 to-[#EFB078]/20 px-4 py-2 text-sm font-semibold text-[#EFB078] transition-all duration-200 hover:border-[#EFB078]/30 hover:from-[#701845]/40 hover:to-[#EFB078]/30 hover:text-white backdrop-blur-sm shadow-[0_4px_16px_rgba(112,24,69,0.25)]"
                  >
                    <FiEdit2 size={15} />
                    <span>Edit</span>
                  </button>
                  <button
                    onClick={onDelete}
                    className="flex items-center gap-2 rounded-xl border border-white/10 bg-gradient-to-r from-red-900/30 to-red-600/20 px-4 py-2 text-sm font-semibold text-red-400 transition-all duration-200 hover:border-red-400/30 hover:from-red-900/40 hover:to-red-600/30 hover:text-white backdrop-blur-sm shadow-[0_4px_16px_rgba(185,28,28,0.25)]"
                  >
                    <FiTrash2 size={15} />
                    <span>Delete</span>
                  </button>
                </div>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

// Edit User Modal Component
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
      <div className="relative w-full max-w-lg overflow-hidden rounded-3xl border border-white/12 bg-gradient-to-br from-[#100713]/95 via-[#190d23]/85 to-[#10060f]/95 shadow-[0_28px_80px_-28px_rgba(12,6,20,0.92)]">
        <div
          className="pointer-events-none absolute inset-0 bg-[radial-gradient(circle_at_top_right,rgba(136,32,82,0.55),transparent_65%)]"
          aria-hidden="true"
        />

        <div className="relative px-8 pt-10 pb-8">
          <div className="flex items-start justify-between gap-6">
            <div>
              <p className="text-xs font-semibold uppercase tracking-[0.24em] text-[#f3c5a0]/70">Profile</p>
              <h3 className="mt-2 text-2xl font-semibold tracking-wide text-white">Edit User</h3>
              <p className="mt-2 text-sm text-white/70">
                Update user details below. Changes save instantly after confirmation.
              </p>
            </div>
            <span className="mt-2 inline-flex h-2 w-2 shrink-0 rounded-full bg-gradient-to-r from-[#701845] to-[#EFB078]" />
          </div>

          <form onSubmit={handleSubmit} className="mt-8 space-y-5">
            <div>
              <label className="text-xs font-semibold uppercase tracking-[0.18em] text-white/65">Name</label>
              <input
                type="text"
                value={formData.name}
                onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                className="mt-2 block w-full rounded-2xl border border-white/10 bg-white/5 px-4 py-3 text-sm text-white placeholder-white/40 backdrop-blur-sm transition-all duration-200 focus:border-[#EFB078]/60 focus:outline-none focus:ring-0"
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
                className="mt-2 block w-full rounded-2xl border border-white/10 bg-white/5 px-4 py-3 text-sm text-white placeholder-white/40 backdrop-blur-sm transition-all duration-200 focus:border-[#EFB078]/60 focus:outline-none focus:ring-0"
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
                className="mt-2 block w-full rounded-2xl border border-white/10 bg-white/5 px-4 py-3 text-sm text-white placeholder-white/40 backdrop-blur-sm transition-all duration-200 focus:border-[#EFB078]/60 focus:outline-none focus:ring-0"
                placeholder="Enter email address"
              />
            </div>
            <div>
              <label className="text-xs font-semibold uppercase tracking-[0.18em] text-white/65">Class</label>
              <input
                type="text"
                value={formData.class}
                onChange={(e) => setFormData({ ...formData, class: e.target.value })}
                className="mt-2 block w-full rounded-2xl border border-white/10 bg-white/5 px-4 py-3 text-sm text-white placeholder-white/40 backdrop-blur-sm transition-all duration-200 focus:border-[#EFB078]/60 focus:outline-none focus:ring-0"
                placeholder="Enter class"
                required
              />
            </div>

            <div className="flex items-center justify-end gap-3 pt-4">
              <button
                type="button"
                onClick={onClose}
                className="rounded-lg border border-white/10 bg-white/5 px-5 py-2.5 text-xs font-semibold uppercase tracking-[0.18em] text-white/75 transition-all duration-200 hover:border-white/20 hover:bg-white/10 hover:text-white focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-white/30"
              >
                Cancel
              </button>
              <button
                type="submit"
                disabled={loading}
                className="rounded-lg bg-gradient-to-r from-[#701845]/90 via-[#9E4B63]/80 to-[#EFB078]/85 px-5 py-2.5 text-xs font-semibold uppercase tracking-[0.18em] text-white shadow-[0_16px_34px_rgba(136,32,82,0.45)] transition-all duration-200 hover:scale-[1.01] disabled:opacity-50 disabled:shadow-none focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#EFB078]/70"
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

