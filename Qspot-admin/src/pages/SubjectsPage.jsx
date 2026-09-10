import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { FiEdit2, FiTrash2, FiPlus, FiSearch, FiX } from 'react-icons/fi';
import Sidebar from '../components/Sidebar';
import ConfirmDialog from '../components/dialogs/ConfirmDialog';
import brandIcon from '../assets/Icon.png';

const SubjectsPage = () => {
  const [subjects, setSubjects] = useState([]);
  const [searchTerm, setSearchTerm] = useState('');
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [showEditModal, setShowEditModal] = useState(false);
  const [editingSubject, setEditingSubject] = useState(null);
  const [deleteConfirm, setDeleteConfirm] = useState(null);
  const [selectedSubject, setSelectedSubject] = useState(null);
  const [detailLoading, setDetailLoading] = useState(false);

  useEffect(() => {
    fetchSubjects();
  }, []);

  const fetchSubjects = async () => {
    try {
      setLoading(true);
      const baseURL = import.meta.env.VITE_API_BASE_URL;
      const response = await axios.get(`${baseURL}/subjects`);
      setSubjects(response.data || []);
    } catch (err) {
      console.error('Error fetching subjects:', err);
      setError('Failed to fetch subjects');
    } finally {
      setLoading(false);
    }
  };

  const handleCreateSubject = async (formData) => {
    try {
      const token = localStorage.getItem('adminToken');
      const baseURL = import.meta.env.VITE_API_BASE_URL;
      
      const formDataToSend = new FormData();
      formDataToSend.append('name', formData.name);
      formDataToSend.append('order', formData.order);
      formDataToSend.append('image', formData.image);
      
      await axios.post(`${baseURL}/subjects`, formDataToSend, {
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'multipart/form-data'
        }
      });
      
      setShowCreateModal(false);
      fetchSubjects();
    } catch (err) {
      console.error('Error creating subject:', err);
      alert('Failed to create subject');
    }
  };

  const handleUpdateSubject = async (formData) => {
    try {
      const token = localStorage.getItem('adminToken');
      const baseURL = import.meta.env.VITE_API_BASE_URL;
      
      const formDataToSend = new FormData();
      formDataToSend.append('name', formData.name);
      formDataToSend.append('order', formData.order);
      if (formData.image) {
        formDataToSend.append('image', formData.image);
      }
      
      await axios.put(`${baseURL}/subjects/${editingSubject._id}`, formDataToSend, {
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'multipart/form-data'
        }
      });
      
      setShowEditModal(false);
      setEditingSubject(null);
      fetchSubjects();
    } catch (err) {
      console.error('Error updating subject:', err);
      alert('Failed to update subject');
    }
  };

  const handleDeleteSubject = async (subjectId) => {
    try {
      const token = localStorage.getItem('adminToken');
      const baseURL = import.meta.env.VITE_API_BASE_URL;
      
      await axios.delete(`${baseURL}/subjects/${subjectId}`, {
        headers: {
          'Authorization': `Bearer ${token}`
        }
      });
      
      setDeleteConfirm(null);
      fetchSubjects();
    } catch (err) {
      console.error('Error deleting subject:', err);
      alert('Failed to delete subject');
    }
  };

  const handleNavigate = (path) => {
    window.location.href = path;
  };

  const handleCardClick = async (subjectId) => {
    try {
      setDetailLoading(true);
      setSelectedSubject({ _id: subjectId });
      const baseURL = import.meta.env.VITE_API_BASE_URL;
      const response = await axios.get(`${baseURL}/subjects/${subjectId}`);
      setSelectedSubject(response.data);
    } catch (err) {
      console.error('Error fetching subject details:', err);
      alert('Failed to load subject details');
      setSelectedSubject(null);
    } finally {
      setDetailLoading(false);
    }
  };

  const handleEditFromDetail = () => {
    setEditingSubject(selectedSubject);
    setSelectedSubject(null);
    setShowEditModal(true);
  };

  const handleDeleteFromDetail = () => {
    setDeleteConfirm(selectedSubject);
    setSelectedSubject(null);
  };

  return (
    <div className="flex min-h-screen bg-black">
      <Sidebar currentPage="subjects" onNavigate={handleNavigate} />
      
      <div className="flex-1 flex flex-col ml-64">
        <main className="flex-1 p-6">
          <div className="mb-6 flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between">
            <div>
              <h2 className="text-3xl font-bold text-white mb-2">Subjects Management</h2>
              {/* <p className="text-gray-400">Manage educational subjects and categories</p> */}
            </div>
            <div className="flex w-full flex-col gap-3 lg:w-auto lg:flex-row lg:items-center lg:gap-4">
              <div className="relative w-full max-w-md">
                <FiSearch className="absolute left-4 top-1/2 -translate-y-1/2 text-[#f3c5a0]/70" size={18} />
                <input
                  type="text"
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  placeholder="Search subjects by name..."
                  className="w-full rounded-2xl border border-white/10 bg-gradient-to-br from-[#11060d]/60 via-[#1c0b18]/40 to-[#12060f]/60 px-12 py-3 text-sm text-white placeholder-[#f3c5a0]/55 backdrop-blur-xl transition-all focus:border-[#701845]/50 focus:outline-none focus:ring-2 focus:ring-[#701845]/30"
                />
              </div>
              <button
                onClick={() => setShowCreateModal(true)}
                className="inline-flex min-w-[155px] items-center justify-center space-x-2 rounded-2xl border-0 bg-gradient-to-r from-[#701845]/90 via-[#9E4B63]/80 to-[#EFB078]/85 px-6 py-3 text-sm font-semibold text-white shadow-[0_8px_20px_rgba(112,24,69,0.3)] transition-all hover:from-[#5a1538] hover:to-[#d49a6a] hover:shadow-[0_12px_28px_rgba(112,24,69,0.4)] focus:outline-none"
              >
                <FiPlus size={16} />
                <span>Add Subject</span>
              </button>
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
                onClick={fetchSubjects}
                className="ml-4 text-red-300 underline hover:text-red-200"
              >
                Retry
              </button>
            </div>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-4 lg:grid-cols-5 xl:grid-cols-6 gap-4">
              {subjects.length === 0 ? (
                <div className="col-span-full text-center py-12">
                  <p className="text-gray-400">No subjects found</p>
                </div>
              ) : (
                subjects
                  .filter((subject) => {
                    if (!searchTerm) return true;
                    const term = searchTerm.trim().toLowerCase();
                    return subject.name?.toLowerCase().includes(term);
                  })
                  .map((subject) => (
                    <div
                      key={subject._id}
                      onClick={() => handleCardClick(subject._id)}
                      className="relative overflow-hidden rounded-3xl border border-white/10 bg-gradient-to-br from-[#11060d]/70 via-[#1c0b18]/50 to-[#12060f]/70 shadow-[0_8px_32px_rgba(112,24,69,0.25)] backdrop-blur-xl hover:border-[#701845]/40 hover:shadow-[0_12px_40px_rgba(112,24,69,0.35)] transition-all cursor-pointer hover:scale-[1.02]"
                    >
                      <div className="relative h-[300px]">
                        <img
                          src={subject.image}
                          alt={subject.name}
                          className="h-full w-full object-cover"
                          onError={(e) => {
                            e.target.src = 'data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMjQiIGhlaWdodD0iMjQiIHZpZXdCb3g9IjAgMCAyNCAyNCIgZmlsbD0ibm9uZSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KPHJlY3Qgd2lkdGg9IjI0IiBoZWlnaHQ9IjI0IiBmaWxsPSIjMzc0MTUxIi8+CjxwYXRoIGQ9Ik0xMiA2VjE4TTYgMTJIMTgiIHN0cm9rZT0iIzlDQTNBRiIgc3Ryb2tlLXdpZHRoPSIyIiBzdHJva2UtbGluZWNhcD0icm91bmQiLz4KPC9zdmc+';
                          }}
                        />
                        {subject.order !== undefined && subject.order !== null && subject.order !== '' && (
                          <span className="absolute right-3 top-3 inline-flex items-center rounded-full bg-black/55 px-3 py-1 text-xs font-semibold text-[#EFB078] border border-white/20 shadow-[0_2px_10px_rgba(0,0,0,0.4)]" title="Order">
                            #{String(subject.order)}
                          </span>
                        )}
                        <div className="absolute inset-x-0 bottom-0 bg-gradient-to-t from-[#0b0610]/90 via-[#120a1b]/70 to-transparent px-4 py-3">
                          <h3 className="text-lg font-semibold text-white truncate">
                            {subject.name}
                          </h3>
                        </div>
                      </div>
                    </div>
                  ))
              )}
            </div>
          )}
        </main>
      </div>

      {/* Create Subject Modal */}
      {showCreateModal && (
        <CreateSubjectModal
          onClose={() => setShowCreateModal(false)}
          onSave={handleCreateSubject}
        />
      )}

      {/* Subject Detail Modal */}
      {selectedSubject && (
        <SubjectDetailModal
          subject={selectedSubject}
          loading={detailLoading}
          onClose={() => setSelectedSubject(null)}
          onEdit={handleEditFromDetail}
          onDelete={handleDeleteFromDetail}
        />
      )}

      {/* Edit Subject Modal */}
      {showEditModal && editingSubject && (
        <EditSubjectModal
          subject={editingSubject}
          onClose={() => {
            setShowEditModal(false);
            setEditingSubject(null);
          }}
          onSave={handleUpdateSubject}
        />
      )}

      {/* Delete Confirmation Modal */}
      {deleteConfirm && (
        <ConfirmDialog
          iconSrc={brandIcon}
          iconAlt="QSpot icon"
          title="Delete Subject"
          description={`Are you sure you want to delete ${
            deleteConfirm.name || 'this subject'
          }? This action cannot be undone.`}
          cancelLabel="Cancel"
          confirmLabel="Delete"
          confirmVariant="danger"
          onCancel={() => setDeleteConfirm(null)}
          onConfirm={() => handleDeleteSubject(deleteConfirm._id)}
        />
      )}
    </div>
  );
};

// Subject Detail Modal Component
const SubjectDetailModal = ({ subject, loading, onClose, onEdit, onDelete }) => {
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

        <div className="relative flex items-center justify-between border-b border-white/10 px-6 py-4">
          <div className="flex items-center gap-3">
            <div className="flex h-12 w-12 items-center justify-center rounded-xl border border-white/12 bg-black/40 shadow-[0_8px_24px_rgba(136,32,82,0.4)] backdrop-blur-sm">
              <img src={brandIcon} alt="QSpot" className="h-7 w-7 object-contain" />
            </div>
            <div>
              <p className="text-[15px] font-semibold uppercase tracking-[0.2em] text-[#f3c5a0]/60">Subject Overview</p>
            </div>
          </div>
          <button
            onClick={onClose}
            className="rounded-xl border border-white/10 bg-white/5 p-2 text-white/75 transition-all duration-200 hover:border-white/25 hover:bg-white/10 hover:text-white backdrop-blur-sm"
          >
            <FiX size={18} />
          </button>
        </div>

        <div className="relative px-6 py-5 overflow-y-auto max-h-[calc(95vh-80px)]">
          {loading ? (
            <div className="flex justify-center items-center py-12">
              <div className="animate-spin rounded-full h-10 w-10 border-b-2 border-[#EFB078]"></div>
            </div>
          ) : (
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-5">
              <div className="flex items-start justify-center">
                <div className="relative overflow-hidden rounded-2xl border border-white/10 bg-gradient-to-br from-[#11060d]/50 via-[#1c0b18]/30 to-[#12060f]/50 backdrop-blur-xl shadow-[0_12px_40px_-10px_rgba(112,24,69,0.35)] w-full">
                  <img
                    src={subject.image}
                    alt={subject.name}
                    className="w-full h-auto object-cover"
                    onError={(e) => {
                      e.target.src = 'data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMjQiIGhlaWdodD0iMjQiIHZpZXdCb3g9IjAgMCAyNCAyNCIgZmlsbD0ibm9uZSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KPHJlY3Qgd2lkdGg9IjI0IiBoZWlnaHQ9IjI0IiBmaWxsPSIjMzc0MTUxIi8+CjxwYXRoIGQ9Ik0xMiA2VjE4TTYgMTJIMTgiIHN0cm9rZT0iIzlDQTNBRiIgc3Ryb2tlLXdpZHRoPSIyIiBzdHJva2UtbGluZWNhcD0icm91bmQiLz4KPC9zdmc+';
                    }}
                  />
                </div>
              </div>

              <div className="flex flex-col justify-between space-y-4">
                <div className="space-y-3">
                  <div className="rounded-xl border border-white/10 bg-gradient-to-br from-[#11060d]/50 via-[#1c0b18]/30 to-[#12060f]/50 backdrop-blur-xl p-4 shadow-[0_8px_24px_rgba(0,0,0,0.2)]">
                    <label className="text-[10px] font-semibold uppercase tracking-[0.15em] text-white/45">Name</label>
                    <p className="mt-1.5 text-base font-semibold text-white">{subject.name || 'N/A'}</p>
                  </div>

                  {subject.order !== undefined && subject.order !== null && subject.order !== '' && (
                    <div className="rounded-xl border border-white/10 bg-gradient-to-br from-[#11060d]/50 via-[#1c0b18]/30 to-[#12060f]/50 backdrop-blur-xl p-4 shadow-[0_8px_24px_rgba(0,0,0,0.2)]">
                      <label className="text-[10px] font-semibold uppercase tracking-[0.15em] text-white/45">Order</label>
                      <p className="mt-1.5 text-base font-semibold text-white">#{String(subject.order)}</p>
                    </div>
                  )}
                </div>

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

// Create Subject Modal Component
const CreateSubjectModal = ({ onClose, onSave }) => {
  const [formData, setFormData] = useState({
    name: '',
    order: 0,
    image: null
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

  const handleImageChange = (e) => {
    const file = e.target.files[0];
    if (file) {
      setFormData({ ...formData, image: file });
    }
  };

  useEffect(() => {
    const previousOverflow = document.body.style.overflow;
    document.body.style.overflow = 'hidden';
    return () => {
      document.body.style.overflow = previousOverflow;
    };
  }, []);

  return (
    <div className="fixed inset-0 z-[120] flex h-full w-full items-center justify-center bg-black/70 px-4 py-10 backdrop-blur-md">
      <div className="relative w-full max-w-lg overflow-hidden rounded-3xl border border-white/12 bg-gradient-to-br from-[#100713]/95 via-[#190d23]/85 to-[#10060f]/95 shadow-[0_28px_80px_-28px_rgba(12,6,20,0.92)]">
        <div className="pointer-events-none absolute inset-0 bg-[radial-gradient(circle_at_top_right,rgba(136,32,82,0.55),transparent_65%)]" aria-hidden="true" />
        <div className="relative max-h-[90vh] overflow-y-auto px-7 pt-7 pb-7">
          <div className="absolute left-8 top-[60px] flex h-12 w-12 items-center justify-center rounded-2xl border border-white/12 bg-black/60 shadow-[0_14px_36px_rgba(136,32,82,0.45)]">
            <img src={brandIcon} alt="QSpot icon" className="h-7 w-7 object-contain" />
          </div>
          <div className="flex items-start justify-between gap-6 pl-18">
            <div>
              <p className="text-xs font-semibold uppercase tracking-[0.24em] text-[#f3c5a0]/70">New Entry</p>
              <h3 className="mt-2 text-2xl font-semibold tracking-wide text-white">Add New Subject</h3>
              <p className="mt-2 text-sm text-white/70">Fill in subject details and upload an image.</p>
            </div>
            <span className="mt-2 inline-flex h-2 w-2 shrink-0 rounded-full bg-gradient-to-r from-[#701845] to-[#EFB078]" />
          </div>
          <form onSubmit={handleSubmit} className="mt-8 space-y-4">
            <div>
              <label className="text-xs font-semibold uppercase tracking-[0.18em] text-white/65">Name *</label>
              <input
                type="text"
                value={formData.name}
                onChange={(e) => setFormData({...formData, name: e.target.value})}
                className="mt-2 block w-full rounded-2xl border border-white/10 bg-white/5 px-4 py-2.5 text-sm text-white placeholder-white/40 backdrop-blur-sm transition-all duration-200 focus:border-[#EFB078]/60 focus:outline-none focus:ring-0"
                placeholder="Enter subject name"
                required
              />
            </div>
            <div>
              <label className="text-xs font-semibold uppercase tracking-[0.18em] text-white/65">Order *</label>
              <input
                type="number"
                value={formData.order}
                onChange={(e) => setFormData({...formData, order: parseInt(e.target.value) || 0})}
                className="mt-2 block w-full rounded-2xl border border-white/10 bg-white/5 px-4 py-2.5 text-sm text-white placeholder-white/40 backdrop-blur-sm transition-all duration-200 focus:border-[#EFB078]/60 focus:outline-none focus:ring-0"
                placeholder="e.g., 1"
                min="0"
                required
              />
            </div>
            <div>
              <label className="text-xs font-semibold uppercase tracking-[0.18em] text-white/65">Image *</label>
              <input
                type="file"
                accept="image/*"
                onChange={handleImageChange}
                className="mt-2 block w-full rounded-2xl border border-white/10 bg-white/5 px-4 py-2.5 text-sm text-white backdrop-blur-sm transition-all duration-200 focus:border-[#EFB078]/60 focus:outline-none focus:ring-0 file:mr-4 file:rounded-xl file:border-0 file:bg-gradient-to-r file:from-[#701845]/80 file:to-[#EFB078]/70 file:px-4 file:py-2 file:text-xs file:font-semibold file:uppercase file:tracking-wide file:text-white hover:file:from-[#5a1538] hover:file:to-[#d49a6a]"
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
                {loading ? 'Creating...' : 'Create Subject'}
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
};

// Edit Subject Modal Component
const EditSubjectModal = ({ subject, onClose, onSave }) => {
  const [formData, setFormData] = useState({
    name: subject.name || '',
    order: subject.order || 0,
    image: null
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

  const handleImageChange = (e) => {
    const file = e.target.files[0];
    if (file) {
      setFormData({ ...formData, image: file });
    }
  };

  useEffect(() => {
    const previousOverflow = document.body.style.overflow;
    document.body.style.overflow = 'hidden';
    return () => {
      document.body.style.overflow = previousOverflow;
    };
  }, []);

  return (
    <div className="fixed inset-0 z-[120] flex h-full w-full items-center justify-center bg-black/70 px-4 py-10 backdrop-blur-md">
      <div className="relative w-full max-w-md overflow-hidden rounded-3xl border border-white/12 bg-gradient-to-br from-[#100713]/95 via-[#190d23]/85 to-[#10060f]/95 shadow-[0_28px_80px_-28px_rgba(12,6,20,0.92)]">
        <div className="pointer-events-none absolute inset-0 bg-[radial-gradient(circle_at_top_right,rgba(136,32,82,0.55),transparent_65%)]" aria-hidden="true" />
        <div className="relative px-6 pt-8 pb-6">
          <div className="absolute left-8 top-[60px] flex h-12 w-12 items-center justify-center rounded-2xl border border-white/12 bg-black/60 shadow-[0_14px_36px_rgba(136,32,82,0.45)]">
            <img src={brandIcon} alt="QSpot icon" className="h-7 w-7 object-contain" />
          </div>
          <div className="flex items-start justify-between gap-6 pl-18">
            <div>
              <p className="text-xs font-semibold uppercase tracking-[0.24em] text-[#f3c5a0]/70">Update</p>
              <h3 className="mt-2 text-2xl font-semibold tracking-wide text-white">Edit Subject</h3>
              <p className="mt-2 text-sm text-white/70">Modify subject details or upload a new image.</p>
            </div>
            <span className="mt-2 inline-flex h-2 w-2 shrink-0 rounded-full bg-gradient-to-r from-[#701845] to-[#EFB078]" />
          </div>
          <form onSubmit={handleSubmit} className="mt-7 space-y-4">
            <div>
              <label className="text-xs font-semibold uppercase tracking-[0.18em] text-white/65">Name *</label>
              <input
                type="text"
                value={formData.name}
                onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                className="mt-2 block w-full rounded-2xl border border-white/10 bg-white/5 px-4 py-2.5 text-sm text-white placeholder-white/40 backdrop-blur-sm transition-all duration-200 focus:border-[#EFB078]/60 focus:outline-none focus:ring-0"
                placeholder="Enter subject name"
                required
              />
            </div>
            <div>
              <label className="text-xs font-semibold uppercase tracking-[0.18em] text-white/65">Order *</label>
              <input
                type="number"
                value={formData.order}
                onChange={(e) => setFormData({ ...formData, order: parseInt(e.target.value) || 0 })}
                className="mt-2 block w-full rounded-2xl border border-white/10 bg-white/5 px-4 py-2.5 text-sm text-white placeholder-white/40 backdrop-blur-sm transition-all duration-200 focus:border-[#EFB078]/60 focus:outline-none focus:ring-0"
                placeholder="e.g., 1"
                min="0"
                required
              />
            </div>
            <div>
              <label className="text-xs font-semibold uppercase tracking-[0.18em] text-white/65">New Image (optional)</label>
              <input
                type="file"
                accept="image/*"
                onChange={handleImageChange}
                className="mt-2 block w-full rounded-2xl border border-white/10 bg-white/5 px-4 py-2.5 text-sm text-white backdrop-blur-sm transition-all duration-200 focus:border-[#EFB078]/60 focus:outline-none focus:ring-0 file:mr-4 file:rounded-xl file:border-0 file:bg-gradient-to-r file:from-[#701845]/80 file:to-[#EFB078]/70 file:px-4 file:py-2 file:text-xs file:font-semibold file:uppercase file:tracking-wide file:text-white hover:file:from-[#5a1538] hover:file:to-[#d49a6a]"
              />
              <p className="mt-2 text-xs text-white/50">Upload a new image to replace the existing one.</p>
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
                {loading ? 'Updating...' : 'Update Subject'}
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
};

export default SubjectsPage;
