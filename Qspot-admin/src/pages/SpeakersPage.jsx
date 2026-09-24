import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { FiEdit2, FiTrash2, FiPlus, FiX, FiSearch } from 'react-icons/fi';
import Sidebar from '../components/Sidebar';
import ConfirmDialog from '../components/dialogs/ConfirmDialog';
import ErrorState from '../components/ui/ErrorState';
import Spinner from '../components/ui/Spinner';
import usePageTitle from '../hooks/usePageTitle';
import useBodyScrollLock from '../hooks/useBodyScrollLock';
import apiClient from '../api/client';
import { PLACEHOLDER_IMAGE } from '../constants/placeholder';
import brandIcon from '../assets/Icon.png';

const SpeakersPage = () => {
  usePageTitle('Speakers');
  const navigate = useNavigate();
  const [speakers, setSpeakers] = useState([]);
  const [searchTerm, setSearchTerm] = useState('');
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [showEditModal, setShowEditModal] = useState(false);
  const [editingSpeaker, setEditingSpeaker] = useState(null);
  const [deleteConfirm, setDeleteConfirm] = useState(null);
  const [selectedSpeaker, setSelectedSpeaker] = useState(null);
  const [detailLoading, setDetailLoading] = useState(false);

  useEffect(() => {
    fetchSpeakers();
  }, []);

  const fetchSpeakers = async () => {
    try {
      setLoading(true);
      setError('');
      const response = await apiClient.get('/speakers');
      const data = Array.isArray(response.data) ? [...response.data] : [];
      data.sort((a, b) => {
        const aNum = Number(a?.order);
        const bNum = Number(b?.order);
        const aHas = !Number.isNaN(aNum);
        const bHas = !Number.isNaN(bNum);
        if (aHas && bHas) return aNum - bNum; // ascending by order
        if (aHas) return -1; // items with order come first
        if (bHas) return 1;
        return 0;
      });
      setSpeakers(data);
    } catch (err) {
      setError(err.message || 'Failed to fetch speakers');
    } finally {
      setLoading(false);
    }
  };

  const handleCreateSpeaker = async (formData) => {
    try {
      const formDataToSend = new FormData();
      formDataToSend.append('name', formData.name);
      formDataToSend.append('designation', formData.designation);
      formDataToSend.append('order', formData.order === '' ? '0' : String(formData.order));
      formDataToSend.append('image', formData.image);
      await apiClient.post('/speakers', formDataToSend, {
        headers: { 'Content-Type': 'multipart/form-data' }
      });
      setShowCreateModal(false);
      fetchSpeakers();
    } catch (err) {
      alert(err.message || 'Failed to create speaker');
    }
  };

  const handleUpdateSpeaker = async (formData) => {
    try {
      const formDataToSend = new FormData();
      formDataToSend.append('name', formData.name);
      formDataToSend.append('designation', formData.designation);
      formDataToSend.append('order', formData.order === '' ? '0' : String(formData.order));
      if (formData.image) {
        formDataToSend.append('image', formData.image);
      }
      await apiClient.put(`/speakers/${editingSpeaker._id}`, formDataToSend, {
        headers: { 'Content-Type': 'multipart/form-data' }
      });
      setShowEditModal(false);
      setEditingSpeaker(null);
      fetchSpeakers();
    } catch (err) {
      alert(err.message || 'Failed to update speaker');
    }
  };

  const handleDeleteSpeaker = async (speakerId) => {
    try {
      await apiClient.delete(`/speakers/${speakerId}`);
      setDeleteConfirm(null);
      fetchSpeakers();
    } catch (err) {
      // 409 (speaker has videos/schedules/questions) carries a counts message
      // from the server (CONTRACT.md); apiClient already surfaces it here.
      alert(err.message || 'Failed to delete speaker');
    }
  };

  const handleCardClick = async (speakerId) => {
    try {
      setDetailLoading(true);
      setSelectedSpeaker({ _id: speakerId });
      const response = await apiClient.get(`/speakers/${speakerId}`);
      setSelectedSpeaker(response.data);
    } catch (err) {
      alert(err.message || 'Failed to load speaker details');
      setSelectedSpeaker(null);
    } finally {
      setDetailLoading(false);
    }
  };

  const handleEditFromDetail = () => {
    setEditingSpeaker(selectedSpeaker);
    setSelectedSpeaker(null);
    setShowEditModal(true);
  };

  const handleDeleteFromDetail = () => {
    setDeleteConfirm(selectedSpeaker);
    setSelectedSpeaker(null);
  };

  return (
    <div className="flex min-h-screen overflow-x-hidden bg-black">
      <Sidebar currentPage="speakers" onNavigate={navigate} />
      
      <div className="flex-1 flex flex-col w-full pb-28 md:ml-64 md:pb-0">
        <main className="flex-1 p-4 sm:p-6">
          <div className="mb-6 flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
            <div>
              <h2 className="text-2xl sm:text-3xl font-bold text-white mb-2">Speakers Management</h2>
              {/* <p className="text-gray-400">Manage speakers and their information</p> */}
            </div>
            <div className="flex w-full flex-col gap-3 sm:flex-row sm:items-center sm:gap-4 md:w-auto">
              <div className="relative w-full sm:max-w-md">
                <FiSearch className="absolute left-4 top-1/2 -translate-y-1/2 text-[#f3c5a0]/70" size={18} />
                <input
                  type="text"
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  placeholder="Search speakers by name or designation..."
                  className="w-full rounded-2xl border border-white/10 bg-gradient-to-br from-[#11060d]/60 via-[#1c0b18]/40 to-[#12060f]/60 px-12 py-3 text-sm text-white placeholder-[#f3c5a0]/55 backdrop-blur-xl transition-all focus:border-[#701845]/50 focus:outline-none focus:ring-2 focus:ring-[#701845]/30"
                />
              </div>
              <button
                onClick={() => setShowCreateModal(true)}
                className="inline-flex w-full sm:w-auto sm:min-w-[155px] items-center justify-center space-x-2 rounded-2xl border-0 bg-gradient-to-r from-[#701845]/90 via-[#9E4B63]/80 to-[#EFB078]/85 px-6 py-3 text-sm font-semibold text-white shadow-[0_8px_20px_rgba(112,24,69,0.3)] transition-all hover:from-[#5a1538] hover:to-[#d49a6a] hover:shadow-[0_12px_28px_rgba(112,24,69,0.4)] focus:outline-none"
              >
                <FiPlus size={16} />
                <span>Add Speaker</span>
              </button>
            </div>
          </div>

          {loading ? (
            <Spinner />
          ) : error ? (
            <ErrorState message={error} onRetry={fetchSpeakers} />
          ) : (
            <div className="grid grid-cols-3 gap-2.5 sm:gap-5 md:grid-cols-3 xl:grid-cols-4">
              {speakers.length === 0 ? (
                <div className="col-span-full text-center py-12">
                  <p className="text-gray-400">No speakers found</p>
                </div>
              ) : (
                speakers
                  .filter((speaker) => {
                    if (!searchTerm) return true;
                    const term = searchTerm.trim().toLowerCase();
                    return (
                      speaker.name?.toLowerCase().includes(term) ||
                      speaker.designation?.toLowerCase().includes(term)
                    );
                  })
                  .map((speaker) => (
                  <div 
                    key={speaker._id} 
                    onClick={() => handleCardClick(speaker._id)}
                    className="relative overflow-hidden rounded-xl sm:rounded-3xl border border-white/10 bg-gradient-to-br from-[#11060d]/70 via-[#1c0b18]/50 to-[#12060f]/70 shadow-[0_8px_32px_rgba(112,24,69,0.25)] backdrop-blur-xl hover:border-[#701845]/40 hover:shadow-[0_12px_40px_rgba(112,24,69,0.35)] transition-all cursor-pointer hover:scale-[1.02]"
                  >
                    <div className="relative aspect-[3/4] sm:aspect-auto sm:h-[260px]">
                      <img
                        src={speaker.image}
                        alt={speaker.name}
                        className="h-full w-full object-cover"
                        onError={(e) => {
                          e.target.src = PLACEHOLDER_IMAGE;
                        }}
                      />
                      {speaker.order !== undefined && speaker.order !== '' && (
                        <span className="absolute right-1.5 top-1.5 inline-flex items-center rounded-full bg-black/55 px-1.5 py-0.5 text-[10px] sm:right-3 sm:top-3 sm:px-3 sm:py-1 sm:text-xs font-semibold text-[#EFB078] border border-white/20 shadow-[0_2px_10px_rgba(0,0,0,0.4)]" title="Order">
                          #{String(speaker.order)}
                        </span>
                      )}
                      <div className="absolute inset-x-0 bottom-0 bg-gradient-to-t from-[#0b0610]/90 via-[#120a1b]/70 to-transparent px-2 py-2 sm:px-4 sm:py-3">
                        <div className="flex items-start justify-between gap-1.5 sm:gap-3">
                          <div className="min-w-0">
                            <h3 className="text-[11px] sm:text-lg font-semibold text-white truncate">
                              {speaker.name}
                            </h3>
                            <p className="mt-0.5 sm:mt-1 text-[9px] sm:text-sm text-white/75 truncate">
                              {speaker.designation || 'No designation'}
                            </p>
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>
                ))
              )}
            </div>
          )}
        </main>
      </div>

      {/* Create Speaker Modal */}
      {showCreateModal && (
        <CreateSpeakerModal
          onClose={() => setShowCreateModal(false)}
          onSave={handleCreateSpeaker}
        />
      )}

      {/* Edit Speaker Modal */}
      {showEditModal && editingSpeaker && (
        <EditSpeakerModal
          speaker={editingSpeaker}
          onClose={() => {
            setShowEditModal(false);
            setEditingSpeaker(null);
          }}
          onSave={handleUpdateSpeaker}
        />
      )}

      {/* Speaker Detail Modal */}
      {selectedSpeaker && (
        <SpeakerDetailModal
          speaker={selectedSpeaker}
          loading={detailLoading}
          onClose={() => setSelectedSpeaker(null)}
          onEdit={handleEditFromDetail}
          onDelete={handleDeleteFromDetail}
        />
      )}

      {/* Delete Confirmation Modal */}
      {deleteConfirm && (
        <ConfirmDialog
          iconSrc={brandIcon}
          iconAlt="QSpot icon"
          title="Delete Speaker"
          description={`Are you sure you want to delete ${
            deleteConfirm.name || 'this speaker'
          }? This action cannot be undone.`}
          cancelLabel="Cancel"
          confirmLabel="Delete"
          confirmVariant="danger"
          onCancel={() => setDeleteConfirm(null)}
          onConfirm={() => handleDeleteSpeaker(deleteConfirm._id)}
        />
      )}
    </div>
  );
};

// Speaker Detail Modal Component
const SpeakerDetailModal = ({ speaker, loading, onClose, onEdit, onDelete }) => {
  useBodyScrollLock(true);

  return (
    <div className="fixed inset-0 z-[120] flex items-center justify-center bg-black/70 p-4 backdrop-blur-md">
      <div className="relative w-full max-w-3xl max-h-[95vh] overflow-hidden rounded-3xl border border-white/10 bg-gradient-to-br from-[#11060d]/70 via-[#1c0b18]/50 to-[#12060f]/70 shadow-[0_25px_70px_-25px_rgba(112,24,69,0.6)] backdrop-blur-xl">
        <div
          className="pointer-events-none absolute inset-0 bg-[radial-gradient(circle_at_top_right,rgba(136,32,82,0.45),transparent_60%)]"
          aria-hidden="true"
        />

        {/* Header with Icon and Close Button */}
        <div className="relative flex items-center justify-between gap-3 border-b border-white/10 px-4 sm:px-6 py-4">
          <div className="flex items-center gap-3 min-w-0">
            <div className="flex h-12 w-12 shrink-0 items-center justify-center rounded-xl border border-white/12 bg-black/40 shadow-[0_8px_24px_rgba(136,32,82,0.4)] backdrop-blur-sm">
              <img src={brandIcon} alt="QSpot" className="h-7 w-7 object-contain" />
            </div>
            <div className="min-w-0">
              <p className="text-[15px] font-semibold uppercase tracking-[0.2em] text-[#f3c5a0]/60 truncate">Speaker Profile</p>
              {/*  <h3 className="mt-0.5 text-lg font-semibold tracking-wide text-white">Speaker Details</h3> */}
            </div>
          </div>
          <button
            onClick={onClose}
            className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl border border-white/10 bg-white/5 text-white/75 transition-all duration-200 hover:border-white/25 hover:bg-white/10 hover:text-white backdrop-blur-sm"
          >
            <FiX size={18} />
          </button>
        </div>

        {/* Content */}
        <div className="relative px-4 sm:px-6 py-5 overflow-y-auto max-h-[calc(95vh-80px)]">
          {loading ? (
            <div className="flex justify-center items-center py-12">
              <div className="animate-spin rounded-full h-10 w-10 border-b-2 border-[#EFB078]"></div>
            </div>
          ) : (
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-5">
              {/* Left Column - Speaker Image */}
              <div className="flex items-start justify-center">
                <div className="relative overflow-hidden rounded-2xl border border-white/10 bg-gradient-to-br from-[#11060d]/50 via-[#1c0b18]/30 to-[#12060f]/50 backdrop-blur-xl shadow-[0_12px_40px_-10px_rgba(112,24,69,0.35)] w-full">
                  <img
                    src={speaker.image}
                    alt={speaker.name}
                    className="w-full h-auto object-cover"
                    onError={(e) => {
                      e.target.src = PLACEHOLDER_IMAGE;
                    }}
                  />
                </div>
              </div>

              {/* Right Column - Speaker Information */}
              <div className="flex flex-col justify-between space-y-4">
                <div className="space-y-3">
                  <div className="rounded-xl border border-white/10 bg-gradient-to-br from-[#11060d]/50 via-[#1c0b18]/30 to-[#12060f]/50 backdrop-blur-xl p-4 shadow-[0_8px_24px_rgba(0,0,0,0.2)]">
                    <label className="text-[10px] font-semibold uppercase tracking-[0.15em] text-white/45">Name</label>
                    <p className="mt-1.5 text-base font-semibold text-white">{speaker.name || 'N/A'}</p>
                  </div>

                  <div className="rounded-xl border border-white/10 bg-gradient-to-br from-[#11060d]/50 via-[#1c0b18]/30 to-[#12060f]/50 backdrop-blur-xl p-4 shadow-[0_8px_24px_rgba(0,0,0,0.2)]">
                    <label className="text-[10px] font-semibold uppercase tracking-[0.15em] text-white/45">Designation</label>
                    <p className="mt-1.5 text-base text-white/90">{speaker.designation || 'No designation provided'}</p>
                  </div>

                  {speaker.order !== undefined && speaker.order !== '' && (
                    <div className="rounded-xl border border-white/10 bg-gradient-to-br from-[#11060d]/50 via-[#1c0b18]/30 to-[#12060f]/50 backdrop-blur-xl p-4 shadow-[0_8px_24px_rgba(0,0,0,0.2)]">
                      <label className="text-[10px] font-semibold uppercase tracking-[0.15em] text-white/45">Order</label>
                      <p className="mt-1.5 text-base font-semibold text-white">#{String(speaker.order)}</p>
                    </div>
                  )}
                </div>

                {/* Action Buttons */}
                <div className="flex flex-wrap items-center justify-end gap-2.5 pt-3 border-t border-white/10">
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

// Create Speaker Modal Component
const CreateSpeakerModal = ({ onClose, onSave }) => {
  const [formData, setFormData] = useState({
    name: '',
    designation: '',
    order: '',
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

  useBodyScrollLock(true);

  return (
    <div className="fixed inset-0 z-[120] flex h-full w-full items-center justify-center overflow-y-auto bg-black/70 px-4 py-10 backdrop-blur-md">
      <div className="relative w-full max-w-lg overflow-hidden rounded-3xl border border-white/12 bg-gradient-to-br from-[#100713]/95 via-[#190d23]/85 to-[#10060f]/95 shadow-[0_28px_80px_-28px_rgba(12,6,20,0.92)]">
        <div
          className="pointer-events-none absolute inset-0 bg-[radial-gradient(circle_at_top_right,rgba(136,32,82,0.55),transparent_65%)]"
          aria-hidden="true"
        />

        <div className="relative max-h-[90vh] overflow-y-auto px-5 sm:px-8 pt-8 pb-8">
          <div className="absolute left-5 sm:left-8 top-[60px] flex h-12 w-12 items-center justify-center rounded-2xl border border-white/12 bg-black/60 shadow-[0_14px_36px_rgba(136,32,82,0.45)]">
            <img src={brandIcon} alt="QSpot icon" className="h-7 w-7 object-contain" />
          </div>
          <div className="flex items-start justify-between gap-6 pl-16 sm:pl-18">
            <div>
              <p className="text-xs font-semibold uppercase tracking-[0.24em] text-[#f3c5a0]/70">New Entry</p>
              <h3 className="mt-2 text-xl sm:text-2xl font-semibold tracking-wide text-white">Add New Speaker</h3>
              <p className="mt-2 text-sm text-white/70">
                Fill in speaker details and upload an image.
              </p>
            </div>
            <span className="mt-2 inline-flex h-2 w-2 shrink-0 rounded-full bg-gradient-to-r from-[#701845] to-[#EFB078]" />
          </div>

          <form onSubmit={handleSubmit} className="mt-8 space-y-5">
            <div>
              <label className="text-xs font-semibold uppercase tracking-[0.18em] text-white/65">Name *</label>
              <input
                type="text"
                value={formData.name}
                onChange={(e) => setFormData({...formData, name: e.target.value})}
                className="mt-2 block w-full rounded-2xl border border-white/10 bg-white/5 px-4 py-3 text-sm text-white placeholder-white/40 backdrop-blur-sm transition-all duration-200 focus:border-[#EFB078]/60 focus:outline-none focus:ring-0"
                placeholder="Enter speaker name"
                required
              />
            </div>
            <div>
              <label className="text-xs font-semibold uppercase tracking-[0.18em] text-white/65">Designation</label>
              <input
                type="text"
                value={formData.designation}
                onChange={(e) => setFormData({...formData, designation: e.target.value})}
                className="mt-2 block w-full rounded-2xl border border-white/10 bg-white/5 px-4 py-3 text-sm text-white placeholder-white/40 backdrop-blur-sm transition-all duration-200 focus:border-[#EFB078]/60 focus:outline-none focus:ring-0"
                placeholder="Enter designation"
              />
            </div>
            <div>
              <label className="text-xs font-semibold uppercase tracking-[0.18em] text-white/65">Order (number)</label>
              <input
                type="number"
                inputMode="numeric"
                value={formData.order}
                onChange={(e) => setFormData({ ...formData, order: e.target.value })}
                className="mt-2 block w-full rounded-2xl border border-white/10 bg-white/5 px-4 py-3 text-sm text-white placeholder-white/40 backdrop-blur-sm transition-all duration-200 focus:border-[#EFB078]/60 focus:outline-none focus:ring-0"
                placeholder="e.g., 1"
                min="0"
              />
            </div>
            <div>
              <label className="text-xs font-semibold uppercase tracking-[0.18em] text-white/65">Image *</label>
              <input
                type="file"
                accept="image/*"
                onChange={handleImageChange}
                className="mt-2 block w-full rounded-2xl border border-white/10 bg-white/5 px-4 py-3 text-sm text-white backdrop-blur-sm transition-all duration-200 focus:border-[#EFB078]/60 focus:outline-none focus:ring-0 file:mr-4 file:rounded-xl file:border-0 file:bg-gradient-to-r file:from-[#701845]/80 file:to-[#EFB078]/70 file:px-4 file:py-2 file:text-xs file:font-semibold file:uppercase file:tracking-wide file:text-white hover:file:from-[#5a1538] hover:file:to-[#d49a6a]"
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
                {loading ? 'Creating...' : 'Create Speaker'}
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
};

// Edit Speaker Modal Component
const EditSpeakerModal = ({ speaker, onClose, onSave }) => {
  const [formData, setFormData] = useState({
    name: speaker.name || '',
    designation: speaker.designation || '',
    order: speaker.order ?? '',
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

  useBodyScrollLock(true);

  return (
    <div className="fixed inset-0 z-[120] flex h-full w-full items-center justify-center overflow-y-auto bg-black/70 px-4 py-10 backdrop-blur-md">
      <div className="relative w-full max-w-lg overflow-hidden rounded-3xl border border-white/12 bg-gradient-to-br from-[#100713]/95 via-[#190d23]/85 to-[#10060f]/95 shadow-[0_28px_80px_-28px_rgba(12,6,20,0.92)]">
        <div
          className="pointer-events-none absolute inset-0 bg-[radial-gradient(circle_at_top_right,rgba(136,32,82,0.55),transparent_65%)]"
          aria-hidden="true"
        />

        <div className="relative max-h-[90vh] overflow-y-auto px-5 sm:px-8 pt-12 pb-8">
          <div className="absolute left-5 sm:left-8 top-[60px] flex h-12 w-12 items-center justify-center rounded-2xl border border-white/12 bg-black/60 shadow-[0_14px_36px_rgba(136,32,82,0.45)]">
            <img src={brandIcon} alt="QSpot icon" className="h-7 w-7 object-contain" />
          </div>
          <div className="flex items-start justify-between gap-6 pl-16 sm:pl-18">
            <div>
              <p className="text-xs font-semibold uppercase tracking-[0.24em] text-[#f3c5a0]/70">Update</p>
              <h3 className="mt-2 text-xl sm:text-2xl font-semibold tracking-wide text-white">Edit Speaker</h3>
              <p className="mt-2 text-sm text-white/70">
                Modify speaker details or upload a new image.
              </p>
            </div>
            <span className="mt-2 inline-flex h-2 w-2 shrink-0 rounded-full bg-gradient-to-r from-[#701845] to-[#EFB078]" />
          </div>
          <form onSubmit={handleSubmit} className="mt-8 space-y-5">
            <div>
              <label className="text-xs font-semibold uppercase tracking-[0.18em] text-white/65">Name *</label>
              <input
                type="text"
                value={formData.name}
                onChange={(e) => setFormData({...formData, name: e.target.value})}
                className="mt-2 block w-full rounded-2xl border border-white/10 bg-white/5 px-4 py-3 text-sm text-white placeholder-white/40 backdrop-blur-sm transition-all duration-200 focus:border-[#EFB078]/60 focus:outline-none focus:ring-0"
                placeholder="Enter speaker name"
                required
              />
            </div>
            <div>
              <label className="text-xs font-semibold uppercase tracking-[0.18em] text-white/65">Designation</label>
              <input
                type="text"
                value={formData.designation}
                onChange={(e) => setFormData({...formData, designation: e.target.value})}
                className="mt-2 block w-full rounded-2xl border border-white/10 bg-white/5 px-4 py-3 text-sm text-white placeholder-white/40 backdrop-blur-sm transition-all duration-200 focus:border-[#EFB078]/60 focus:outline-none focus:ring-0"
                placeholder="Enter designation"
              />
            </div>
            <div>
              <label className="text-xs font-semibold uppercase tracking-[0.18em] text-white/65">Order (number)</label>
              <input
                type="number"
                inputMode="numeric"
                value={formData.order}
                onChange={(e) => setFormData({ ...formData, order: e.target.value })}
                className="mt-2 block w-full rounded-2xl border border-white/10 bg-white/5 px-4 py-3 text-sm text-white placeholder-white/40 backdrop-blur-sm transition-all duration-200 focus:border-[#EFB078]/60 focus:outline-none focus:ring-0"
                placeholder="e.g., 1"
                min="0"
              />
            </div>
            <div>
              <label className="text-xs font-semibold uppercase tracking-[0.18em] text-white/65">New Image (optional)</label>
              <input
                type="file"
                accept="image/*"
                onChange={handleImageChange}
                className="mt-2 block w-full rounded-2xl border border-white/10 bg-white/5 px-4 py-3 text-sm text-white backdrop-blur-sm transition-all duration-200 focus:border-[#EFB078]/60 focus:outline-none focus:ring-0 file:mr-4 file:rounded-xl file:border-0 file:bg-gradient-to-r file:from-[#701845]/80 file:to-[#EFB078]/70 file:px-4 file:py-2 file:text-xs file:font-semibold file:uppercase file:tracking-wide file:text-white hover:file:from-[#5a1538] hover:file:to-[#d49a6a]"
              />
              <p className="mt-2 text-xs text-white/50">Leave empty to keep current image</p>
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
                {loading ? 'Updating...' : 'Update Speaker'}
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
};

export default SpeakersPage;
