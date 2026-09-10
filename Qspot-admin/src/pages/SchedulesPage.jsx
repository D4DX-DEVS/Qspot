import React, { useState, useEffect, useMemo, useRef } from 'react';
import axios from 'axios';
import { FiEdit2, FiTrash2, FiPlus, FiSearch, FiChevronLeft, FiChevronRight, FiCalendar, FiClock, FiUser, FiChevronDown } from 'react-icons/fi';
import Sidebar from '../components/Sidebar';
import ConfirmDialog from '../components/dialogs/ConfirmDialog';
import brandIcon from '../assets/Icon.png';

const SchedulesPage = () => {
  const [schedules, setSchedules] = useState([]);
  const [filteredSchedules, setFilteredSchedules] = useState([]);
  const [speakers, setSpeakers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [showEditModal, setShowEditModal] = useState(false);
  const [editingSchedule, setEditingSchedule] = useState(null);
  const [deleteConfirm, setDeleteConfirm] = useState(null);
  
  // Pagination and search states
  const [currentPage, setCurrentPage] = useState(1);
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [facultyFilter, setFacultyFilter] = useState('');
  const itemsPerPage = 10;

  useEffect(() => {
    fetchSchedules();
    fetchSpeakers();
  }, []);

  // Filter and sort schedules based on search term, class filter, and sort options
  useEffect(() => {
    let filtered = [...schedules];

    // Apply search filter
    if (searchTerm) {
      filtered = filtered.filter(schedule => 
        schedule.title?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        schedule.class?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        schedule.faculty?.name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        schedule.faculty?.designation?.toLowerCase().includes(searchTerm.toLowerCase())
      );
    }

    if (facultyFilter) {
      filtered = filtered.filter(schedule => schedule.faculty?._id === facultyFilter);
    }

    if (statusFilter !== 'all') {
      const referenceDate = new Date();
      filtered = filtered.filter(schedule => {
        const scheduleDate = schedule.scheduleDate ? new Date(schedule.scheduleDate) : null;
        if (!scheduleDate || Number.isNaN(scheduleDate.getTime())) return false;
        const isUpcoming = scheduleDate > referenceDate;
        return statusFilter === 'upcoming' ? isUpcoming : !isUpcoming;
      });
    }

    filtered.sort((a, b) => {
      const dateA = a.scheduleDate ? new Date(a.scheduleDate) : null;
      const dateB = b.scheduleDate ? new Date(b.scheduleDate) : null;
      const timeA = dateA && !Number.isNaN(dateA.getTime()) ? dateA.getTime() : 0;
      const timeB = dateB && !Number.isNaN(dateB.getTime()) ? dateB.getTime() : 0;
      return timeA - timeB;
    });

    setFilteredSchedules(filtered);
    setCurrentPage(1);
  }, [schedules, searchTerm, facultyFilter, statusFilter]);

  const fetchSchedules = async () => {
    try {
      setLoading(true);
      const baseURL = import.meta.env.VITE_API_BASE_URL;
      const response = await axios.get(`${baseURL}/schedules`);
      setSchedules(response.data || []);
    } catch (err) {
      console.error('Error fetching schedules:', err);
      setError('Failed to fetch schedules');
    } finally {
      setLoading(false);
    }
  };

  const fetchSpeakers = async () => {
    try {
      const baseURL = import.meta.env.VITE_API_BASE_URL;
      const response = await axios.get(`${baseURL}/speakers`);
      setSpeakers(response.data || []);
    } catch (err) {
      console.error('Error fetching speakers:', err);
    }
  };

  const handleCreateSchedule = async (formData) => {
    try {
      const token = localStorage.getItem('adminToken');
      const baseURL = import.meta.env.VITE_API_BASE_URL;
      
      await axios.post(`${baseURL}/schedules`, formData, {
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json'
        }
      });
      
      setShowCreateModal(false);
      fetchSchedules();
    } catch (err) {
      console.error('Error creating schedule:', err);
      alert('Failed to create schedule');
    }
  };

  const handleEditSchedule = (schedule) => {
    setEditingSchedule(schedule);
    setShowEditModal(true);
  };

  const handleUpdateSchedule = async (formData) => {
    try {
      const token = localStorage.getItem('adminToken');
      const baseURL = import.meta.env.VITE_API_BASE_URL;
      
      await axios.put(`${baseURL}/schedules/${editingSchedule._id}`, formData, {
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json'
        }
      });
      
      setShowEditModal(false);
      setEditingSchedule(null);
      fetchSchedules();
    } catch (err) {
      console.error('Error updating schedule:', err);
      alert('Failed to update schedule');
    }
  };

  const handleDeleteSchedule = async (scheduleId) => {
    try {
      const token = localStorage.getItem('adminToken');
      const baseURL = import.meta.env.VITE_API_BASE_URL;
      
      await axios.delete(`${baseURL}/schedules/${scheduleId}`, {
        headers: {
          'Authorization': `Bearer ${token}`
        }
      });
      
      setDeleteConfirm(null);
      fetchSchedules();
    } catch (err) {
      console.error('Error deleting schedule:', err);
      alert('Failed to delete schedule');
    }
  };

  const handleNavigate = (path) => {
    window.location.href = path;
  };

  // Pagination logic
  const totalPages = Math.ceil(filteredSchedules.length / itemsPerPage);
  const startIndex = (currentPage - 1) * itemsPerPage;
  const endIndex = startIndex + itemsPerPage;
  const currentSchedules = filteredSchedules.slice(startIndex, endIndex);

  const handlePageChange = (page) => {
    setCurrentPage(page);
  };

  // Statistics
  const totalSchedules = schedules.length;
  const upcomingSchedules = schedules.filter(s => new Date(s.scheduleDate) > new Date()).length;
  const pastSchedules = schedules.filter(s => new Date(s.scheduleDate) <= new Date()).length;
  const statusOptions = [
    { value: 'all', label: 'All', count: totalSchedules },
    { value: 'upcoming', label: 'Upcoming', count: upcomingSchedules },
    { value: 'completed', label: 'Completed', count: pastSchedules },
  ];

  return (
    <div className="flex min-h-screen bg-black">
      <Sidebar currentPage="schedules" onNavigate={handleNavigate} />
      
      <div className="flex-1 flex flex-col ml-64">
        <main className="flex-1 p-4">
          {/* Header Section */}
          <div className="mb-4">
            <div className="flex flex-col lg:flex-row lg:items-center lg:justify-between gap-4">
              <div>
                <h2 className="text-2xl font-bold text-white mb-1">Schedules Management</h2>
                <p className="text-gray-400 text-sm">Manage class schedules and timetables</p>
              </div>
              
              {/* Statistics Cards */}
              <div className="flex gap-3">
                <div className="relative overflow-hidden rounded-2xl border border-white/10 bg-gradient-to-br from-[#11060d]/80 via-[#1c0b18]/60 to-[#12060f]/80 px-4 py-3 shadow-[0_8px_32px_rgba(112,24,69,0.25)] backdrop-blur-xl min-w-[120px]">
                  <div className="flex items-center gap-2">
                    <FiCalendar className="text-[#EFB078]" size={16} />
                    <div>
                      <p className="text-lg font-bold text-white">{totalSchedules}</p>
                      <p className="text-xs text-gray-400">Total</p>
                    </div>
                  </div>
                </div>
                <div className="relative overflow-hidden rounded-2xl border border-white/10 bg-gradient-to-br from-[#11060d]/80 via-[#1c0b18]/60 to-[#12060f]/80 px-4 py-3 shadow-[0_8px_32px_rgba(112,24,69,0.25)] backdrop-blur-xl min-w-[120px]">
                  <div className="flex items-center gap-2">
                    <FiClock className="text-[#EFB078]" size={16} />
                    <div>
                      <p className="text-lg font-bold text-white">{upcomingSchedules}</p>
                      <p className="text-xs text-gray-400">Upcoming</p>
                    </div>
                  </div>
                </div>
                <div className="relative overflow-hidden rounded-2xl border border-white/10 bg-gradient-to-br from-[#11060d]/80 via-[#1c0b18]/60 to-[#12060f]/80 px-4 py-3 shadow-[0_8px_32px_rgba(112,24,69,0.25)] backdrop-blur-xl min-w-[120px]">
                  <div className="flex items-center gap-2">
                    <FiUser className="text-[#EFB078]" size={16} />
                    <div>
                      <p className="text-lg font-bold text-white">{pastSchedules}</p>
                      <p className="text-xs text-gray-400">Completed</p>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            {/* Search and Filter Section */}
            <div className="mt-4 flex flex-col gap-3 lg:flex-row lg:items-center lg:justify-between">
              <div className="relative w-full lg:max-w-xl">
                <FiSearch className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" size={16} />
                <input
                  type="text"
                  placeholder="Search schedules by title, class, or faculty..."
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  className="w-full rounded-2xl border border-white/10 bg-gradient-to-br from-[#11060d]/60 via-[#1c0b18]/40 to-[#12060f]/60 py-3 pl-9 pr-4 text-sm text-white placeholder-slate-400 backdrop-blur-xl transition-all focus:outline-none focus:border-[#701845]/50 focus:ring-2 focus:ring-[#701845]/30"
                />
              </div>

              <div className="flex w-full flex-col gap-2 lg:w-auto lg:flex-row lg:items-center lg:gap-3">
                <div className="flex items-center gap-1 rounded-2xl border border-white/10 bg-gradient-to-br from-[#11060d]/60 via-[#1c0b18]/40 to-[#12060f]/60 p-1.5 backdrop-blur-xl overflow-hidden">
                  {statusOptions.map((option) => {
                    const isActive = statusFilter === option.value;
                    return (
                      <button
                        key={option.value}
                        onClick={() => setStatusFilter(option.value)}
                        className={`flex items-center gap-1.5 rounded-2xl px-3 py-1.5 text-xs font-semibold uppercase tracking-[0.14em] transition-all ${
                          isActive
                            ? 'bg-gradient-to-r from-[#701845]/80 via-[#9E4B63]/70 to-[#EFB078]/70 text-white shadow-[0_10px_26px_rgba(112,24,69,0.35)]'
                            : 'text-white/55 hover:text-white'
                        }`}
                        type="button"
                      >
                        <span>{option.label}</span>
                        <span className="text-[10px] font-semibold text-white/50">{option.count}</span>
                      </button>
                    );
                  })}
                </div>

                <div className="w-full sm:w-60">
                  <FacultySelect
                    speakers={speakers}
                    value={facultyFilter}
                    onChange={(value) => setFacultyFilter(value)}
                    placeholder="All Faculties"
                    includeAllOption
                    allLabel="All Faculties"
                  />
                </div>

                <button
                  onClick={() => setShowCreateModal(true)}
                  className="inline-flex items-center gap-2 rounded-2xl bg-gradient-to-r from-[#701845]/90 via-[#9E4B63]/80 to-[#EFB078]/85 px-4 py-2.5 text-sm font-semibold text-white shadow-[0_8px_20px_rgba(112,24,69,0.3)] transition-all hover:from-[#5a1538] hover:to-[#d49a6a]"
                  type="button"
                >
                  <FiPlus size={14} />
                  <span>Add</span>
                </button>
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
                onClick={fetchSchedules}
                className="ml-4 text-red-300 underline hover:text-red-200"
              >
                Retry
              </button>
            </div>
          ) : (
            <div className="space-y-3">
              {filteredSchedules.length === 0 ? (
                <div className="text-center py-8">
                  <FiCalendar className="mx-auto text-gray-500 mb-3" size={36} />
                  <p className="text-gray-400">
                    {searchTerm || facultyFilter || statusFilter !== 'all' ? 'No schedules found matching your criteria' : 'No schedules found'}
                  </p>
                  {(searchTerm || facultyFilter || statusFilter !== 'all') && (
                    <button
                      onClick={() => {
                        setSearchTerm('');
                        setFacultyFilter('');
                        setStatusFilter('all');
                      }}
                      className="mt-2 text-indigo-400 hover:text-indigo-300 transition-colors text-sm"
                    >
                      Clear filters
                    </button>
                  )}
                </div>
              ) : (
                <>
                  <div className="grid gap-y-2 gap-x-3 justify-items-center sm:grid-cols-2 xl:grid-cols-4">
                    {currentSchedules.map((schedule) => {
                      const scheduleDate = schedule.scheduleDate ? new Date(schedule.scheduleDate) : null;
                      const createdDate = schedule.createdAt ? new Date(schedule.createdAt) : null;
                      const isUpcoming = scheduleDate ? scheduleDate > new Date() : false;
                      const formattedDate = scheduleDate
                        ? scheduleDate.toLocaleDateString(undefined, {
                            weekday: 'short',
                            month: 'short',
                            day: 'numeric',
                            year: 'numeric',
                          })
                        : 'No date';
                      const formattedTime = scheduleDate
                        ? scheduleDate.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
                        : 'No time';
                      const createdLabel = createdDate
                        ? createdDate.toLocaleDateString(undefined, { month: 'short', day: 'numeric', year: 'numeric' })
                        : 'Unknown date';
                      return (
                        <article
                          key={schedule._id}
                          className="mx-auto flex w-full max-w-xs flex-col gap-2.5 rounded-2xl border border-white/12 bg-gradient-to-br from-[#1a0913]/88 via-[#251026]/72 to-[#11040f]/85 p-2.5 shadow-[0_10px_28px_-24px_rgba(112,24,69,0.58)] transition-all duration-200 hover:border-[#EFB078]/45 hover:shadow-[0_16px_42px_-26px_rgba(239,176,120,0.45)]"
                        >
                          <header className="flex items-start justify-between gap-2">
                            <div className="space-y-2">
                              <h3 className="text-lg font-semibold text-white leading-snug line-clamp-2">{schedule.title}</h3>
                              <div className="flex flex-wrap items-center gap-1 text-[10px] text-white/70">
                                <span className="inline-flex items-center gap-1 rounded-full bg-white/5 px-2 py-[2px]">
                                  <FiCalendar size={10} className="text-indigo-300" />
                                  Class {schedule.class || 'N/A'}
                                </span>
                                <span className="inline-flex items-center gap-1 rounded-full bg-white/5 px-2 py-[2px]">
                                  <FiUser size={10} className="text-[#EFB078]" />
                                  {schedule.faculty?.name || 'Unknown Faculty'}
                                  {schedule.faculty?.designation && (
                                    <span className="ml-1 text-[9px] uppercase tracking-[0.12em] text-white/45">
                                      {schedule.faculty.designation}
                                    </span>
                                  )}
                                </span>
                              </div>
                            </div>
                            <span
                              className={`inline-flex items-center gap-1 rounded-full px-2 py-[2px] text-[9px] font-semibold uppercase tracking-[0.18em] ${
                                isUpcoming
                                  ? 'bg-emerald-500/20 text-emerald-200'
                                  : 'bg-slate-600/25 text-slate-200'
                              }`}
                            >
                              {isUpcoming ? <FiClock size={10} /> : <FiCalendar size={10} />}
                              {isUpcoming ? 'Upcoming' : 'Completed'}
                            </span>
                          </header>

                          <section className="space-y-1.5 text-[11px] text-white/80">
                            <div className="flex items-center gap-2">
                              <div className="flex h-6 w-6 items-center justify-center rounded-md bg-indigo-900/40 text-indigo-200/90">
                                <FiCalendar size={12} />
                              </div>
                              <div>
                                <p className="text-[9px] uppercase tracking-[0.16em] text-white/45">Date</p>
                                <p className="text-sm font-medium text-white">{formattedDate}</p>
                              </div>
                            </div>
                            <div className="flex items-center gap-2">
                              <div className="flex h-6 w-6 items-center justify-center rounded-md bg-[#701845]/35 text-[#EFB078]">
                                <FiClock size={12} />
                              </div>
                              <div>
                                <p className="text-[9px] uppercase tracking-[0.16em] text-white/45">Time</p>
                                <p className="text-sm font-medium text-white">{formattedTime}</p>
                              </div>
                            </div>
                          </section>

                          <footer className="mt-auto flex items-center justify-between gap-1 text-[9px] text-white/55">
                            <span className="inline-flex items-center gap-1">
                              <FiCalendar size={9} />
                              Created {createdLabel}
                            </span>
                            <div className="flex items-center gap-1.5">
                              <button
                                onClick={() => handleEditSchedule(schedule)}
                                className="flex h-8 w-8 items-center justify-center rounded-xl border border-white/15 bg-white/5 text-white/70 transition-colors hover:border-[#EFB078]/45 hover:text-white"
                                title="Edit schedule"
                                aria-label="Edit schedule"
                              >
                                <FiEdit2 size={12} />
                              </button>
                              <button
                                onClick={() => setDeleteConfirm(schedule)}
                                className="flex h-8 w-8 items-center justify-center rounded-xl border border-red-500/35 bg-red-500/15 text-red-200 transition-colors hover:border-red-400/60 hover:bg-red-500/25 hover:text-white"
                                title="Delete schedule"
                                aria-label="Delete schedule"
                              >
                                <FiTrash2 size={12} />
                              </button>
                            </div>
                          </footer>
                        </article>
                      );
                    })}
                  </div>

                  {/* Pagination */}
                  {totalPages > 1 && (
                    <div className="relative overflow-hidden rounded-2xl border border-white/10 bg-gradient-to-br from-[#11060d]/60 via-[#1c0b18]/40 to-[#12060f]/60 backdrop-blur-xl p-4 mt-4">
                      <div className="flex items-center justify-between">
                        <div className="text-xs text-gray-400">
                          Showing {startIndex + 1} to {Math.min(endIndex, filteredSchedules.length)} of {filteredSchedules.length} schedules
                        </div>
                        <div className="flex items-center space-x-1">
                          <button
                            onClick={() => handlePageChange(currentPage - 1)}
                            disabled={currentPage === 1}
                            className="p-1.5 rounded-lg bg-gray-700 text-gray-300 hover:bg-gray-600 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
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
                                  className={`px-2 py-1.5 rounded-lg text-xs font-medium transition-colors ${
                                    currentPage === page
                                      ? 'bg-indigo-600 text-white'
                                      : 'bg-gray-700 text-gray-300 hover:bg-gray-600'
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
                            className="p-1.5 rounded-lg bg-gray-700 text-gray-300 hover:bg-gray-600 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
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

      {/* Create Schedule Modal */}
      {showCreateModal && (
        <CreateScheduleModal
          speakers={speakers}
          onClose={() => setShowCreateModal(false)}
          onSave={handleCreateSchedule}
        />
      )}

      {/* Edit Schedule Modal */}
      {showEditModal && editingSchedule && (
        <EditScheduleModal
          schedule={editingSchedule}
          speakers={speakers}
          onClose={() => {
            setShowEditModal(false);
            setEditingSchedule(null);
          }}
          onSave={handleUpdateSchedule}
        />
      )}

      {/* Delete Confirmation Modal */}
      {deleteConfirm && (
        <ConfirmDialog
          title="Delete Schedule"
          description={`Are you sure you want to delete "${deleteConfirm.title}"? This action cannot be undone.`}
          confirmLabel="Delete"
          cancelLabel="Cancel"
          confirmVariant="danger"
          onCancel={() => setDeleteConfirm(null)}
          onConfirm={() => handleDeleteSchedule(deleteConfirm._id)}
        />
      )}
    </div>
  );
};

// Create Schedule Modal Component
const CreateScheduleModal = ({ speakers, onClose, onSave }) => {
  const [formData, setFormData] = useState({
    title: '',
    class: '',
    scheduleDate: '',
    faculty: ''
  });
  const [loading, setLoading] = useState(false);
  const [dateValue, setDateValue] = useState('');
  const [timeValue, setTimeValue] = useState('');

  useEffect(() => {
    setFormData((prev) => {
      const nextValue =
        dateValue && timeValue ? combineDateTimeParts(dateValue, timeValue) : '';
      if (prev.scheduleDate === nextValue) return prev;
      return { ...prev, scheduleDate: nextValue };
    });
  }, [dateValue, timeValue]);

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (
      !formData.title.trim() ||
      !formData.class.trim() ||
      !formData.scheduleDate ||
      !formData.faculty
    ) {
      alert('Please fill in all required fields.');
      return;
    }
    setLoading(true);
    try {
      await onSave(formData);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    const previousOverflow = document.body.style.overflow;
    document.body.style.overflow = 'hidden';
    return () => {
      document.body.style.overflow = previousOverflow;
    };
  }, []);

  const inputClass =
    'mt-2 block w-full rounded-2xl border border-white/10 bg-white/5 px-4 py-3 text-sm text-white placeholder-white/40 backdrop-blur-sm transition-all duration-200 focus:border-[#EFB078]/60 focus:outline-none focus:ring-0';

  return (
    <div className="fixed inset-0 z-[120] flex h-full w-full items-center justify-center overflow-y-auto bg-black/70 px-4 py-10 backdrop-blur-md">
      <div className="relative w-full max-w-xl overflow-visible rounded-3xl border border-white/12 bg-gradient-to-br from-[#100713]/92 via-[#190d23]/85 to-[#10060f]/92 shadow-[0_28px_80px_-28px_rgba(12,6,20,0.92)]">
        <div
          className="pointer-events-none absolute inset-0 rounded-3xl bg-[radial-gradient(circle_at_top_right,rgba(136,32,82,0.55),transparent_65%)]"
          aria-hidden="true"
        />

        <div className="relative px-8 pt-9 pb-8">
          <div className="absolute left-8 top-6 flex h-12 w-12 items-center justify-center rounded-2xl border border-white/12 bg-black/60 shadow-[0_14px_36px_rgba(136,32,82,0.45)]">
            <img src={brandIcon} alt="QSpot icon" className="h-7 w-7 object-contain" />
          </div>

          <div className="flex flex-col gap-2 pl-20">
            <p className="text-xs font-semibold uppercase tracking-[0.24em] text-[#f3c5a0]/70">Schedule</p>
            <h3 className="text-2xl font-semibold tracking-wide text-white">Add New Schedule</h3>
            <p className="text-sm text-white/70">
              Fill in the schedule details and assign a faculty.
            </p>
          </div>

          <form onSubmit={handleSubmit} className="mt-8 space-y-5">
            <div>
              <label className="text-xs font-semibold uppercase tracking-[0.2em] text-white/65">Title *</label>
              <input
                type="text"
                value={formData.title}
                onChange={(e) => setFormData({ ...formData, title: e.target.value })}
                placeholder="Enter schedule title"
                className={inputClass}
                required
              />
            </div>

            <div>
              <label className="text-xs font-semibold uppercase tracking-[0.2em] text-white/65">Class *</label>
              <input
                type="text"
                value={formData.class}
                onChange={(e) => setFormData({ ...formData, class: e.target.value })}
                placeholder="Enter class"
                className={inputClass}
                required
              />
            </div>

            <div className="grid gap-4 sm:grid-cols-2">
              <div>
                <label className="text-xs font-semibold uppercase tracking-[0.2em] text-white/65">
                  Date *
                </label>
                <ScheduleDatePicker value={dateValue} onChange={setDateValue} />
              </div>
              <div>
                <label className="text-xs font-semibold uppercase tracking-[0.2em] text-white/65">
                  Time *
                </label>
                <ScheduleTimePicker value={timeValue} onChange={setTimeValue} />
              </div>
            </div>

            <div>
              <label className="text-xs font-semibold uppercase tracking-[0.2em] text-white/65">Faculty *</label>
              <FacultySelect
                speakers={speakers}
                value={formData.faculty}
                onChange={(value) => setFormData({ ...formData, faculty: value })}
              />
            </div>

            <div className="flex items-center justify-end gap-3 pt-4">
              <button
                type="button"
                onClick={onClose}
                className="rounded-lg border border-white/10 bg-white/5 px-5 py-2.5 text-xs font-semibold uppercase tracking-[0.18em] text-white/75 transition-all duration-200 hover:border-white/20 hover:bg-white/10 hover:text-white"
              >
                Cancel
              </button>
              <button
                type="submit"
                disabled={loading}
                className="rounded-lg bg-gradient-to-r from-[#701845]/90 via-[#9E4B63]/80 to-[#EFB078]/85 px-5 py-2.5 text-xs font-semibold uppercase tracking-[0.18em] text-white shadow-[0_16px_34px_rgba(136,32,82,0.45)] transition-all duration-200 hover:scale-[1.01] disabled:opacity-50 disabled:shadow-none"
              >
                {loading ? 'Creating...' : 'Create Schedule'}
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
};

// Edit Schedule Modal Component
const EditScheduleModal = ({ schedule, speakers, onClose, onSave }) => {
  const [formData, setFormData] = useState({
    title: schedule.title || '',
    class: schedule.class || '',
    scheduleDate: schedule.scheduleDate
      ? combineDateTimeParts(
          formatDatePart(schedule.scheduleDate),
          formatTimePart(schedule.scheduleDate),
        )
      : '',
    faculty: schedule.faculty?._id || ''
  });
  const [loading, setLoading] = useState(false);
  const [dateValue, setDateValue] = useState(() => formatDatePart(schedule.scheduleDate) || '');
  const [timeValue, setTimeValue] = useState(() => formatTimePart(schedule.scheduleDate) || '');

  useEffect(() => {
    setFormData((prev) => {
      const nextValue =
        dateValue && timeValue ? combineDateTimeParts(dateValue, timeValue) : '';
      if (prev.scheduleDate === nextValue) return prev;
      return { ...prev, scheduleDate: nextValue };
    });
  }, [dateValue, timeValue]);

  useEffect(() => {
    setFormData({
      title: schedule.title || '',
      class: schedule.class || '',
      scheduleDate: schedule.scheduleDate
        ? combineDateTimeParts(
            formatDatePart(schedule.scheduleDate),
            formatTimePart(schedule.scheduleDate),
          )
        : '',
      faculty: schedule.faculty?._id || ''
    });
    setDateValue(formatDatePart(schedule.scheduleDate) || '');
    setTimeValue(formatTimePart(schedule.scheduleDate) || '');
  }, [schedule]);
 
  const handleSubmit = async (e) => {
    e.preventDefault();
    if (
      !formData.title.trim() ||
      !formData.class.trim() ||
      !formData.scheduleDate ||
      !formData.faculty
    ) {
      alert('Please fill in all required fields.');
      return;
    }
    setLoading(true);
    try {
      await onSave(formData);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    const previousOverflow = document.body.style.overflow;
    document.body.style.overflow = 'hidden';
    return () => {
      document.body.style.overflow = previousOverflow;
    };
  }, []);

  const inputClass =
    'mt-2 block w-full rounded-2xl border border-white/10 bg-white/5 px-4 py-3 text-sm text-white placeholder-white/40 backdrop-blur-sm transition-all duration-200 focus:border-[#EFB078]/60 focus:outline-none focus:ring-0';

  return (
    <div className="fixed inset-0 z-[120] flex h-full w-full items-center justify-center overflow-y-auto bg-black/70 px-4 py-10 backdrop-blur-md">
      <div className="relative w-full max-w-xl overflow-visible rounded-3xl border border-white/12 bg-gradient-to-br from-[#100713]/92 via-[#190d23]/85 to-[#10060f]/92 shadow-[0_28px_80px_-28px_rgba(12,6,20,0.92)]">
        <div
          className="pointer-events-none absolute inset-0 rounded-3xl bg-[radial-gradient(circle_at_top_right,rgba(136,32,82,0.55),transparent_65%)]"
          aria-hidden="true"
        />

        <div className="relative px-8 pt-9 pb-8">
          <div className="absolute left-8 top-6 flex h-12 w-12 items-center justify-center rounded-2xl border border-white/12 bg-black/60 shadow-[0_14px_36px_rgba(136,32,82,0.45)]">
            <img src={brandIcon} alt="QSpot icon" className="h-7 w-7 object-contain" />
          </div>

          <div className="flex flex-col gap-2 pl-20">
            <p className="text-xs font-semibold uppercase tracking-[0.24em] text-[#f3c5a0]/70">Schedule</p>
            <h3 className="text-2xl font-semibold tracking-wide text-white">Edit Schedule</h3>
            <p className="text-sm text-white/70">
              Update schedule details and confirm the assigned faculty.
            </p>
          </div>

          <form onSubmit={handleSubmit} className="mt-8 space-y-5">
            <div>
              <label className="text-xs font-semibold uppercase tracking-[0.2em] text-white/65">Title *</label>
              <input
                type="text"
                value={formData.title}
                onChange={(e) => setFormData({ ...formData, title: e.target.value })}
                placeholder="Enter schedule title"
                className={inputClass}
                required
              />
            </div>

            <div>
              <label className="text-xs font-semibold uppercase tracking-[0.2em] text-white/65">Class *</label>
              <input
                type="text"
                value={formData.class}
                onChange={(e) => setFormData({ ...formData, class: e.target.value })}
                placeholder="Enter class name (e.g., 8, 9, 10, 11, 12)"
                className={inputClass}
                required
              />
            </div>

            <div className="grid gap-4 sm:grid-cols-2">
              <div>
                <label className="text-xs font-semibold uppercase tracking-[0.2em] text-white/65">
                  Date *
                </label>
                <ScheduleDatePicker value={dateValue} onChange={setDateValue} />
              </div>
              <div>
                <label className="text-xs font-semibold uppercase tracking-[0.2em] text-white/65">
                  Time *
                </label>
                <ScheduleTimePicker value={timeValue} onChange={setTimeValue} />
              </div>
            </div>

            <div>
              <label className="text-xs font-semibold uppercase tracking-[0.2em] text-white/65">Faculty *</label>
              <FacultySelect
                speakers={speakers}
                value={formData.faculty}
                onChange={(value) => setFormData({ ...formData, faculty: value })}
              />
            </div>

            <div className="flex items-center justify-end gap-3 pt-4">
              <button
                type="button"
                onClick={onClose}
                className="rounded-lg border border-white/10 bg-white/5 px-5 py-2.5 text-xs font-semibold uppercase tracking-[0.18em] text-white/75 transition-all duration-200 hover:border-white/20 hover:bg-white/10 hover:text-white"
              >
                Cancel
              </button>
              <button
                type="submit"
                disabled={loading}
                className="rounded-lg bg-gradient-to-r from-[#701845]/90 via-[#9E4B63]/80 to-[#EFB078]/85 px-5 py-2.5 text-xs font-semibold uppercase tracking-[0.18em] text-white shadow-[0_16px_34px_rgba(136,32,82,0.45)] transition-all duration-200 hover:scale-[1.01] disabled:opacity-50 disabled:shadow-none"
              >
                {loading ? 'Updating...' : 'Update Schedule'}
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
};

const ensureNoScrollbarStyle = () => {
  if (typeof document === 'undefined') return;
  const styleId = 'qspot-no-scrollbar-style';
  if (document.getElementById(styleId)) return;
  const style = document.createElement('style');
  style.id = styleId;
  style.innerHTML = `
    .qspot-no-scrollbar {
      scrollbar-width: none;
      -ms-overflow-style: none;
    }
    .qspot-no-scrollbar::-webkit-scrollbar {
      display: none;
      width: 0;
      height: 0;
    }
  `;
  document.head.appendChild(style);
};

const FacultySelect = ({ speakers, value, onChange, placeholder = 'Select a faculty', includeAllOption = false, allLabel = 'All Faculties' }) => {
  useEffect(() => {
    ensureNoScrollbarStyle();
  }, []);
  const [open, setOpen] = useState(false);
  const containerRef = useRef(null);

  useEffect(() => {
    const handleClickOutside = (event) => {
      if (containerRef.current && !containerRef.current.contains(event.target)) {
        setOpen(false);
      }
    };
    document.addEventListener('mousedown', handleClickOutside);
    document.addEventListener('touchstart', handleClickOutside);
    return () => {
      document.removeEventListener('mousedown', handleClickOutside);
      document.removeEventListener('touchstart', handleClickOutside);
    };
  }, []);

  const selectedOption = useMemo(
    () => (value ? speakers.find((speaker) => speaker._id === value) : undefined),
    [speakers, value],
  );

  return (
    <div ref={containerRef} className="relative">
      <button
        type="button"
        onClick={() => setOpen((prev) => !prev)}
        className="flex w-full items-center justify-between rounded-2xl border border-white/10 bg-white/5 px-3 py-2.5 text-left text-xs text-white backdrop-blur-sm transition-all duration-200 hover:border-[#EFB078]/40 focus:outline-none focus:ring-0"
      >
        <span className={selectedOption ? 'text-white' : 'text-white/50'}>
          {selectedOption
            ? `${selectedOption.name}${
                selectedOption.designation ? ` (${selectedOption.designation})` : ''
              }`
            : placeholder}
        </span>
        <FiChevronDown
          size={14}
          className={`ml-3 shrink-0 transition-transform ${open ? 'rotate-180 text-[#EFB078]' : 'text-white/60'}`}
        />
      </button>
      {open && (
        <div className="absolute left-0 top-full z-[180] mt-2 w-full min-w-[240px] max-w-[360px] overflow-hidden rounded-2xl border border-white/10 bg-gradient-to-br from-[#11060d]/95 via-[#1c0b18]/85 to-[#12060f]/95 shadow-[0_22px_60px_rgba(12,6,20,0.65)] backdrop-blur-xl">
          <ul className="max-h-60 overflow-y-auto pr-1 qspot-no-scrollbar">
            <li className="border-b border-white/10 bg-white/5 px-3 py-2 text-[10px] uppercase tracking-[0.2em] text-white/50">
              Faculty List
            </li>
            {includeAllOption && (
              <li>
                <button
                  type="button"
                  onClick={() => {
                    onChange('');
                    setOpen(false);
                  }}
                  className={`flex w-full items-center justify-between px-3 py-2 text-xs transition-all duration-150 ${
                    !value
                      ? 'bg-gradient-to-r from-[#701845]/70 to-[#EFB078]/35 text-white shadow-[0_10px_28px_rgba(112,24,69,0.35)]'
                      : 'text-white/80 hover:bg-white/10 hover:text-white'
                  }`}
                >
                  <span className="font-medium">{allLabel}</span>
                </button>
              </li>
            )}
            {speakers.length === 0 && (
              <li className="px-3 py-2 text-xs text-white/60">No faculties available</li>
            )}
            {speakers.map((speaker) => {
              const isSelected = speaker._id === value;
              return (
                <li key={speaker._id}>
                  <button
                    type="button"
                    onClick={() => {
                      onChange(speaker._id);
                      setOpen(false);
                    }}
                    className={`flex w-full items-start justify-between px-3 py-2 text-xs transition-all duration-150 ${
                      isSelected
                        ? 'bg-gradient-to-r from-[#701845]/70 to-[#EFB078]/35 text-white shadow-[0_10px_28px_rgba(112,24,69,0.35)]'
                        : 'text-white/80 hover:bg-white/10 hover:text-white'
                    }`}
                  >
                    <span className="flex flex-col text-left">
                      <span className="font-medium">{speaker.name}</span>
                      {speaker.designation && (
                        <span className="text-[10px] text-white/60">{speaker.designation}</span>
                      )}
                    </span>
                    {speaker.order !== undefined && speaker.order !== '' && (
                      <span className="rounded-full border border-white/15 bg-black/20 px-1.5 py-0.5 text-[10px] text-white/55">
                        #{speaker.order}
                      </span>
                    )}
                  </button>
                </li>
              );
            })}
          </ul>
        </div>
      )}
    </div>
  );
};

const weekDays = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];

function padNumber(num) {
  return String(num).padStart(2, '0');
}

function formatDatePart(isoDateTime) {
  if (!isoDateTime) return '';
  const date = new Date(isoDateTime);
  if (Number.isNaN(date.getTime())) return '';
  return `${date.getFullYear()}-${padNumber(date.getMonth() + 1)}-${padNumber(date.getDate())}`;
}

function formatTimePart(isoDateTime) {
  if (!isoDateTime) return '';
  const date = new Date(isoDateTime);
  if (Number.isNaN(date.getTime())) return '';
  return `${padNumber(date.getHours())}:${padNumber(date.getMinutes())}`;
}

function combineDateTimeParts(datePart, timePart) {
  if (!datePart || !timePart) return '';
  return `${datePart}T${timePart}`;
}

function formatTimeDisplay(timePart) {
  if (!timePart) return '';
  const [hourStr, minuteStr] = timePart.split(':');
  const hour = Number(hourStr);
  if (Number.isNaN(hour)) return '';
  const period = hour >= 12 ? 'PM' : 'AM';
  const displayHour = ((hour + 11) % 12) + 1;
  return `${displayHour}:${minuteStr} ${period}`;
}

const ScheduleDatePicker = ({ value, onChange }) => {
  const [open, setOpen] = useState(false);
  const containerRef = useRef(null);
  const selectedDate = value ? new Date(`${value}T00:00:00`) : null;
  const [viewDate, setViewDate] = useState(() => selectedDate || new Date());

  useEffect(() => {
    if (value) {
      const next = new Date(`${value}T00:00:00`);
      if (!Number.isNaN(next.getTime())) {
        setViewDate(next);
      }
    }
  }, [value]);

  useEffect(() => {
    const handleClickOutside = (event) => {
      if (containerRef.current && !containerRef.current.contains(event.target)) {
        setOpen(false);
      }
    };
    if (open) {
      document.addEventListener('mousedown', handleClickOutside);
      document.addEventListener('touchstart', handleClickOutside);
    }
    return () => {
      document.removeEventListener('mousedown', handleClickOutside);
      document.removeEventListener('touchstart', handleClickOutside);
    };
  }, [open]);

  const daysInMonth = useMemo(
    () => new Date(viewDate.getFullYear(), viewDate.getMonth() + 1, 0).getDate(),
    [viewDate],
  );

  const firstDayIndex = useMemo(
    () => new Date(viewDate.getFullYear(), viewDate.getMonth(), 1).getDay(),
    [viewDate],
  );

  const displayLabel = selectedDate
    ? selectedDate.toLocaleDateString(undefined, {
        month: 'short',
        day: 'numeric',
        year: 'numeric',
      })
    : 'Select date';

  const handleSelectDay = (day) => {
    const nextDate = new Date(viewDate.getFullYear(), viewDate.getMonth(), day, 0, 0, 0, 0);
    const dateStr = `${nextDate.getFullYear()}-${padNumber(nextDate.getMonth() + 1)}-${padNumber(
      nextDate.getDate(),
    )}`;
    onChange(dateStr);
    setOpen(false);
  };

  const handleClear = () => {
    onChange('');
    setOpen(false);
  };

  return (
    <div ref={containerRef} className="relative">
      <button
        type="button"
        onClick={() => setOpen((prev) => !prev)}
        className="flex w-full items-center justify-between rounded-2xl border border-white/10 bg-white/5 px-4 py-3 text-left text-sm text-white backdrop-blur-sm transition-all duration-200 hover:border-[#EFB078]/40 focus:outline-none focus:ring-0"
      >
        <span className={selectedDate ? 'text-white' : 'text-white/50'}>{displayLabel}</span>
        <div className="ml-3 flex items-center gap-2 text-white/60">
          <FiCalendar size={16} />
          <FiChevronDown
            size={16}
            className={`transition-transform ${open ? 'rotate-180 text-[#EFB078]' : ''}`}
          />
        </div>
      </button>

      {open && (
        <div className="absolute left-0 bottom-full z-[180] mb-2 w-fit min-w-[260px] overflow-hidden rounded-2xl border border-white/10 bg-gradient-to-br from-[#11060d]/95 via-[#1c0b18]/85 to-[#12060f]/95 shadow-[0_16px_48px_rgba(12,6,20,0.55)] backdrop-blur-xl">
          <div className="space-y-3 p-4">
            <div className="flex items-center justify-between">
              <button
                type="button"
                onClick={() =>
                  setViewDate((prev) => new Date(prev.getFullYear(), prev.getMonth() - 1, 1))
                }
                className="flex h-8 w-8 items-center justify-center rounded-full border border-white/10 bg-white/5 text-white/70 transition-all hover:border-[#EFB078]/30 hover:text-white"
              >
                <FiChevronLeft size={14} />
              </button>
              <div className="text-sm font-semibold text-white">
                {viewDate.toLocaleDateString(undefined, { month: 'long', year: 'numeric' })}
              </div>
              <button
                type="button"
                onClick={() =>
                  setViewDate((prev) => new Date(prev.getFullYear(), prev.getMonth() + 1, 1))
                }
                className="flex h-8 w-8 items-center justify-center rounded-full border border-white/10 bg-white/5 text-white/70 transition-all hover:border-[#EFB078]/30 hover:text-white"
              >
                <FiChevronRight size={14} />
              </button>
            </div>

            <div className="grid grid-cols-7 gap-0.5 text-center text-[10px] font-semibold text-white/50">
              {weekDays.map((day) => (
                <div key={day} className="py-1">
                  {day}
                </div>
              ))}
              {Array.from({ length: firstDayIndex }).map((_, index) => (
                <div key={`empty-${index}`} className="py-1" />
              ))}
              {Array.from({ length: daysInMonth }, (_, index) => {
                const day = index + 1;
                const isActive =
                  selectedDate &&
                  selectedDate.getFullYear() === viewDate.getFullYear() &&
                  selectedDate.getMonth() === viewDate.getMonth() &&
                  selectedDate.getDate() === day;
                return (
                  <button
                    type="button"
                    key={day}
                    onClick={() => handleSelectDay(day)}
                    className={`rounded-xl px-1.5 py-1.5 text-xs transition-all duration-150 ${
                      isActive
                        ? 'bg-gradient-to-r from-[#701845]/70 to-[#EFB078]/40 text-white shadow-[0_8px_22px_rgba(112,24,69,0.35)]'
                        : 'text-white/80 hover:bg-white/10 hover:text-white'
                    }`}
                  >
                    {day}
                  </button>
                );
              })}
            </div>

            <div className="flex items-center justify-between pt-1">
              <button
                type="button"
                onClick={handleClear}
                className="rounded-xl border border-white/10 bg-white/5 px-3 py-1.5 text-[10px] font-semibold uppercase tracking-[0.18em] text-white/65 transition-all hover:border-white/20 hover:bg-white/10 hover:text-white"
              >
                Clear
              </button>
              <button
                type="button"
                onClick={() => setOpen(false)}
                className="rounded-xl bg-gradient-to-r from-[#701845]/90 via-[#9E4B63]/80 to-[#EFB078]/85 px-4 py-1.5 text-[11px] font-semibold uppercase tracking-[0.18em] text-white shadow-[0_16px_34px_rgba(136,32,82,0.45)] transition-all duration-200 hover:scale-[1.01]"
              >
                Done
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

const ScheduleTimePicker = ({ value, onChange }) => {
  const [open, setOpen] = useState(false);
  const containerRef = useRef(null);
  const [hour, setHour] = useState(8);
  const [minute, setMinute] = useState(0);
  const [period, setPeriod] = useState('AM');

  useEffect(() => {
    if (!value) {
      setHour(8);
      setMinute(0);
      setPeriod('AM');
      return;
    }
    const [hourStr, minuteStr] = value.split(':');
    const hour24 = Number(hourStr);
    const minuteValue = Number(minuteStr);
    if (Number.isNaN(hour24) || Number.isNaN(minuteValue)) return;
    setMinute(minuteValue);
    if (hour24 === 0) {
      setHour(12);
      setPeriod('AM');
    } else if (hour24 === 12) {
      setHour(12);
      setPeriod('PM');
    } else if (hour24 > 12) {
      setHour(hour24 - 12);
      setPeriod('PM');
    } else {
      setHour(hour24);
      setPeriod('AM');
    }
  }, [value]);

  useEffect(() => {
    const handleClickOutside = (event) => {
      if (containerRef.current && !containerRef.current.contains(event.target)) {
        setOpen(false);
      }
    };
    if (open) {
      document.addEventListener('mousedown', handleClickOutside);
      document.addEventListener('touchstart', handleClickOutside);
    }
    return () => {
      document.removeEventListener('mousedown', handleClickOutside);
      document.removeEventListener('touchstart', handleClickOutside);
    };
  }, [open]);

  const hours = useMemo(() => Array.from({ length: 12 }, (_, i) => i + 1), []);
  const minutes = useMemo(() => [0, 15, 30, 45], []);

  const handleApply = () => {
    const hour24 =
      period === 'PM'
        ? hour === 12
          ? 12
          : (hour + 12) % 24
        : hour % 12;
    const nextValue = `${padNumber(hour24)}:${padNumber(minute)}`;
    onChange(nextValue);
    setOpen(false);
  };

  const handleClear = () => {
    onChange('');
    setHour(8);
    setMinute(0);
    setPeriod('AM');
    setOpen(false);
  };

  const displayLabel = value ? formatTimeDisplay(value) : 'Select time';

  return (
    <div ref={containerRef} className="relative">
      <button
        type="button"
        onClick={() => setOpen((prev) => !prev)}
        className="flex w-full items-center justify-between rounded-2xl border border-white/10 bg-white/5 px-4 py-3 text-left text-sm text-white backdrop-blur-sm transition-all duration-200 hover:border-[#EFB078]/40 focus:outline-none focus:ring-0"
      >
        <span className={value ? 'text-white' : 'text-white/50'}>{displayLabel}</span>
        <div className="ml-3 flex items-center gap-2 text-white/60">
          <FiClock size={16} />
          <FiChevronDown
            size={16}
            className={`transition-transform ${open ? 'rotate-180 text-[#EFB078]' : ''}`}
          />
        </div>
      </button>

      {open && (
        <div className="absolute left-0 bottom-full z-[180] mb-2 w-fit min-w-[220px] overflow-hidden rounded-2xl border border-white/10 bg-gradient-to-br from-[#11060d]/95 via-[#1c0b18]/85 to-[#12060f]/95 shadow-[0_16px_48px_rgba(12,6,20,0.55)] backdrop-blur-xl">
          <div className="space-y-3 p-4">
            <div>
              <p className="mb-1 text-[10px] uppercase tracking-[0.15em] text-white/45">Hour</p>
              <div className="grid grid-cols-4 gap-1.5">
                {hours.map((item) => (
                  <button
                    type="button"
                    key={item}
                    onClick={() => setHour(item)}
                    className={`rounded-lg px-2 py-1 text-xs transition-all ${
                      hour === item
                        ? 'bg-gradient-to-r from-[#701845]/70 to-[#EFB078]/40 text-white shadow-[0_6px_18px_rgba(112,24,69,0.35)]'
                        : 'bg-white/5 text-white/75 hover:bg-white/10 hover:text-white'
                    }`}
                  >
                    {padNumber(item)}
                  </button>
                ))}
              </div>
            </div>
            <div>
              <p className="mb-1 text-[10px] uppercase tracking-[0.15em] text-white/45">Minute</p>
              <div className="grid grid-cols-4 gap-1.5">
                {minutes.map((item) => (
                  <button
                    type="button"
                    key={item}
                    onClick={() => setMinute(item)}
                    className={`rounded-lg px-2 py-1 text-xs transition-all ${
                      minute === item
                        ? 'bg-gradient-to-r from-[#701845]/70 to-[#EFB078]/40 text-white shadow-[0_6px_18px_rgba(112,24,69,0.35)]'
                        : 'bg-white/5 text-white/75 hover:bg-white/10 hover:text-white'
                    }`}
                  >
                    {padNumber(item)}
                  </button>
                ))}
              </div>
            </div>
            <div>
              <p className="mb-1 text-[10px] uppercase tracking-[0.15em] text-white/45">Period</p>
              <div className="grid grid-cols-2 gap-2">
                {['AM', 'PM'].map((item) => (
                  <button
                    type="button"
                    key={item}
                    onClick={() => setPeriod(item)}
                    className={`rounded-lg px-2 py-1.5 text-xs font-semibold transition-all ${
                      period === item
                        ? 'bg-gradient-to-r from-[#701845]/70 to-[#EFB078]/40 text-white shadow-[0_6px_18px_rgba(112,24,69,0.35)]'
                        : 'bg-white/5 text-white/75 hover:bg-white/10 hover:text-white'
                    }`}
                  >
                    {item}
                  </button>
                ))}
              </div>
            </div>
            <div className="flex items-center justify-between pt-1">
              <button
                type="button"
                onClick={handleClear}
                className="rounded-xl border border-white/10 bg-white/5 px-3 py-1.5 text-[10px] font-semibold uppercase tracking-[0.18em] text-white/65 transition-all hover:border-white/20 hover:bg-white/10 hover:text-white"
              >
                Clear
              </button>
              <button
                type="button"
                onClick={handleApply}
                className="rounded-xl bg-gradient-to-r from-[#701845]/90 via-[#9E4B63]/80 to-[#EFB078]/85 px-4 py-1.5 text-[11px] font-semibold uppercase tracking-[0.18em] text-white shadow-[0_16px_34px_rgba(136,32,82,0.45)] transition-all duration-200 hover:scale-[1.01]"
              >
                Set Time
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default SchedulesPage;
