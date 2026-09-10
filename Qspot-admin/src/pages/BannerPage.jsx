import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { FiEdit2, FiTrash2, FiPlus, FiChevronLeft, FiChevronRight, FiImage, FiCalendar } from 'react-icons/fi';
import Sidebar from '../components/Sidebar';
import ConfirmDialog from '../components/dialogs/ConfirmDialog';
import brandIcon from '../assets/Icon.png';

const BannerPage = () => {
  const [banners, setBanners] = useState([]);
  const [filteredBanners, setFilteredBanners] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [showEditModal, setShowEditModal] = useState(false);
  const [editingBanner, setEditingBanner] = useState(null);
  const [deleteConfirm, setDeleteConfirm] = useState(null);
  
  // Pagination and search states
  const [currentPage, setCurrentPage] = useState(1);
  const itemsPerPage = 10;

  useEffect(() => {
    fetchBanners();
  }, []);

  // Sort banners by newest first
  useEffect(() => {
    const sorted = [...banners].sort((a, b) => {
      const dateA = new Date(a.createdAt || 0);
      const dateB = new Date(b.createdAt || 0);
      return dateB - dateA;
    });
    setFilteredBanners(sorted);
    setCurrentPage(1);
  }, [banners]);

  const fetchBanners = async () => {
    try {
      setLoading(true);
      const baseURL = import.meta.env.VITE_API_BASE_URL;
      const response = await axios.get(`${baseURL}/banner`);
      setBanners(response.data || []);
    } catch (err) {
      console.error('Error fetching banners:', err);
      setError('Failed to fetch banners');
    } finally {
      setLoading(false);
    }
  };

  const handleCreateBanner = async (formData) => {
    try {
      const token = localStorage.getItem('adminToken');
      const baseURL = import.meta.env.VITE_API_BASE_URL;
      
      const formDataToSend = new FormData();
      formDataToSend.append('image', formData.image);
      
      await axios.post(`${baseURL}/banner`, formDataToSend, {
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'multipart/form-data'
        }
      });
      
      setShowCreateModal(false);
      fetchBanners();
    } catch (err) {
      console.error('Error creating banner:', err);
      alert('Failed to create banner');
    }
  };

  const handleEditBanner = (banner) => {
    setEditingBanner(banner);
    setShowEditModal(true);
  };

  const handleUpdateBanner = async (formData) => {
    try {
      const token = localStorage.getItem('adminToken');
      const baseURL = import.meta.env.VITE_API_BASE_URL;
      
      const formDataToSend = new FormData();
      if (formData.image) {
        formDataToSend.append('image', formData.image);
      }
      
      await axios.put(`${baseURL}/banner/${editingBanner._id}`, formDataToSend, {
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'multipart/form-data'
        }
      });
      
      setShowEditModal(false);
      setEditingBanner(null);
      fetchBanners();
    } catch (err) {
      console.error('Error updating banner:', err);
      alert('Failed to update banner');
    }
  };

  const handleDeleteBanner = async (bannerId) => {
    try {
      const token = localStorage.getItem('adminToken');
      const baseURL = import.meta.env.VITE_API_BASE_URL;
      
      await axios.delete(`${baseURL}/banner/${bannerId}`, {
        headers: {
          'Authorization': `Bearer ${token}`
        }
      });
      
      setDeleteConfirm(null);
      fetchBanners();
    } catch (err) {
      console.error('Error deleting banner:', err);
      alert('Failed to delete banner');
    }
  };

  const handleNavigate = (path) => {
    window.location.href = path;
  };

  // Pagination logic
  const totalPages = Math.ceil(filteredBanners.length / itemsPerPage);
  const startIndex = (currentPage - 1) * itemsPerPage;
  const endIndex = startIndex + itemsPerPage;
  const currentBanners = filteredBanners.slice(startIndex, endIndex);

  const handlePageChange = (page) => {
    setCurrentPage(page);
  };

  // Statistics
  const totalBanners = banners.length;
  const recentBanners = banners.filter(b => {
    const bannerDate = new Date(b.createdAt);
    const weekAgo = new Date();
    weekAgo.setDate(weekAgo.getDate() - 7);
    return bannerDate > weekAgo;
  }).length;

  return (
    <div className="flex min-h-screen bg-black">
      <Sidebar currentPage="banner" onNavigate={handleNavigate} />
      
      <div className="flex-1 flex flex-col ml-64">
        <main className="flex-1 p-4">
          {/* Header Section */}
          <div className="mb-8">
            <div className="flex flex-col lg:flex-row lg:items-center lg:justify-between gap-4">
              <div>
                <h2 className="text-2xl font-semibold text-white">Banner Management</h2>
                <p className="text-sm text-gray-400">Manage website banners and promotional images</p>
              </div>
              <button
                onClick={() => setShowCreateModal(true)}
                className="inline-flex items-center gap-2 self-start rounded-2xl bg-gradient-to-r from-[#701845]/90 via-[#9E4B63]/80 to-[#EFB078]/85 px-4 py-2.5 text-sm font-semibold text-white shadow-[0_8px_20px_rgba(112,24,69,0.3)] transition-all hover:from-[#5a1538] hover:to-[#d49a6a]"
              >
                <FiPlus size={14} />
                <span>Add Banner</span>
              </button>
            </div>

            <div className="mt-4">
              <p className="text-xs uppercase tracking-[0.24em] text-white/45">
                {totalBanners} Total · {recentBanners} Added This Week
              </p>
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
                onClick={fetchBanners}
                className="ml-4 text-red-300 underline hover:text-red-200"
              >
                Retry
              </button>
            </div>
          ) : (
            <div className="space-y-3">
              {filteredBanners.length === 0 ? (
                <div className="text-center py-8">
                  <FiImage className="mx-auto text-gray-500 mb-3" size={36} />
                  <p className="text-gray-400">
                    No banners found
                  </p>
                </div>
              ) : (
                <>
                  <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
                    {currentBanners.map((banner) => (
                      <article
                        key={banner._id}
                        className="group relative flex flex-col gap-3 rounded-2xl border border-white/12 bg-gradient-to-br from-[#120714]/85 via-[#1c0b1c]/70 to-[#0e050d]/85 p-4 shadow-[0_18px_46px_-26px_rgba(112,24,69,0.55)] transition-all duration-200 hover:-translate-y-1 hover:border-[#701845]/45 hover:shadow-[0_26px_60px_-28px_rgba(112,24,69,0.65)]"
                      >
                        <div className="relative h-32 overflow-hidden rounded-xl border border-white/10 bg-black/40">
                          <img
                            src={banner.image}
                            alt="Banner"
                            className="h-full w-full object-cover transition-transform duration-300 group-hover:scale-[1.03]"
                            onError={(e) => {
                              e.target.src =
                                'data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMjQiIGhlaWdodD0iMjQiIHZpZXdCb3g9IjAgMCAyNCAyNCIgZmlsbD0ibm9uZSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KPHJlY3Qgd2lkdGg9IjI0IiBoZWlnaHQ9IjI0IiBmaWxsPSIjMzc0MTUxIi8+CjxwYXRoIGQ9Ik0xMiA2VjE4TTYgMTJIMTgiIHN0cm9rZT0iIzlDQTNBRiIgc3Ryb2tlLXdpZHRoPSIyIiBzdHJva2UtbGluZWNhcD0icm91bmQiLz4KPC9zdmc+';
                            }}
                          />
                        </div>
                        <div className="flex flex-1 flex-col gap-2">
                          <h3 className="text-sm font-semibold text-white leading-snug">
                            Banner
                          </h3>
                          <div className="rounded-xl border border-white/10 bg-white/5 p-2 text-[11px] text-white/75">
                            <span className="font-medium text-white/85">Image URL</span>
                            <p className="mt-1 truncate text-white/65">{banner.image}</p>
                          </div>
                          <div className="mt-auto flex items-center justify-between text-[11px] text-white/60">
                            <span className="inline-flex items-center gap-1">
                              <FiCalendar size={11} className="text-[#EFB078]" />
                              {banner.createdAt
                                ? new Date(banner.createdAt).toLocaleDateString(undefined, {
                                    month: 'short',
                                    day: 'numeric',
                                    year: 'numeric',
                                  })
                                : 'Unknown date'}
                            </span>
                            <div className="flex gap-1.5">
                              <button
                                onClick={() => handleEditBanner(banner)}
                                className="flex h-8 w-8 items-center justify-center rounded-xl border border-white/15 bg-white/5 text-white/75 transition-all hover:border-[#EFB078]/40 hover:text-white"
                                title="Edit banner"
                                aria-label="Edit banner"
                              >
                                <FiEdit2 size={12} />
                              </button>
                              <button
                                onClick={() => setDeleteConfirm(banner)}
                                className="flex h-8 w-8 items-center justify-center rounded-xl border border-white/15 bg-white/5 text-white/75 transition-all hover:border-red-400/60 hover:text-red-200"
                                title="Delete banner"
                                aria-label="Delete banner"
                              >
                                <FiTrash2 size={12} />
                              </button>
                            </div>
                          </div>
                        </div>
                      </article>
                    ))}
                  </div>

                  {/* Pagination */}
                  {totalPages > 1 && (
                    <div className="relative overflow-hidden rounded-2xl border border-white/10 bg-gradient-to-br from-[#11060d]/60 via-[#1c0b18]/40 to-[#12060f]/60 backdrop-blur-xl p-4 mt-4">
                      <div className="flex items-center justify-between">
                        <div className="text-xs text-gray-400">
                          Showing {startIndex + 1} to {Math.min(endIndex, filteredBanners.length)} of {filteredBanners.length} banners
                        </div>
                        <div className="flex items-center space-x-1">
                          <button
                            onClick={() => handlePageChange(currentPage - 1)}
                            disabled={currentPage === 1}
                            className="flex h-8 w-8 items-center justify-center rounded-xl border border-white/10 bg-white/5 text-white/60 transition-all hover:border-[#EFB078]/40 hover:text-white disabled:opacity-40 disabled:cursor-not-allowed"
                          >
                            <FiChevronLeft size={14} />
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
                                  className={`px-2.5 py-1.5 rounded-xl text-xs font-semibold tracking-[0.16em] transition-all ${
                                    currentPage === page
                                      ? 'bg-gradient-to-r from-[#701845]/85 via-[#9E4B63]/75 to-[#EFB078]/70 text-white shadow-[0_8px_24px_rgba(112,24,69,0.35)]'
                                      : 'border border-white/10 bg-white/5 text-white/70 hover:border-[#EFB078]/40 hover:text-white'
                                  }`}
                                >
                                  {page}
                                </button>
                              );
                            } else if (
                              page === currentPage - 2 ||
                              page === currentPage + 2
                            ) {
                              return <span key={page} className="text-gray-500 text-xs">...</span>;
                            }
                            return null;
                          })}
                          
                          <button
                            onClick={() => handlePageChange(currentPage + 1)}
                            disabled={currentPage === totalPages}
                            className="flex h-8 w-8 items-center justify-center rounded-xl border border-white/10 bg-white/5 text-white/60 transition-all hover:border-[#EFB078]/40 hover:text-white disabled:opacity-40 disabled:cursor-not-allowed"
                          >
                            <FiChevronRight size={14} />
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

      {/* Create Banner Modal */}
      {showCreateModal && (
        <CreateBannerModal
          onClose={() => setShowCreateModal(false)}
          onSave={handleCreateBanner}
        />
      )}

      {/* Edit Banner Modal */}
      {showEditModal && editingBanner && (
        <EditBannerModal
          banner={editingBanner}
          onClose={() => {
            setShowEditModal(false);
            setEditingBanner(null);
          }}
          onSave={handleUpdateBanner}
        />
      )}

      {/* Delete Confirmation Modal */}
      {deleteConfirm && (
        <ConfirmDialog
          title="Delete Banner"
          description="Are you sure you want to delete this banner? This action cannot be undone."
          confirmLabel="Delete"
          cancelLabel="Cancel"
          confirmVariant="danger"
          onCancel={() => setDeleteConfirm(null)}
          onConfirm={() => handleDeleteBanner(deleteConfirm._id)}
        />
      )}
    </div>
  );
};

// Create Banner Modal Component
const CreateBannerModal = ({ onClose, onSave }) => {
  const [formData, setFormData] = useState({
    image: null
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

  const handleImageChange = (e) => {
    const file = e.target.files[0];
    if (file) {
      setFormData({ ...formData, image: file });
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
              Banner
            </p>
            <h3 className="text-xl font-semibold tracking-wide text-white">Add New Banner</h3>
            <p className="text-xs text-white/70">
              Upload a banner image to highlight content.
            </p>
          </div>

          <form onSubmit={handleSubmit} className="mt-6 space-y-4.5">
            <div>
              <label className="text-[11px] font-semibold uppercase tracking-[0.2em] text-white/65">
                Banner Image *
              </label>
              <input
                type="file"
                accept="image/*"
                onChange={handleImageChange}
                className="mt-2 block w-full rounded-2xl border border-white/10 bg-white/5 px-3.5 py-2.5 text-[13px] text-white placeholder-white/40 backdrop-blur-sm transition-all duration-200 focus:border-[#EFB078]/60 focus:outline-none focus:ring-0"
                required
              />
              <p className="mt-1 text-[10px] text-white/60">Recommended size: 1200x400px</p>
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
                {loading ? 'Creating...' : 'Create Banner'}
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
};

// Edit Banner Modal Component
const EditBannerModal = ({ banner, onClose, onSave }) => {
  const [formData, setFormData] = useState({
    image: null
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

  const handleImageChange = (e) => {
    const file = e.target.files[0];
    if (file) {
      setFormData({ ...formData, image: file });
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
              Banner
            </p>
            <h3 className="text-xl font-semibold tracking-wide text-white">Edit Banner</h3>
            <p className="text-xs text-white/70">
              Update the banner image or keep the current one.
            </p>
          </div>

          <form onSubmit={handleSubmit} className="mt-6 space-y-4.5">
            <div>
              <label className="text-[11px] font-semibold uppercase tracking-[0.2em] text-white/65">
                Current Image
              </label>
              <img
                src={banner.image}
                alt="Current banner"
                className="mt-2 h-32 w-full rounded-2xl border border-white/15 object-cover"
              />
            </div>
            <div>
              <label className="text-[11px] font-semibold uppercase tracking-[0.2em] text-white/65">
                New Image (optional)
              </label>
              <input
                type="file"
                accept="image/*"
                onChange={handleImageChange}
                className="mt-2 block w-full rounded-2xl border border-white/10 bg-white/5 px-3.5 py-2.5 text-[13px] text-white placeholder-white/40 backdrop-blur-sm transition-all duration-200 focus:border-[#EFB078]/60 focus:outline-none focus:ring-0"
              />
              <p className="mt-1 text-[10px] text-white/60">Leave empty to keep current image</p>
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
                {loading ? 'Updating...' : 'Update Banner'}
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
};

export default BannerPage;
