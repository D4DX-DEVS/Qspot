import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { FiEdit2, FiTrash2, FiPlus, FiSearch, FiCalendar, FiClock, FiUser } from 'react-icons/fi';
import Sidebar from '../components/Sidebar';
import ConfirmDialog from '../components/dialogs/ConfirmDialog';
import ErrorState from '../components/ui/ErrorState';
import Spinner from '../components/ui/Spinner';
import EmptyState from '../components/ui/EmptyState';
import Pagination from '../components/ui/Pagination';
import DateTimePicker from '../components/ui/DateTimePicker';
import { FacultySelect } from '../components/ui/EntitySelect';
import usePageTitle from '../hooks/usePageTitle';
import useBodyScrollLock from '../hooks/useBodyScrollLock';
import apiClient from '../api/client';
import brandIcon from '../assets/Icon.png';

const SchedulesPage = () => {
  usePageTitle('Schedules');
  const navigate = useNavigate();
  const [schedules, setSchedules] = useState([]);
  const [filteredSchedules, setFilteredSchedules] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [showEditModal, setShowEditModal] = useState(false);
  const [editingSchedule, setEditingSchedule] = useState(null);
  const [deleteConfirm, setDeleteConfirm] = useState(null);

  const [currentPage, setCurrentPage] = useState(1);
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [facultyFilter, setFacultyFilter] = useState('');
  const itemsPerPage = 10;

  useEffect(() => {
    fetchSchedules();
  }, []);

  useEffect(() => {
    let filtered = [...schedules];

    if (searchTerm) {
      filtered = filtered.filter(
        (schedule) =>
          schedule.title?.toLowerCase().includes(searchTerm.toLowerCase()) ||
          schedule.class?.toLowerCase().includes(searchTerm.toLowerCase()) ||
          schedule.faculty?.name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
          schedule.faculty?.designation?.toLowerCase().includes(searchTerm.toLowerCase())
      );
    }

    if (facultyFilter) {
      filtered = filtered.filter((schedule) => schedule.faculty?._id === facultyFilter);
    }

    if (statusFilter !== 'all') {
      const referenceDate = new Date();
      filtered = filtered.filter((schedule) => {
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
      setError('');
      const response = await apiClient.get('/schedules');
      setSchedules(response.data || []);
    } catch (err) {
      setError(err.message || 'Failed to fetch schedules');
    } finally {
      setLoading(false);
    }
  };

  const handleCreateSchedule = async (formData) => {
    try {
      await apiClient.post('/schedules', formData);
      setShowCreateModal(false);
      fetchSchedules();
    } catch (err) {
      alert(err.message || 'Failed to create schedule');
    }
  };

  const handleEditSchedule = (schedule) => {
    setEditingSchedule(schedule);
    setShowEditModal(true);
  };

  const handleUpdateSchedule = async (formData) => {
    try {
      await apiClient.put(`/schedules/${editingSchedule._id}`, formData);
      setShowEditModal(false);
      setEditingSchedule(null);
      fetchSchedules();
    } catch (err) {
      alert(err.message || 'Failed to update schedule');
    }
  };

  const handleDeleteSchedule = async (scheduleId) => {
    try {
      await apiClient.delete(`/schedules/${scheduleId}`);
      setDeleteConfirm(null);
      fetchSchedules();
    } catch (err) {
      alert(err.message || 'Failed to delete schedule');
    }
  };

  const totalPages = Math.ceil(filteredSchedules.length / itemsPerPage);
  const startIndex = (currentPage - 1) * itemsPerPage;
  const endIndex = startIndex + itemsPerPage;
  const currentSchedules = filteredSchedules.slice(startIndex, endIndex);

  const totalSchedules = schedules.length;
  const upcomingSchedules = schedules.filter((s) => new Date(s.scheduleDate) > new Date()).length;
  const pastSchedules = schedules.filter((s) => new Date(s.scheduleDate) <= new Date()).length;
  const statusOptions = [
    { value: 'all', label: 'All', count: totalSchedules },
    { value: 'upcoming', label: 'Upcoming', count: upcomingSchedules },
    { value: 'completed', label: 'Completed', count: pastSchedules },
  ];

  return (
    <div className="flex min-h-screen overflow-x-hidden bg-black">
      <Sidebar currentPage="schedules" onNavigate={navigate} />

      <div className="flex-1 flex flex-col w-full pb-28 md:ml-64 md:pb-0">
        <main className="flex-1 p-4">
          <div className="mb-4">
            <div className="flex flex-col lg:flex-row lg:items-center lg:justify-between gap-4">
              <div>
                <h2 className="text-2xl font-bold text-white mb-1">Schedules Management</h2>
                <p className="text-gray-400 text-sm">Manage class schedules and timetables</p>
              </div>

              <div className="grid grid-cols-3 gap-2 sm:flex sm:gap-3">
                <div className="relative overflow-hidden rounded-2xl border border-white/10 bg-gradient-to-br from-[#11060d]/80 via-[#1c0b18]/60 to-[#12060f]/80 px-2.5 py-2.5 shadow-[0_8px_32px_rgba(112,24,69,0.25)] backdrop-blur-xl sm:px-4 sm:py-3 sm:min-w-[120px]">
                  <div className="flex items-center gap-2">
                    <FiCalendar className="shrink-0 text-[#EFB078]" size={16} />
                    <div>
                      <p className="text-lg font-bold text-white">{totalSchedules}</p>
                      <p className="text-xs text-gray-400">Total</p>
                    </div>
                  </div>
                </div>
                <div className="relative overflow-hidden rounded-2xl border border-white/10 bg-gradient-to-br from-[#11060d]/80 via-[#1c0b18]/60 to-[#12060f]/80 px-2.5 py-2.5 shadow-[0_8px_32px_rgba(112,24,69,0.25)] backdrop-blur-xl sm:px-4 sm:py-3 sm:min-w-[120px]">
                  <div className="flex items-center gap-2">
                    <FiClock className="shrink-0 text-[#EFB078]" size={16} />
                    <div>
                      <p className="text-lg font-bold text-white">{upcomingSchedules}</p>
                      <p className="text-xs text-gray-400">Upcoming</p>
                    </div>
                  </div>
                </div>
                <div className="relative overflow-hidden rounded-2xl border border-white/10 bg-gradient-to-br from-[#11060d]/80 via-[#1c0b18]/60 to-[#12060f]/80 px-2.5 py-2.5 shadow-[0_8px_32px_rgba(112,24,69,0.25)] backdrop-blur-xl sm:px-4 sm:py-3 sm:min-w-[120px]">
                  <div className="flex items-center gap-2">
                    <FiUser className="shrink-0 text-[#EFB078]" size={16} />
                    <div>
                      <p className="text-lg font-bold text-white">{pastSchedules}</p>
                      <p className="text-xs text-gray-400">Completed</p>
                    </div>
                  </div>
                </div>
              </div>
            </div>

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
                <div className="flex items-center gap-1 overflow-x-auto rounded-2xl border border-white/10 bg-gradient-to-br from-[#11060d]/60 via-[#1c0b18]/40 to-[#12060f]/60 p-1.5 backdrop-blur-xl">
                  {statusOptions.map((option) => {
                    const isActive = statusFilter === option.value;
                    return (
                      <button
                        key={option.value}
                        onClick={() => setStatusFilter(option.value)}
                        className={`flex shrink-0 items-center gap-1.5 rounded-2xl px-3 py-1.5 text-xs font-semibold uppercase tracking-[0.14em] transition-all ${
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
                    value={facultyFilter}
                    onChange={setFacultyFilter}
                    includeAllOption
                    allLabel="All Faculties"
                    className="!py-2.5 text-xs"
                  />
                </div>

                <button
                  onClick={() => setShowCreateModal(true)}
                  className="inline-flex w-full shrink-0 items-center justify-center gap-2 whitespace-nowrap rounded-2xl bg-gradient-to-r from-[#701845]/90 via-[#9E4B63]/80 to-[#EFB078]/85 px-4 py-2.5 text-sm font-semibold text-white shadow-[0_8px_20px_rgba(112,24,69,0.3)] transition-all hover:from-[#5a1538] hover:to-[#d49a6a] sm:w-auto"
                  type="button"
                >
                  <FiPlus size={14} />
                  <span>Add</span>
                </button>
              </div>
            </div>
          </div>
          {loading ? (
            <Spinner />
          ) : error ? (
            <ErrorState message={error} onRetry={fetchSchedules} />
          ) : (
            <div className="space-y-3">
              {filteredSchedules.length === 0 ? (
                <EmptyState
                  icon={FiCalendar}
                  title={
                    searchTerm || facultyFilter || statusFilter !== 'all'
                      ? 'No schedules found matching your criteria'
                      : 'No schedules found'
                  }
                  action={
                    (searchTerm || facultyFilter || statusFilter !== 'all') && (
                      <button
                        onClick={() => {
                          setSearchTerm('');
                          setFacultyFilter('');
                          setStatusFilter('all');
                        }}
                        className="text-indigo-400 hover:text-indigo-300 transition-colors text-sm"
                      >
                        Clear filters
                      </button>
                    )
                  }
                />
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
                                <button
                                  type="button"
                                  onClick={() => schedule.faculty?._id && navigate(`/admin/speakers`)}
                                  className="inline-flex items-center gap-1 rounded-full bg-white/5 px-2 py-[2px] hover:bg-white/10"
                                >
                                  <FiUser size={10} className="text-[#EFB078]" />
                                  {schedule.faculty?.name || 'Unknown Faculty'}
                                  {schedule.faculty?.designation && (
                                    <span className="ml-1 text-[9px] uppercase tracking-[0.12em] text-white/45">
                                      {schedule.faculty.designation}
                                    </span>
                                  )}
                                </button>
                              </div>
                            </div>
                            <span
                              className={`inline-flex items-center gap-1 rounded-full px-2 py-[2px] text-[9px] font-semibold uppercase tracking-[0.18em] ${
                                isUpcoming ? 'bg-emerald-500/20 text-emerald-200' : 'bg-slate-600/25 text-slate-200'
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
                                className="flex h-9 w-9 items-center justify-center rounded-xl border border-white/15 bg-white/5 text-white/70 transition-colors hover:border-[#EFB078]/45 hover:text-white"
                                title="Edit schedule"
                                aria-label="Edit schedule"
                              >
                                <FiEdit2 size={12} />
                              </button>
                              <button
                                onClick={() => setDeleteConfirm(schedule)}
                                className="flex h-9 w-9 items-center justify-center rounded-xl border border-red-500/35 bg-red-500/15 text-red-200 transition-colors hover:border-red-400/60 hover:bg-red-500/25 hover:text-white"
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

                  <Pagination
                    page={currentPage}
                    totalPages={totalPages}
                    total={filteredSchedules.length}
                    onChange={setCurrentPage}
                    label="schedules"
                  />
                </>
              )}
            </div>
          )}
        </main>
      </div>

      {showCreateModal && (
        <ScheduleFormModal title="Add New Schedule" submitLabel="Create Schedule" onClose={() => setShowCreateModal(false)} onSave={handleCreateSchedule} />
      )}

      {showEditModal && editingSchedule && (
        <ScheduleFormModal
          title="Edit Schedule"
          submitLabel="Update Schedule"
          schedule={editingSchedule}
          onClose={() => {
            setShowEditModal(false);
            setEditingSchedule(null);
          }}
          onSave={handleUpdateSchedule}
        />
      )}

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

// Shared Create/Edit form. `schedule` present => edit mode.
const ScheduleFormModal = ({ title, submitLabel, schedule, onClose, onSave }) => {
  const [formData, setFormData] = useState({
    title: schedule?.title || '',
    class: schedule?.class || '',
    scheduleDate: schedule?.scheduleDate || '',
    faculty: schedule?.faculty?._id || '',
  });
  const [loading, setLoading] = useState(false);
  useBodyScrollLock(true);

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!formData.title.trim() || !formData.class.trim() || !formData.scheduleDate || !formData.faculty) {
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

  const inputClass =
    'mt-2 block w-full rounded-2xl border border-white/10 bg-white/5 px-4 py-3 text-sm text-white placeholder-white/40 backdrop-blur-sm transition-all duration-200 focus:border-[#EFB078]/60 focus:outline-none focus:ring-0';

  return (
    <div className="fixed inset-0 z-[120] flex h-full w-full items-center justify-center overflow-y-auto bg-black/70 px-3 py-6 backdrop-blur-md sm:px-4 sm:py-10">
      <div className="relative max-h-[90vh] w-full max-w-xl overflow-y-auto rounded-3xl border border-white/12 bg-gradient-to-br from-[#100713]/92 via-[#190d23]/85 to-[#10060f]/92 shadow-[0_28px_80px_-28px_rgba(12,6,20,0.92)]">
        <div className="pointer-events-none absolute inset-0 rounded-3xl bg-[radial-gradient(circle_at_top_right,rgba(136,32,82,0.55),transparent_65%)]" aria-hidden="true" />

        <div className="relative px-5 pt-8 pb-6 sm:px-8 sm:pt-9 sm:pb-8">
          <div className="absolute left-5 top-5 flex h-10 w-10 items-center justify-center rounded-2xl border border-white/12 bg-black/60 shadow-[0_14px_36px_rgba(136,32,82,0.45)] sm:left-8 sm:top-6 sm:h-12 sm:w-12">
            <img src={brandIcon} alt="QSpot icon" className="h-6 w-6 object-contain sm:h-7 sm:w-7" />
          </div>

          <div className="flex flex-col gap-2 pl-14 sm:pl-20">
            <p className="text-xs font-semibold uppercase tracking-[0.24em] text-[#f3c5a0]/70">Schedule</p>
            <h3 className="text-xl font-semibold tracking-wide text-white sm:text-2xl">{title}</h3>
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
                placeholder="Enter class (e.g., 8, 9, 10)"
                className={inputClass}
                required
              />
            </div>

            <div>
              <label className="text-xs font-semibold uppercase tracking-[0.2em] text-white/65">Date &amp; Time *</label>
              <DateTimePicker
                valueISO={formData.scheduleDate}
                onChangeISO={(iso) => setFormData({ ...formData, scheduleDate: iso })}
                required
                className="mt-2"
              />
            </div>

            <div>
              <label className="text-xs font-semibold uppercase tracking-[0.2em] text-white/65">Faculty *</label>
              <FacultySelect
                value={formData.faculty}
                onChange={(value) => setFormData({ ...formData, faculty: value })}
                required
                className="mt-2"
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
                {loading ? 'Saving...' : submitLabel}
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
};

export default SchedulesPage;
