import React, { useState, useEffect, useCallback } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import { FiEdit2, FiTrash2, FiPlus, FiSearch, FiPlay, FiCalendar, FiMessageSquare, FiEyeOff, FiBarChart2 } from 'react-icons/fi';
import Sidebar from '../components/Sidebar';
import ConfirmDialog from '../components/dialogs/ConfirmDialog';
import ErrorState from '../components/ui/ErrorState';
import Spinner from '../components/ui/Spinner';
import EmptyState from '../components/ui/EmptyState';
import Pagination from '../components/ui/Pagination';
import DateTimePicker from '../components/ui/DateTimePicker';
import Modal from '../components/ui/Modal';
import { SubjectSelect, FacultySelect } from '../components/ui/EntitySelect';
import usePageTitle from '../hooks/usePageTitle';
import useBodyScrollLock from '../hooks/useBodyScrollLock';
import apiClient from '../api/client';
import { formatDuration } from '../utils/format';
import brandIcon from '../assets/Icon.png';

const VIDEO_FILE_ACCEPT = 'video/mp4,video/webm,video/quicktime,video/x-m4v,.mp4,.webm,.mov,.m4v';

// Helper function to extract YouTube video ID
const getYouTubeVideoId = (url) => {
  if (!url || typeof url !== 'string') return null;
  
  // Clean the URL - remove any whitespace
  url = url.trim();
  
  // YouTube URL patterns - comprehensive matching
  const patterns = [
    // YouTube Shorts: youtube.com/shorts/VIDEO_ID
    /youtube\.com\/shorts\/([a-zA-Z0-9_-]{11})/,
    // Standard watch URLs: youtube.com/watch?v=VIDEO_ID
    /(?:youtube\.com\/watch\?v=|youtu\.be\/|youtube\.com\/embed\/|youtube\.com\/v\/)([a-zA-Z0-9_-]{11})/,
    // Watch URLs with other parameters: youtube.com/watch?feature=...&v=VIDEO_ID
    /youtube\.com\/watch\?.*[&?]v=([a-zA-Z0-9_-]{11})/,
    // Short URLs: youtu.be/VIDEO_ID
    /youtu\.be\/([a-zA-Z0-9_-]{11})/,
    // Mobile URLs: m.youtube.com/watch?v=VIDEO_ID
    /m\.youtube\.com\/watch\?v=([a-zA-Z0-9_-]{11})/,
    // Mobile Shorts: m.youtube.com/shorts/VIDEO_ID
    /m\.youtube\.com\/shorts\/([a-zA-Z0-9_-]{11})/,
    // Just the video ID if it's 11 characters (YouTube video IDs are always 11 chars)
    /^([a-zA-Z0-9_-]{11})$/
  ];
  
  for (const pattern of patterns) {
    const match = url.match(pattern);
    if (match && match[1] && match[1].length === 11) {
      return match[1];
    }
  }
  
  console.warn('Could not extract YouTube video ID from:', url);
  return null;
};

// Helper function to check if URL is a YouTube link
const isYouTubeUrl = (url) => {
  if (!url) return false;
  return url.includes('youtube.com') || url.includes('youtu.be');
};

// Helper function to handle YouTube video click
const handleYouTubeClick = (url) => {
  if (isYouTubeUrl(url)) {
    // Open YouTube video in new tab
    window.open(url, '_blank', 'noopener,noreferrer');
  }
};

// YouTube Thumbnail Component with automatic fallback
const YouTubeThumbnail = ({ url, className, alt = "YouTube thumbnail", onOrientationChange }) => {
  const [imgSrc, setImgSrc] = useState(null);
  const [currentQuality, setCurrentQuality] = useState('maxresdefault');
  const [hasError, setHasError] = useState(false);

  useEffect(() => {
    // Reset when URL changes
    setHasError(false);
    const videoId = getYouTubeVideoId(url);
    
    if (videoId) {
      // Start with hqdefault (always available for all YouTube videos)
      // This ensures thumbnails always load without console errors
      setCurrentQuality('hqdefault');
      const thumbnailUrl = `https://img.youtube.com/vi/${videoId}/hqdefault.jpg`;
      setImgSrc(thumbnailUrl);
    } else {
      console.warn('Could not extract YouTube video ID from URL:', url);
      setImgSrc(null);
    }
  }, [url]);

  const handleError = () => {
    const videoId = getYouTubeVideoId(url);
    if (!videoId) {
      console.error('No video ID found for URL:', url);
      setHasError(true);
      return;
    }

    // If hqdefault fails, something is seriously wrong
    if (currentQuality === 'hqdefault') {
      console.error('hqdefault thumbnail failed for video:', videoId, 'URL:', url);
      setHasError(true);
      setImgSrc(null);
    } else if (currentQuality === 'maxresdefault') {
      // Fallback to hqdefault (always available)
      setCurrentQuality('hqdefault');
      setImgSrc(`https://img.youtube.com/vi/${videoId}/hqdefault.jpg`);
    }
  };

  const handleLoad = (event) => {
    setHasError(false);
    if (typeof onOrientationChange === 'function' && event?.target) {
      const { naturalWidth, naturalHeight } = event.target;
      if (naturalWidth && naturalHeight) {
        onOrientationChange(naturalHeight > naturalWidth ? 'portrait' : 'landscape');
      }
    }
  };

  if (!url || !getYouTubeVideoId(url)) {
    return (
      <div className={`${className} bg-gray-800 flex items-center justify-center`}>
        <span className="text-gray-500 text-xs">Invalid URL</span>
      </div>
    );
  }

  if (hasError && !imgSrc) {
    return (
      <div className={`${className} bg-gray-800 flex items-center justify-center`}>
        <span className="text-gray-500 text-xs">Thumbnail unavailable</span>
      </div>
    );
  }

  if (!imgSrc) {
    return (
      <div className={`${className} bg-gray-800 flex items-center justify-center`}>
        <div className="animate-pulse text-gray-500 text-xs">Loading...</div>
      </div>
    );
  }

  return (
    <img
      key={imgSrc} // Force re-render when src changes
      src={imgSrc}
      alt={alt}
      className={className}
      onError={handleError}
      onLoad={handleLoad}
      style={{ display: 'block', objectFit: 'cover', width: '100%', height: '100%' }}
    />
  );
};

// Unified thumbnail preview component with orientation support
const VideoThumbnailPreview = ({ video, className = '', onOrientationChange }) => {
  const videoUrl = video.video;
  const detectOrientationFromUrl = (url) => {
    if (!url) return 'landscape';
    if (isYouTubeUrl(url) && /\/shorts\//i.test(url)) {
      return 'portrait';
    }
    return 'landscape';
  };

  const [orientation, setOrientation] = useState(() => detectOrientationFromUrl(videoUrl));

  const updateOrientation = useCallback((value) => {
    if (value !== 'portrait' && value !== 'landscape') return;
    setOrientation((prev) => {
      if (prev === value) return prev;
      if (typeof onOrientationChange === 'function') {
        onOrientationChange(value);
      }
      return value;
    });
  }, [onOrientationChange]);

  useEffect(() => {
    const initialOrientation = detectOrientationFromUrl(videoUrl);
    setOrientation(initialOrientation);
    if (typeof onOrientationChange === 'function') {
      onOrientationChange(initialOrientation);
    }
  }, [videoUrl, onOrientationChange]);

  const thumbnailWrapperClass = orientation === 'portrait'
    ? 'aspect-[9/16]'
    : 'aspect-[16/9]';

  return (
    <div className={`relative ${thumbnailWrapperClass} w-full overflow-hidden rounded-xl bg-black/40 ${className}`}>
      {isYouTubeUrl(videoUrl) ? (
        <button
          type="button"
          className="group/preview relative h-full w-full"
          onClick={(e) => {
            e.stopPropagation();
            handleYouTubeClick(videoUrl);
          }}
          title="Open in YouTube"
        >
          <YouTubeThumbnail
            url={videoUrl}
            className="h-full w-full object-cover transition-all duration-300 group-hover/preview:scale-[1.03]"
            alt={video.title || 'Video thumbnail'}
            onOrientationChange={/\/shorts\//i.test(videoUrl) ? undefined : updateOrientation}
          />
          <div className="pointer-events-none absolute inset-0 bg-gradient-to-t from-black/65 via-black/10 to-transparent opacity-80 transition-opacity group-hover/preview:opacity-60" />
          <div className="pointer-events-none absolute bottom-3 right-3 inline-flex items-center gap-1 rounded-full bg-black/60 px-3 py-1 text-[10px] font-semibold uppercase tracking-[0.18em] text-white/90">
            Watch
          </div>
        </button>
      ) : (
        <div className="relative h-full w-full">
          <video
            src={videoUrl}
            className="h-full w-full object-cover"
            preload="metadata"
            muted
            playsInline
            onClick={(e) => e.stopPropagation()}
            onLoadedMetadata={(event) => {
              const { videoHeight, videoWidth } = event.target;
              if (videoHeight && videoWidth) {
                updateOrientation(videoHeight > videoWidth ? 'portrait' : 'landscape');
              }
            }}
          />
          <div className="pointer-events-none absolute inset-0 bg-gradient-to-t from-black/65 via-black/10 to-transparent opacity-70" />
          <div className="pointer-events-none absolute bottom-3 right-3 inline-flex items-center gap-1 rounded-full bg-black/60 px-3 py-1 text-[10px] font-semibold uppercase tracking-[0.18em] text-white/90">
            Preview
          </div>
        </div>
      )}
    </div>
  );
};

const VideoCard = ({ video, onEdit, onDelete, onOpenContent, onOpenStats }) => {
  const [orientation, setOrientation] = useState('landscape');
  const isPortrait = orientation === 'portrait';

  return (
    <article
      className="group relative overflow-hidden rounded-2xl border border-white/10 bg-gradient-to-br from-[#18061c]/90 via-[#120514]/92 to-[#08040a]/95 p-3 shadow-[0_10px_28px_-18px_rgba(112,24,69,0.5)] transition-all duration-300 hover:-translate-y-1 hover:border-[#701845]/40 hover:shadow-[0_18px_40px_-20px_rgba(112,24,69,0.68)]"
    >
      <div
        className={`flex gap-3 ${
          isPortrait ? 'flex-col md:flex-row md:items-start' : 'flex-col'
        }`}
      >
        <div className={isPortrait ? 'w-24 md:w-28 lg:w-32 flex-shrink-0' : 'w-full relative'}>
          <div className="rounded-xl bg-black/30 p-1.5">
            <VideoThumbnailPreview
              video={video}
              onOrientationChange={setOrientation}
              className=""
            />
          </div>
          {video.isPublished === false && (
            <span className="absolute left-3 top-3 inline-flex items-center gap-1 rounded-full bg-black/70 px-2 py-0.5 text-[9px] font-semibold uppercase tracking-[0.16em] text-amber-200">
              <FiEyeOff size={10} /> Draft
            </span>
          )}
        </div>

        <div
          className={`flex min-w-0 flex-1 flex-col ${
            isPortrait ? 'md:min-h-[240px] gap-3' : 'gap-3'
          }`}
        >
          <div className="px-0.5 pt-0.5 space-y-2">
            <h3
              className={`text-[13px] font-semibold text-white leading-snug break-words whitespace-normal ${
                isPortrait ? 'line-clamp-6' : 'line-clamp-3'
              }`}
            >
              {video.order ? `#${video.order} · ` : ''}
              {video.title}
            </h3>
            <div className="flex flex-wrap items-center gap-1.5">
              <span className="inline-flex min-h-[28px] items-center justify-start gap-2 rounded-full border border-[#EFB078]/30 bg-gradient-to-r from-[#701845]/30 to-[#EFB078]/20 px-3 py-1 text-[10px] font-semibold uppercase tracking-[0.14em] text-[#EFB078] shadow-[0_2px_8px_rgba(239,176,120,0.15)]">
                {video.subject?.name || 'Subject Pending'}
              </span>
              {video.durationSeconds > 0 && (
                <span className="inline-flex items-center rounded-full bg-white/5 px-2.5 py-1 text-[10px] font-semibold text-white/60">
                  {formatDuration(video.durationSeconds)}
                </span>
              )}
            </div>
          </div>
          <div
            className={`mt-auto flex gap-2 ${
              isPortrait
                ? 'flex-col items-stretch md:flex-row md:items-center md:justify-between'
                : 'items-center justify-start'
            }`}
          >
            <div className={`flex items-center gap-2 opacity-100 transition-all duration-200 md:opacity-0 md:group-hover:opacity-100 ${isPortrait ? 'md:ml-auto' : ''}`}>
              <button
                onClick={(e) => {
                  e.stopPropagation();
                  onOpenContent();
                }}
                className="flex min-h-[36px] items-center gap-1 rounded-xl bg-white/10 px-2.5 py-1.5 text-[10px] font-semibold text-white transition-all hover:bg-white/20"
                title="Questions, learn note & downloads"
              >
                <FiMessageSquare size={12} />
                Content
              </button>
              <button
                onClick={(e) => {
                  e.stopPropagation();
                  onOpenStats();
                }}
                className="flex min-h-[36px] items-center gap-1 rounded-xl bg-white/10 px-2.5 py-1.5 text-[10px] font-semibold text-white transition-all hover:bg-white/20"
                title="Views, completion & quiz stats"
              >
                <FiBarChart2 size={12} />
                Stats
              </button>
              <button
                onClick={(e) => {
                  e.stopPropagation();
                  onEdit();
                }}
                className="flex min-h-[36px] items-center gap-1 rounded-xl bg-white/10 px-2.5 py-1.5 text-[10px] font-semibold text-white transition-all hover:bg-white/20"
                title="Edit video"
              >
                <FiEdit2 size={12} />
                Edit
              </button>
              <button
                onClick={(e) => {
                  e.stopPropagation();
                  onDelete();
                }}
                className="flex min-h-[36px] items-center gap-1 rounded-xl bg-red-500/20 px-2.5 py-1.5 text-[10px] font-semibold text-red-200 transition-all hover:bg-red-500/30"
                title="Delete video"
              >
                <FiTrash2 size={12} />
                Delete
              </button>
            </div>
          </div>
        </div>
      </div>
    </article>
  );
};

const VideosPage = () => {
  usePageTitle('Videos');
  const navigate = useNavigate();
  const [searchParams, setSearchParams] = useSearchParams();
  const [videos, setVideos] = useState([]);
  const [filteredVideos, setFilteredVideos] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [showEditModal, setShowEditModal] = useState(false);
  const [editingVideo, setEditingVideo] = useState(null);
  const [deleteConfirm, setDeleteConfirm] = useState(null);
  const [statsVideo, setStatsVideo] = useState(null);
  const [stats, setStats] = useState(null);
  const [statsLoading, setStatsLoading] = useState(false);
  const [statsError, setStatsError] = useState('');

  // Pagination and search states
  const [currentPage, setCurrentPage] = useState(1);
  const [searchTerm, setSearchTerm] = useState('');
  // Cross-link from Subjects ("Videos" button) preselects this via ?subject=
  const [subjectFilter, setSubjectFilter] = useState(searchParams.get('subject') || '');
  const itemsPerPage = 12;

  useEffect(() => {
    fetchVideos();
  }, []);

  useEffect(() => {
    const next = new URLSearchParams(searchParams);
    if (subjectFilter) next.set('subject', subjectFilter);
    else next.delete('subject');
    setSearchParams(next, { replace: true });
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [subjectFilter]);

  // Filter and sort videos based on search term, subject filter, and sort options
  useEffect(() => {
    let filtered = [...videos];

    // Apply search filter
    if (searchTerm) {
      filtered = filtered.filter(video => 
        video.title?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        video.description?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        video.subject?.name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        video.releaseDate?.toLowerCase().includes(searchTerm.toLowerCase())
      );
    }

    // Apply subject filter
    if (subjectFilter) {
      filtered = filtered.filter(video => 
        video.subject?._id === subjectFilter
      );
    }

    // Default sorting: subject, then order, then newest first (CONTRACT.md).
    filtered.sort((a, b) => {
      const subjectA = a.subject?.name || '';
      const subjectB = b.subject?.name || '';
      if (subjectA !== subjectB) return subjectA.localeCompare(subjectB);
      const orderA = Number(a.order) || 0;
      const orderB = Number(b.order) || 0;
      if (orderA !== orderB) return orderA - orderB;
      const dateA = new Date(a.createdAt || 0);
      const dateB = new Date(b.createdAt || 0);
      return dateB - dateA;
    });

    setFilteredVideos(filtered);
    setCurrentPage(1); // Reset to first page when filtering
  }, [videos, searchTerm, subjectFilter]);

  const fetchVideos = async () => {
    try {
      setLoading(true);
      setError('');
      const response = await apiClient.get('/videos');
      const loadedVideos = response.data || [];
      setVideos(loadedVideos);
      const target = loadedVideos.find((video) => video._id === searchParams.get('video'));
      if (target && searchParams.get('view') === 'edit') handleEditVideo(target);
      if (target && searchParams.get('view') === 'stats') handleOpenStats(target);
    } catch (err) {
      setError(err.message || 'Failed to fetch videos');
    } finally {
      setLoading(false);
    }
  };

  // Builds the multipart/JSON payload shared by create and update. A picked
  // file uploads as multipart (with a progress callback); otherwise JSON
  // with the pasted URL, per CONTRACT.md's admin video POST/PUT.
  const buildVideoPayload = (formData) => {
    const fields = {
      title: formData.title,
      description: formData.description,
      subject: formData.subject,
      speaker: formData.speaker || '',
      releaseDate: formData.releaseDate || '',
      order: Number(formData.order) || 0,
      isPublished: formData.isPublished,
      practiceEnabled: formData.practiceEnabled,
      practiceTimerMode: formData.practiceTimerMode,
      practiceOverallTimeLimit: formData.practiceOverallTimeLimit ? Number(formData.practiceOverallTimeLimit) : null,
      practicePerQuestionTimeLimit: formData.practicePerQuestionTimeLimit ? Number(formData.practicePerQuestionTimeLimit) : null,
      practiceStartDate: formData.practiceStartDate || '',
      practiceEndDate: formData.practiceEndDate || '',
    };
    if (formData.durationSeconds) fields.durationSeconds = Number(formData.durationSeconds) || 0;

    if (formData.videoFile) {
      const body = new FormData();
      body.append('video', formData.videoFile);
      Object.entries(fields).forEach(([key, value]) => body.append(key, String(value)));
      return { payload: body, headers: { 'Content-Type': 'multipart/form-data' } };
    }
    return { payload: { ...fields, video: formData.videoUrl }, headers: {} };
  };

  const handleCreateVideo = async (formData, onProgress) => {
    try {
      const { payload, headers } = buildVideoPayload(formData);
      await apiClient.post('/videos', payload, {
        headers,
        onUploadProgress: onProgress,
      });
      setShowCreateModal(false);
      fetchVideos();
    } catch (err) {
      alert(err.message || 'Failed to create video');
    }
  };

  const handleEditVideo = (video) => {
    setEditingVideo(video);
    setShowEditModal(true);
  };

  const handleOpenContent = (video) => {
    navigate(`/admin/video-questions?videoId=${video._id}`);
  };

  // GET /api/admin/videos/:id/stats -> { videoId, views, completed,
  // avgWatchedSeconds, quiz:{attempts, avgPercentage} } (CONTRACT.md).
  const handleOpenStats = async (video) => {
    setStatsVideo(video);
    setStats(null);
    setStatsError('');
    setStatsLoading(true);
    try {
      const response = await apiClient.get(`/admin/videos/${video._id}/stats`);
      setStats(response.data);
    } catch (err) {
      setStatsError(err.message || 'Failed to load video stats');
    } finally {
      setStatsLoading(false);
    }
  };

  const handleUpdateVideo = async (formData, onProgress) => {
    try {
      const { payload, headers } = buildVideoPayload(formData);
      await apiClient.put(`/videos/${editingVideo._id}`, payload, {
        headers,
        onUploadProgress: onProgress,
      });
      setShowEditModal(false);
      setEditingVideo(null);
      fetchVideos();
    } catch (err) {
      alert(err.message || 'Failed to update video');
    }
  };

  const handleDeleteVideo = async (videoId) => {
    try {
      await apiClient.delete(`/videos/${videoId}`);
      setDeleteConfirm(null);
      fetchVideos();
    } catch (err) {
      alert(err.message || 'Failed to delete video');
    }
  };

  // Pagination logic
  const totalPages = Math.ceil(filteredVideos.length / itemsPerPage);
  const startIndex = (currentPage - 1) * itemsPerPage;
  const endIndex = startIndex + itemsPerPage;
  const currentVideos = filteredVideos.slice(startIndex, endIndex);

  // Statistics
  const totalVideos = videos.length;
  const recentVideos = videos.filter(v => {
    const videoDate = new Date(v.createdAt);
    const weekAgo = new Date();
    weekAgo.setDate(weekAgo.getDate() - 7);
    return videoDate > weekAgo;
  }).length;

  return (
    <div className="flex min-h-screen overflow-x-hidden bg-black">
      <Sidebar currentPage="videos" onNavigate={navigate} />
      
      <div className="flex-1 flex flex-col w-full pb-28 md:ml-64 md:pb-0">
        <main className="flex-1 p-4 sm:p-6 lg:p-8">
          {/* Header Section */}
          <div className="mb-8">
            <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
              <div>
                <h2 className="text-2xl font-semibold text-white">Videos Management</h2>
                <p className="text-sm text-gray-400">Manage educational videos and content across subjects.</p>
              </div>
              <div className="flex flex-wrap items-center gap-3">
                <div className="relative flex-1 overflow-hidden rounded-2xl border border-white/12 bg-gradient-to-br from-[#140718]/88 via-[#1b0b20]/75 to-[#0b040d]/90 px-5 py-4 shadow-[0_18px_46px_-24px_rgba(112,24,69,0.5)] backdrop-blur-xl min-w-[140px] sm:flex-none sm:min-w-[180px]">
                  <div className="flex items-center gap-3">
                    <div className="flex h-10 w-10 items-center justify-center rounded-2xl border border-white/15 bg-gradient-to-br from-[#701845]/80 via-[#9E4B63]/65 to-[#EFB078]/55 text-white shadow-[0_14px_32px_rgba(112,24,69,0.45)]">
                      <FiPlay size={16} />
                    </div>
                    <div className="flex flex-col leading-tight">
                      <span className="text-[10px] uppercase tracking-[0.24em] text-white/60">
                        Total
                      </span>
                      <span className="text-lg font-semibold text-white">{totalVideos}</span>
                    </div>
                  </div>
                </div>
                <div className="relative flex-1 overflow-hidden rounded-2xl border border-white/12 bg-gradient-to-br from-[#102319]/88 via-[#11291e]/75 to-[#05140c]/90 px-5 py-4 shadow-[0_18px_46px_-24px_rgba(12,142,96,0.5)] backdrop-blur-xl min-w-[140px] sm:flex-none sm:min-w-[180px]">
                  <div className="flex items-center gap-3">
                    <div className="flex h-10 w-10 items-center justify-center rounded-2xl border border-white/15 bg-gradient-to-br from-[#0f7d57]/80 via-[#1fb584]/65 to-[#4ad6a8]/55 text-white shadow-[0_14px_32px_rgba(15,125,87,0.45)]">
                      <FiCalendar size={16} />
                    </div>
                    <div className="flex flex-col leading-tight">
                      <span className="text-[10px] uppercase tracking-[0.24em] text-white/60">
                        This Week
                      </span>
                      <span className="text-lg font-semibold text-white">{recentVideos}</span>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            {/* Search and Filter Section */}
            <div className="mt-4 flex flex-col sm:flex-row gap-3">
                  <div className="relative flex-1 min-w-[240px]">
                <FiSearch className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400" size={16} />
                <input
                  type="text"
                  placeholder="Search videos by title, description, subject, or release date..."
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  className="w-full pl-9 pr-4 py-3 bg-gradient-to-br from-[#11060d]/60 via-[#1c0b18]/40 to-[#12060f]/60 border border-white/10 rounded-2xl text-white placeholder-slate-400 backdrop-blur-xl focus:outline-none focus:border-[#701845]/50 focus:ring-2 focus:ring-[#701845]/30 transition-all text-sm"
                />
              </div>
              <div className="flex flex-col sm:flex-row gap-2 sm:items-stretch">
                <div className="sm:w-52">
                  <SubjectSelect
                    value={subjectFilter}
                    onChange={setSubjectFilter}
                    includeAllOption
                    allLabel="All Subjects"
                    placeholder="Filter by subject"
                    className="!py-2.5 text-[13px]"
                  />
                </div>
                <button
                  onClick={() => setShowCreateModal(true)}
                  className="inline-flex items-center justify-center gap-2 whitespace-nowrap rounded-2xl bg-gradient-to-r from-[#701845]/90 via-[#9E4B63]/80 to-[#EFB078]/85 px-4 py-2.5 text-sm font-semibold text-white shadow-[0_8px_20px_rgba(112,24,69,0.3)] transition-all hover:from-[#5a1538] hover:to-[#d49a6a]"
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
            <ErrorState message={error} onRetry={fetchVideos} />
          ) : (
            <div className="space-y-3">
              {filteredVideos.length === 0 ? (
                <EmptyState
                  icon={FiPlay}
                  title={searchTerm || subjectFilter ? 'No videos found matching your search' : 'No videos found'}
                  action={
                    (searchTerm || subjectFilter) && (
                      <button
                        onClick={() => {
                          setSearchTerm('');
                          setSubjectFilter('');
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
                  <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
                    {currentVideos.map((video) => (
                      <VideoCard
                        key={video._id}
                        video={video}
                        onEdit={() => handleEditVideo(video)}
                        onDelete={() => setDeleteConfirm(video)}
                        onOpenContent={() => handleOpenContent(video)}
                        onOpenStats={() => handleOpenStats(video)}
                      />
                    ))}
                  </div>

                  <Pagination
                    page={currentPage}
                    totalPages={totalPages}
                    total={filteredVideos.length}
                    onChange={setCurrentPage}
                    label="videos"
                  />
                </>
              )}
            </div>
          )}
        </main>
      </div>

      {/* Create Video Modal */}
      {showCreateModal && (
        <VideoFormModal title="Add New Video" submitLabel="Create Video" onClose={() => setShowCreateModal(false)} onSave={handleCreateVideo} />
      )}

      {/* Edit Video Modal */}
      {showEditModal && editingVideo && (
        <VideoFormModal
          title="Edit Video"
          submitLabel="Update Video"
          video={editingVideo}
          onClose={() => {
            setShowEditModal(false);
            setEditingVideo(null);
          }}
          onSave={handleUpdateVideo}
        />
      )}

      {statsVideo && (
        <Modal
          title={statsVideo.title}
          subtitle="Video Stats"
          icon={brandIcon}
          onClose={() => setStatsVideo(null)}
          maxWidth="max-w-lg"
        >
          {statsLoading ? (
            <Spinner />
          ) : statsError ? (
            <ErrorState message={statsError} onRetry={() => handleOpenStats(statsVideo)} />
          ) : (
            stats && (
              <div className="grid grid-cols-2 gap-3">
                <div className="rounded-xl border border-white/10 bg-white/5 p-4">
                  <p className="text-[10px] uppercase tracking-[0.2em] text-white/45">Views</p>
                  <p className="mt-1 text-2xl font-semibold text-white">{stats.views ?? 0}</p>
                </div>
                <div className="rounded-xl border border-white/10 bg-white/5 p-4">
                  <p className="text-[10px] uppercase tracking-[0.2em] text-white/45">Completed</p>
                  <p className="mt-1 text-2xl font-semibold text-white">{stats.completed ?? 0}</p>
                </div>
                <div className="rounded-xl border border-white/10 bg-white/5 p-4">
                  <p className="text-[10px] uppercase tracking-[0.2em] text-white/45">Avg. Watched</p>
                  <p className="mt-1 text-2xl font-semibold text-white">{formatDuration(stats.avgWatchedSeconds)}</p>
                </div>
                <div className="rounded-xl border border-white/10 bg-white/5 p-4">
                  <p className="text-[10px] uppercase tracking-[0.2em] text-white/45">Quiz Attempts</p>
                  <p className="mt-1 text-2xl font-semibold text-white">{stats.quiz?.attempts ?? 0}</p>
                </div>
                <div className="col-span-2 rounded-xl border border-white/10 bg-white/5 p-4">
                  <p className="text-[10px] uppercase tracking-[0.2em] text-white/45">Avg. Quiz Score</p>
                  <p className="mt-1 text-2xl font-semibold text-[#EFB078]">
                    {stats.quiz?.avgPercentage != null ? `${stats.quiz.avgPercentage}%` : 'NA'}
                  </p>
                </div>
              </div>
            )
          )}
        </Modal>
      )}

      {/* Delete Confirmation Modal */}
      {deleteConfirm && (
        <ConfirmDialog
          title="Delete Video"
          description={`Are you sure you want to delete "${deleteConfirm.title || 'this video'}"? This action cannot be undone.`}
          confirmLabel="Delete"
          cancelLabel="Cancel"
          confirmVariant="danger"
          onCancel={() => setDeleteConfirm(null)}
          onConfirm={() => handleDeleteVideo(deleteConfirm._id)}
        />
      )}
    </div>
  );
};

// Shared create/edit form (`video` present => edit mode). Handles both a
// pasted URL and a picked file (mp4/webm/mov/m4v) with an upload progress
// bar, plus the new order/isPublished/durationSeconds fields.
const VideoFormModal = ({ title, submitLabel, video, onClose, onSave }) => {
  const [formData, setFormData] = useState({
    title: video?.title || '',
    description: video?.description || '',
    subject: video?.subject?._id || '',
    speaker: video?.speaker?._id || '',
    videoUrl: video?.video || '',
    videoFile: null,
    releaseDate: video?.releaseDate || '',
    order: video?.order ?? 0,
    isPublished: video?.isPublished !== false,
    durationSeconds: video?.durationSeconds || '',
    practiceEnabled: video?.practiceEnabled !== false,
    practiceTimerMode: video?.practiceTimerMode || 'none',
    practiceOverallTimeLimit: video?.practiceOverallTimeLimit || '',
    practicePerQuestionTimeLimit: video?.practicePerQuestionTimeLimit || '',
    practiceStartDate: video?.practiceStartDate || '',
    practiceEndDate: video?.practiceEndDate || '',
  });
  const [loading, setLoading] = useState(false);
  const [uploadProgress, setUploadProgress] = useState(0);
  useBodyScrollLock(true);

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!formData.videoFile && !formData.videoUrl) {
      alert('Provide a video URL or upload a video file.');
      return;
    }
    setLoading(true);
    setUploadProgress(0);
    try {
      await onSave(formData, (progressEvent) => {
        if (!progressEvent.total) return;
        setUploadProgress(Math.round((progressEvent.loaded * 100) / progressEvent.total));
      });
    } finally {
      setLoading(false);
      setUploadProgress(0);
    }
  };

  const handleFileChange = (e) => {
    const file = e.target.files?.[0];
    if (file) setFormData((prev) => ({ ...prev, videoFile: file, videoUrl: '' }));
  };

  const inputClass =
    'mt-2 block w-full rounded-2xl border border-white/10 bg-white/5 px-3.5 py-2.5 text-[13px] text-white placeholder-white/40 backdrop-blur-sm transition-all duration-200 focus:border-[#EFB078]/60 focus:outline-none focus:ring-0';

  return (
    <div className="fixed inset-0 z-[120] flex h-full w-full items-center justify-center overflow-y-auto bg-black/70 px-3 py-10 backdrop-blur-md sm:px-4">
      <div className="relative w-full max-w-md max-h-[90vh] overflow-y-auto rounded-3xl border border-white/12 bg-gradient-to-br from-[#100713]/92 via-[#190d23]/85 to-[#10060f]/92 shadow-[0_20px_56px_-26px_rgba(12,6,20,0.85)]">
        <div
          className="pointer-events-none absolute inset-0 rounded-3xl bg-[radial-gradient(circle_at_top_right,rgba(136,32,82,0.55),transparent_65%)]"
          aria-hidden="true"
        />

        <div className="relative px-6 pt-7 pb-6 sm:px-7 sm:pt-8 sm:pb-7">
          <div className="absolute left-6 top-5 flex h-10 w-10 items-center justify-center rounded-2xl border border-white/12 bg-black/60 shadow-[0_12px_30px_rgba(136,32,82,0.4)] sm:left-7">
            <img src={brandIcon} alt="QSpot icon" className="h-6 w-6 object-contain" />
          </div>

          <div className="flex flex-col gap-1.5 pl-[4.3rem] sm:pl-16">
            <p className="text-[10px] font-semibold uppercase tracking-[0.24em] text-[#f3c5a0]/70">Video</p>
            <h3 className="text-xl font-semibold tracking-wide text-white">{title}</h3>
          </div>

          <form onSubmit={handleSubmit} className="mt-6 space-y-4.5">
            <div>
              <label className="text-[11px] font-semibold uppercase tracking-[0.2em] text-white/65">Title *</label>
              <input
                type="text"
                value={formData.title}
                onChange={(e) => setFormData({ ...formData, title: e.target.value })}
                placeholder="Enter video title"
                className={inputClass}
                required
              />
            </div>

            <div>
              <label className="text-[11px] font-semibold uppercase tracking-[0.2em] text-white/65">Description</label>
              <textarea
                value={formData.description}
                onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                placeholder="Describe the video content (optional)"
                className={`${inputClass} min-h-[96px] resize-none`}
              />
            </div>

            <div className="grid gap-4 sm:grid-cols-2 items-start">
              <div>
                <label className="text-[11px] font-semibold uppercase tracking-[0.2em] text-white/65">Subject *</label>
                <SubjectSelect
                  value={formData.subject}
                  onChange={(subjectId) => setFormData({ ...formData, subject: subjectId })}
                  className="mt-2"
                  required
                />
              </div>
              <div>
                <label className="text-[11px] font-semibold uppercase tracking-[0.2em] text-white/65">Episode Order</label>
                <input
                  type="number"
                  value={formData.order}
                  onChange={(e) => setFormData({ ...formData, order: e.target.value })}
                  className={inputClass}
                  min="0"
                />
              </div>
            </div>

            <div>
              <label className="text-[11px] font-semibold uppercase tracking-[0.2em] text-white/65">Release Date</label>
              <DateTimePicker
                valueISO={formData.releaseDate}
                onChangeISO={(iso) => setFormData({ ...formData, releaseDate: iso })}
                className="mt-2"
              />
            </div>

            <div>
              <label className="text-[11px] font-semibold uppercase tracking-[0.2em] text-white/65">Faculty</label>
              <FacultySelect
                value={formData.speaker}
                onChange={(speakerId) => setFormData({ ...formData, speaker: speakerId })}
                includeAllOption
                allLabel="No faculty"
                className="mt-2"
              />
            </div>

            <div className="rounded-2xl border border-dashed border-white/15 bg-white/[0.03] p-4">
              <label className="text-[11px] font-semibold uppercase tracking-[0.2em] text-white/65">
                Video URL or upload
              </label>
              <input
                type="url"
                value={formData.videoUrl}
                onChange={(e) => setFormData({ ...formData, videoUrl: e.target.value, videoFile: null })}
                placeholder="https://example.com/video.mp4 or https://youtube.com/watch?v=..."
                className={inputClass}
              />
              <div className="mt-2 flex items-center gap-2">
                <div className="h-px flex-1 bg-white/10" />
                <span className="text-[10px] uppercase tracking-[0.2em] text-white/40">or</span>
                <div className="h-px flex-1 bg-white/10" />
              </div>
              <input
                type="file"
                accept={VIDEO_FILE_ACCEPT}
                onChange={handleFileChange}
                className="mt-2 block w-full text-[12px] text-white/70 file:mr-3 file:rounded-lg file:border-0 file:bg-gradient-to-r file:from-[#701845]/80 file:to-[#EFB078]/70 file:px-3 file:py-2 file:text-[11px] file:font-semibold file:uppercase file:tracking-wide file:text-white"
              />
              {formData.videoFile && (
                <p className="mt-2 text-[11px] text-emerald-300">{formData.videoFile.name} will be uploaded when you save.</p>
              )}
              {loading && formData.videoFile && (
                <div className="mt-3 h-2 w-full overflow-hidden rounded-full bg-white/10">
                  <div
                    className="h-full rounded-full bg-gradient-to-r from-[#701845] to-[#EFB078] transition-all"
                    style={{ width: `${uploadProgress}%` }}
                  />
                </div>
              )}
            </div>

            <div className="grid gap-4 sm:grid-cols-2 items-center">
              <div>
                <label className="text-[11px] font-semibold uppercase tracking-[0.2em] text-white/65">Duration (seconds)</label>
                <input
                  type="number"
                  value={formData.durationSeconds}
                  onChange={(e) => setFormData({ ...formData, durationSeconds: e.target.value })}
                  placeholder="Auto-detected on first watch if left blank"
                  className={inputClass}
                  min="0"
                />
              </div>
              <label className="mt-6 flex items-center gap-2.5 text-xs font-semibold uppercase tracking-[0.18em] text-white/65">
                <input
                  type="checkbox"
                  checked={formData.isPublished}
                  onChange={(e) => setFormData({ ...formData, isPublished: e.target.checked })}
                  className="h-4 w-4 accent-[#EFB078]"
                />
                Published
              </label>
            </div>

            <div className="rounded-2xl border border-[#EFB078]/20 bg-[#EFB078]/5 p-4">
              <p className="text-[11px] font-semibold uppercase tracking-[0.2em] text-[#f3c5a0]">Episode practice settings</p>
              <div className="mt-3 grid gap-4 sm:grid-cols-2">
                <label className="block text-[11px] font-semibold uppercase tracking-[0.18em] text-white/65 sm:col-span-2">
                  Timer mode
                  <select value={formData.practiceTimerMode} onChange={(e) => setFormData({ ...formData, practiceTimerMode: e.target.value })} className={inputClass}>
                    <option value="none">No timer</option>
                    <option value="overall">Overall timer</option>
                    <option value="per-question">Timer per question</option>
                    <option value="both">Overall + per question</option>
                  </select>
                </label>
                <label className="block text-[11px] font-semibold uppercase tracking-[0.18em] text-white/65">
                  Overall seconds
                  <input type="number" min="1" value={formData.practiceOverallTimeLimit} onChange={(e) => setFormData({ ...formData, practiceOverallTimeLimit: e.target.value })} className={inputClass} placeholder="Optional" />
                </label>
                <label className="block text-[11px] font-semibold uppercase tracking-[0.18em] text-white/65">
                  Per-question seconds
                  <input type="number" min="1" value={formData.practicePerQuestionTimeLimit} onChange={(e) => setFormData({ ...formData, practicePerQuestionTimeLimit: e.target.value })} className={inputClass} placeholder="Optional" />
                </label>
                <label className="block text-[11px] font-semibold uppercase tracking-[0.18em] text-white/65">
                  Active from
                  <DateTimePicker valueISO={formData.practiceStartDate} onChangeISO={(iso) => setFormData({ ...formData, practiceStartDate: iso })} className="mt-2" />
                </label>
                <label className="block text-[11px] font-semibold uppercase tracking-[0.18em] text-white/65">
                  Active until
                  <DateTimePicker valueISO={formData.practiceEndDate} onChangeISO={(iso) => setFormData({ ...formData, practiceEndDate: iso })} className="mt-2" />
                </label>
              </div>
              <label className="mt-3 flex items-center gap-2.5 text-xs font-semibold uppercase tracking-[0.18em] text-white/65">
                <input type="checkbox" checked={formData.practiceEnabled} onChange={(e) => setFormData({ ...formData, practiceEnabled: e.target.checked })} className="h-4 w-4 accent-[#EFB078]" />
                Practice active
              </label>
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
                className="rounded-lg bg-gradient-to-r from-[#701845]/90 via-[#9E4B63]/80 to-[#EFB078]/85 px-4.5 py-2 text-[11px] font-semibold uppercase tracking-[0.18em] text-white shadow-[0_12px_26px_rgba(136,32,82,0.45)] transition-all duration-200 hover:scale-[1.01] disabled:opacity-50 disabled:shadow-none"
              >
                {loading ? (formData.videoFile ? `Uploading… ${uploadProgress}%` : 'Saving...') : submitLabel}
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
};

export default VideosPage;
