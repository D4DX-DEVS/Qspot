import React, { useState, useEffect, useCallback, useMemo, useRef } from 'react';
import axios from 'axios';
import { FiEdit2, FiTrash2, FiPlus, FiSearch, FiChevronLeft, FiChevronRight, FiPlay, FiCalendar, FiBookOpen, FiChevronDown } from 'react-icons/fi';
import Sidebar from '../components/Sidebar';
import ConfirmDialog from '../components/dialogs/ConfirmDialog';
import brandIcon from '../assets/Icon.png';

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

// Helper function to generate YouTube thumbnail URL with quality fallback
const getYouTubeThumbnail = (url) => {
  const videoId = getYouTubeVideoId(url);
  if (!videoId) return null;
  
  // Try maxresdefault first (best quality), then fallback to hqdefault (always available)
  return `https://img.youtube.com/vi/${videoId}/maxresdefault.jpg`;
};

// Helper function to get fallback thumbnail (hqdefault is always available)
const getYouTubeThumbnailFallback = (url) => {
  const videoId = getYouTubeVideoId(url);
  if (!videoId) return null;
  return `https://img.youtube.com/vi/${videoId}/hqdefault.jpg`;
};

// Helper function to get sddefault thumbnail (medium quality)
const getYouTubeThumbnailSD = (url) => {
  const videoId = getYouTubeVideoId(url);
  if (!videoId) return null;
  return `https://img.youtube.com/vi/${videoId}/sddefault.jpg`;
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

  const handleError = (e) => {
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

const ensureDropdownStyle = () => {
  if (typeof document === 'undefined') return;
  const styleId = 'qspot-dropdown-style';
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

const SubjectSelect = ({
  subjects,
  value,
  onChange,
  placeholder = 'Select a subject',
  includeAllOption = false,
  allLabel = 'All Subjects'
}) => {
  useEffect(() => {
    ensureDropdownStyle();
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

  const selectedSubject = useMemo(
    () => (value ? subjects.find((subject) => subject._id === value) : undefined),
    [subjects, value],
  );

  const displayLabel = selectedSubject
    ? selectedSubject.name
    : includeAllOption && !value
    ? allLabel
    : placeholder;

  const isActive = Boolean(selectedSubject) || (includeAllOption && !value);

  return (
    <div ref={containerRef} className="relative">
      <button
        type="button"
        onClick={() => setOpen((prev) => !prev)}
        className="flex w-full items-center justify-between rounded-2xl border border-white/12 bg-gradient-to-br from-[#11060d]/70 via-[#1c0b18]/55 to-[#12060f]/70 px-3 py-2.5 text-left text-[13px] text-white shadow-[0_6px_18px_rgba(112,24,69,0.25)] transition-all duration-200 hover:border-[#EFB078]/40 focus:outline-none focus-visible:border-[#EFB078]/60"
      >
        <span className={isActive ? 'text-white' : 'text-white/55'}>{displayLabel}</span>
        <FiChevronDown
          size={14}
          className={`ml-3 shrink-0 transition-transform ${
            open ? 'rotate-180 text-[#EFB078]' : 'text-white/60'
          }`}
        />
      </button>

      {open && (
        <div className="absolute left-0 z-[180] mt-2 w-full min-w-[220px] overflow-hidden rounded-2xl border border-white/12 bg-gradient-to-br from-[#11060d]/95 via-[#1c0b18]/85 to-[#12060f]/95 shadow-[0_24px_58px_-24px_rgba(112,24,69,0.55)] backdrop-blur-xl sm:w-[260px]">
          <div className="max-h-60 overflow-y-auto pr-1 qspot-no-scrollbar">
            {includeAllOption && (
              <button
                type="button"
                onClick={() => {
                  onChange('');
                  setOpen(false);
                }}
                className={`flex w-full items-center justify-between px-4 py-2.5 text-left text-[13px] transition-all duration-150 ${
                  !value
                    ? 'bg-gradient-to-r from-[#701845]/70 to-[#EFB078]/35 text-white shadow-[0_12px_28px_rgba(112,24,69,0.35)]'
                    : 'text-white/80 hover:bg-white/10 hover:text-white'
                }`}
              >
                <span>{allLabel}</span>
              </button>
            )}
            {subjects.length === 0 ? (
              <div className="px-4 py-3 text-sm text-white/65">No subjects available</div>
            ) : (
              subjects.map((subject) => {
                const isSelected = subject._id === value;
                return (
                  <button
                    key={subject._id}
                    type="button"
                    onClick={() => {
                      onChange(subject._id);
                      setOpen(false);
                    }}
                    className={`flex w-full items-center justify-between px-4 py-2.5 text-left text-[13px] transition-all duration-150 ${
                      isSelected
                        ? 'bg-gradient-to-r from-[#701845]/70 to-[#EFB078]/35 text-white shadow-[0_12px_28px_rgba(112,24,69,0.35)]'
                        : 'text-white/85 hover:bg-white/10 hover:text-white'
                    }`}
                  >
                    <span>{subject.name}</span>
                  </button>
                );
              })
            )}
          </div>
        </div>
      )}
    </div>
  );
};

const weekDays = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];

const padNumber = (num) => String(num).padStart(2, '0');

const formatDateLabel = (value) => {
  if (!value) return 'mm/dd/yyyy';
  const date = new Date(`${value}T00:00:00`);
  if (Number.isNaN(date.getTime())) return 'mm/dd/yyyy';
  return date.toLocaleDateString(undefined, {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
  });
};

const VideoDatePicker = ({ value, onChange }) => {
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

  const firstDayOfMonth = useMemo(
    () => new Date(viewDate.getFullYear(), viewDate.getMonth(), 1).getDay(),
    [viewDate],
  );

  const isSameDate = (dateA, dateB) => {
    if (!dateA || !dateB) return false;
    return (
      dateA.getFullYear() === dateB.getFullYear() &&
      dateA.getMonth() === dateB.getMonth() &&
      dateA.getDate() === dateB.getDate()
    );
  };

  const handleDaySelect = (day) => {
    const picked = new Date(viewDate.getFullYear(), viewDate.getMonth(), day);
    const formatted = `${picked.getFullYear()}-${padNumber(picked.getMonth() + 1)}-${padNumber(
      picked.getDate(),
    )}`;
    onChange(formatted);
    setOpen(false);
  };

  const goToMonth = (offset) => {
    setViewDate((prev) => {
      const next = new Date(prev);
      next.setMonth(prev.getMonth() + offset);
      return next;
    });
  };

  return (
    <div ref={containerRef} className="relative">
      <button
        type="button"
        onClick={() => setOpen((prev) => !prev)}
        className="flex w-full items-center justify-between rounded-2xl border border-white/12 bg-gradient-to-br from-[#11060d]/70 via-[#1c0b18]/55 to-[#12060f]/70 px-3 py-2.5 text-left text-[13px] text-white shadow-[0_6px_18px_rgba(112,24,69,0.25)] transition-all duration-200 hover:border-[#EFB078]/40 focus:outline-none focus-visible:border-[#EFB078]/60"
      >
        <span className={value ? 'text-white' : 'text-white/55'}>{formatDateLabel(value)}</span>
        <FiChevronDown
          size={14}
          className={`ml-3 shrink-0 transition-transform ${
            open ? 'rotate-180 text-[#EFB078]' : 'text-white/60'
          }`}
        />
      </button>

      {open && (
        <div className="absolute left-0 bottom-full z-[180] mb-2 w-full min-w-[200px] overflow-hidden rounded-2xl border border-white/12 bg-gradient-to-br from-[#11060d]/95 via-[#1c0b18]/85 to-[#12060f]/95 p-3.5 shadow-[0_20px_48px_-20px_rgba(112,24,69,0.5)] backdrop-blur-xl sm:w-[240px]">
          <div className="mb-2.5 flex items-center justify-between text-white/80">
            <button
              type="button"
              onClick={() => goToMonth(-1)}
              className="rounded-lg border border-white/10 bg-white/5 p-1.5 text-white/70 transition hover:text-white"
            >
              <FiChevronLeft size={14} />
            </button>
            <span className="text-sm font-semibold">
              {viewDate.toLocaleString(undefined, { month: 'long', year: 'numeric' })}
            </span>
            <button
              type="button"
              onClick={() => goToMonth(1)}
              className="rounded-lg border border-white/10 bg-white/5 p-1.5 text-white/70 transition hover:text-white"
            >
              <FiChevronRight size={14} />
            </button>
          </div>

          <div className="grid grid-cols-7 gap-0.5 text-center text-[10px] text-white/55">
            {weekDays.map((day) => (
              <span key={day} className="py-1 font-semibold uppercase tracking-[0.12em]">
                {day}
              </span>
            ))}
          </div>
          <div className="mt-1 grid grid-cols-7 gap-0.5 text-center text-[13px] text-white/80">
            {Array.from({ length: firstDayOfMonth }).map((_, index) => (
              <span key={`blank-${index}`} />
            ))}
            {Array.from({ length: daysInMonth }).map((_, index) => {
              const day = index + 1;
              const date = new Date(viewDate.getFullYear(), viewDate.getMonth(), day);
              const isSelected = selectedDate && isSameDate(date, selectedDate);
              const isToday = isSameDate(date, new Date());
              return (
                <button
                  key={day}
                  type="button"
                  onClick={() => handleDaySelect(day)}
                  className={`flex h-8 w-8 items-center justify-center rounded-lg transition-colors ${
                    isSelected
                      ? 'bg-gradient-to-r from-[#701845]/75 to-[#EFB078]/55 text-white shadow-[0_8px_22px_rgba(112,24,69,0.3)]'
                      : 'text-white/80 hover:bg-white/10 hover:text-white'
                  } ${isToday && !isSelected ? 'ring-1 ring-[#EFB078]/35' : ''}`}
                >
                  {day}
                </button>
              );
            })}
          </div>
          <div className="mt-3 flex items-center justify-between">
            <button
              type="button"
              onClick={() => {
                const today = new Date();
                const formatted = `${today.getFullYear()}-${padNumber(today.getMonth() + 1)}-${padNumber(
                  today.getDate(),
                )}`;
                onChange(formatted);
                setOpen(false);
              }}
              className="text-[11px] font-semibold uppercase tracking-[0.2em] text-[#EFB078] transition hover:text-white"
            >
              Today
            </button>
            <button
              type="button"
              onClick={() => {
                onChange('');
                setOpen(false);
              }}
              className="text-[11px] font-semibold uppercase tracking-[0.2em] text-white/60 transition hover:text-white"
            >
              Clear
            </button>
          </div>
        </div>
      )}
    </div>
  );
};

const VideoCard = ({ video, onEdit, onDelete }) => {
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
        <div className={isPortrait ? 'w-24 md:w-28 lg:w-32 flex-shrink-0' : 'w-full'}>
          <div className="rounded-xl bg-black/30 p-1.5">
            <VideoThumbnailPreview
              video={video}
              onOrientationChange={setOrientation}
              className=""
            />
          </div>
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
              {video.title}
            </h3>
            <span className="inline-flex min-h-[28px] items-center justify-start gap-2 rounded-full border border-[#EFB078]/30 bg-gradient-to-r from-[#701845]/30 to-[#EFB078]/20 px-3 py-1 text-[10px] font-semibold uppercase tracking-[0.14em] text-[#EFB078] shadow-[0_2px_8px_rgba(239,176,120,0.15)]">
              {video.subject?.name || 'Subject Pending'}
            </span>
          </div>
          <div
            className={`mt-auto flex gap-2 ${
              isPortrait
                ? 'flex-col items-stretch md:flex-row md:items-center md:justify-between'
                : 'items-center justify-start'
            }`}
          >
            <div className={`flex items-center gap-2 opacity-0 transition-all duration-200 group-hover:opacity-100 ${isPortrait ? 'md:ml-auto' : ''}`}>
              <button
                onClick={(e) => {
                  e.stopPropagation();
                  onEdit();
                }}
                className="flex items-center gap-1 rounded-xl bg-white/10 px-2.5 py-1.5 text-[10px] font-semibold text-white transition-all hover:bg-white/20"
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
                className="flex items-center gap-1 rounded-xl bg-red-500/20 px-2.5 py-1.5 text-[10px] font-semibold text-red-200 transition-all hover:bg-red-500/30"
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
  const [videos, setVideos] = useState([]);
  const [filteredVideos, setFilteredVideos] = useState([]);
  const [subjects, setSubjects] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [showEditModal, setShowEditModal] = useState(false);
  const [editingVideo, setEditingVideo] = useState(null);
  const [deleteConfirm, setDeleteConfirm] = useState(null);
  
  // Pagination and search states
  const [currentPage, setCurrentPage] = useState(1);
  const [searchTerm, setSearchTerm] = useState('');
  const [subjectFilter, setSubjectFilter] = useState('');
  const itemsPerPage = 12;

  useEffect(() => {
    fetchVideos();
    fetchSubjects();
  }, []);

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

    // Default sorting (newest first)
    filtered.sort((a, b) => {
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
      const baseURL = import.meta.env.VITE_API_BASE_URL;
      const response = await axios.get(`${baseURL}/videos`);
      setVideos(response.data || []);
    } catch (err) {
      console.error('Error fetching videos:', err);
      setError('Failed to fetch videos');
    } finally {
      setLoading(false);
    }
  };

  const fetchSubjects = async () => {
    try {
      const baseURL = import.meta.env.VITE_API_BASE_URL;
      const response = await axios.get(`${baseURL}/subjects`);
      setSubjects(response.data || []);
    } catch (err) {
      console.error('Error fetching subjects:', err);
    }
  };

  const handleCreateVideo = async (formData) => {
    try {
      const token = localStorage.getItem('adminToken');
      const baseURL = import.meta.env.VITE_API_BASE_URL;
      
      // Always send as JSON with video URL
      await axios.post(`${baseURL}/videos`, {
        title: formData.title,
        description: formData.description,
        subject: formData.subject,
        releaseDate: formData.releaseDate,
        video: formData.videoUrl
      }, {
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json'
        }
      });
      
      setShowCreateModal(false);
      fetchVideos();
    } catch (err) {
      console.error('Error creating video:', err);
      alert('Failed to create video');
    }
  };

  const handleEditVideo = (video) => {
    setEditingVideo(video);
    setShowEditModal(true);
  };

  const handleUpdateVideo = async (formData) => {
    try {
      const token = localStorage.getItem('adminToken');
      const baseURL = import.meta.env.VITE_API_BASE_URL;
      
      // Always send as JSON with video URL
      const updateData = {
        title: formData.title,
        description: formData.description,
        subject: formData.subject,
        releaseDate: formData.releaseDate,
        video: formData.videoUrl
      };
      
      await axios.put(`${baseURL}/videos/${editingVideo._id}`, updateData, {
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json'
        }
      });
      
      setShowEditModal(false);
      setEditingVideo(null);
      fetchVideos();
    } catch (err) {
      console.error('Error updating video:', err);
      alert('Failed to update video');
    }
  };

  const handleDeleteVideo = async (videoId) => {
    try {
      const token = localStorage.getItem('adminToken');
      const baseURL = import.meta.env.VITE_API_BASE_URL;
      
      await axios.delete(`${baseURL}/videos/${videoId}`, {
        headers: {
          'Authorization': `Bearer ${token}`
        }
      });
      
      setDeleteConfirm(null);
      fetchVideos();
    } catch (err) {
      console.error('Error deleting video:', err);
      alert('Failed to delete video');
    }
  };

  const handleNavigate = (path) => {
    window.location.href = path;
  };

  // Pagination logic
  const totalPages = Math.ceil(filteredVideos.length / itemsPerPage);
  const startIndex = (currentPage - 1) * itemsPerPage;
  const endIndex = startIndex + itemsPerPage;
  const currentVideos = filteredVideos.slice(startIndex, endIndex);

  const handlePageChange = (page) => {
    setCurrentPage(page);
  };

  // Statistics
  const totalVideos = videos.length;
  const recentVideos = videos.filter(v => {
    const videoDate = new Date(v.createdAt);
    const weekAgo = new Date();
    weekAgo.setDate(weekAgo.getDate() - 7);
    return videoDate > weekAgo;
  }).length;

  return (
    <div className="flex min-h-screen bg-black">
      <Sidebar currentPage="videos" onNavigate={handleNavigate} />
      
      <div className="flex-1 flex flex-col ml-64">
        <main className="flex-1 p-8">
          {/* Header Section */}
          <div className="mb-8">
            <div className="flex flex-col lg:flex-row lg:items-center lg:justify-between gap-4">
              <div>
                <h2 className="text-2xl font-semibold text-white">Videos Management</h2>
                <p className="text-sm text-gray-400">Manage educational videos and content across subjects.</p>
              </div>
              <div className="flex flex-wrap items-center gap-3">
                <div className="relative overflow-hidden rounded-2xl border border-white/12 bg-gradient-to-br from-[#140718]/88 via-[#1b0b20]/75 to-[#0b040d]/90 px-5 py-4 shadow-[0_18px_46px_-24px_rgba(112,24,69,0.5)] backdrop-blur-xl min-w-[180px]">
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
                <div className="relative overflow-hidden rounded-2xl border border-white/12 bg-gradient-to-br from-[#102319]/88 via-[#11291e]/75 to-[#05140c]/90 px-5 py-4 shadow-[0_18px_46px_-24px_rgba(12,142,96,0.5)] backdrop-blur-xl min-w-[180px]">
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
                    subjects={subjects}
                    value={subjectFilter}
                    onChange={(subjectId) => setSubjectFilter(subjectId)}
                    includeAllOption
                    allLabel="All Subjects"
                    placeholder="Filter by subject"
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
            <div className="flex justify-center items-center h-64">
              <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-400"></div>
            </div>
          ) : error ? (
            <div className="bg-red-900/20 border border-red-500/30 text-red-400 px-4 py-3 rounded-md">
              {error}
              <button 
                onClick={fetchVideos}
                className="ml-4 text-red-300 underline hover:text-red-200"
              >
                Retry
              </button>
            </div>
          ) : (
            <div className="space-y-3">
              {filteredVideos.length === 0 ? (
                <div className="text-center py-8">
                  <FiPlay className="mx-auto text-gray-500 mb-3" size={36} />
                  <p className="text-gray-400">
                    {searchTerm || subjectFilter ? 'No videos found matching your search' : 'No videos found'}
                  </p>
                  {(searchTerm || subjectFilter) && (
                    <button
                      onClick={() => {
                        setSearchTerm('');
                        setSubjectFilter('');
                      }}
                      className="mt-2 text-indigo-400 hover:text-indigo-300 transition-colors text-sm"
                    >
                      Clear filters
                    </button>
                  )}
                </div>
              ) : (
                <>
                  <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
                    {currentVideos.map((video) => (
                      <VideoCard
                        key={video._id}
                        video={video}
                        onEdit={() => handleEditVideo(video)}
                        onDelete={() => setDeleteConfirm(video)}
                      />
                    ))}
                  </div>

                  {/* Pagination */}
                  {totalPages > 1 && (
                    <div className="relative overflow-hidden rounded-2xl border border-white/10 bg-gradient-to-br from-[#11060d]/60 via-[#1c0b18]/40 to-[#12060f]/60 backdrop-blur-xl p-4 mt-4">
                      <div className="flex items-center justify-between">
                        <div className="text-xs text-gray-400">
                          Showing {startIndex + 1} to {Math.min(endIndex, filteredVideos.length)} of {filteredVideos.length} videos
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

      {/* Create Video Modal */}
      {showCreateModal && (
        <CreateVideoModal
          subjects={subjects}
          onClose={() => setShowCreateModal(false)}
          onSave={handleCreateVideo}
        />
      )}

      {/* Edit Video Modal */}
      {showEditModal && editingVideo && (
        <EditVideoModal
          video={editingVideo}
          subjects={subjects}
          onClose={() => {
            setShowEditModal(false);
            setEditingVideo(null);
          }}
          onSave={handleUpdateVideo}
        />
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

// Helper function to format date for date input (YYYY-MM-DD)
const formatDateForInput = (dateString) => {
  if (!dateString) return '';
  try {
    const date = new Date(dateString);
    if (isNaN(date.getTime())) return '';
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
  } catch (error) {
    return '';
  }
};

// Create Video Modal Component
const CreateVideoModal = ({ subjects, onClose, onSave }) => {
  const [formData, setFormData] = useState({
    title: '',
    description: '',
    subject: '',
    videoUrl: '',
    releaseDate: ''
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

  const inputClass =
    'mt-2 block w-full rounded-2xl border border-white/10 bg-white/5 px-3.5 py-2.5 text-[13px] text-white placeholder-white/40 backdrop-blur-sm transition-all duration-200 focus:border-[#EFB078]/60 focus:outline-none focus:ring-0';

  return (
    <div className="fixed inset-0 z-[120] flex h-full w-full items-center justify-center bg-black/70 px-3 py-10 backdrop-blur-md sm:px-4">
      <div className="relative w-full max-w-md overflow-visible rounded-3xl border border-white/12 bg-gradient-to-br from-[#100713]/92 via-[#190d23]/85 to-[#10060f]/92 shadow-[0_20px_56px_-26px_rgba(12,6,20,0.85)]">
        <div
          className="pointer-events-none absolute inset-0 rounded-3xl bg-[radial-gradient(circle_at_top_right,rgba(136,32,82,0.55),transparent_65%)]"
          aria-hidden="true"
        />

        <div className="relative px-6 pt-7 pb-6 sm:px-7 sm:pt-8 sm:pb-7">
          <div className="absolute left-6 top-5 flex h-10 w-10 items-center justify-center rounded-2xl border border-white/12 bg-black/60 shadow-[0_12px_30px_rgba(136,32,82,0.4)] sm:left-7">
            <img src={brandIcon} alt="QSpot icon" className="h-6 w-6 object-contain" />
          </div>

          <div className="flex flex-col gap-1.5 pl-[4.3rem] sm:pl-16">
            <p className="text-[10px] font-semibold uppercase tracking-[0.24em] text-[#f3c5a0]/70">
              Video
            </p>
            <h3 className="text-xl font-semibold tracking-wide text-white">Add New Video</h3>
            <p className="text-xs text-white/70">
              Provide the details below to publish a new learning video.
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
                placeholder="Enter video title"
                className={inputClass}
                required
              />
            </div>

            <div>
              <label className="text-[11px] font-semibold uppercase tracking-[0.2em] text-white/65">
                Description
              </label>
              <textarea
                value={formData.description}
                onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                placeholder="Describe the video content (optional)"
                className={`${inputClass} min-h-[96px] resize-none`}
              />
            </div>

            <div className="grid gap-4 sm:grid-cols-2 items-start">
              <div>
                <label className="text-[11px] font-semibold uppercase tracking-[0.2em] text-white/65">
                  Subject *
                </label>
                <SubjectSelect
                  subjects={subjects}
                  value={formData.subject}
                  onChange={(subjectId) => setFormData({ ...formData, subject: subjectId })}
                  placeholder="Select a subject"
                />
              </div>
              <div>
                <label className="text-[11px] font-semibold uppercase tracking-[0.2em] text-white/65">
                  Release Date
                </label>
                <VideoDatePicker
                  value={formData.releaseDate}
                  onChange={(nextDate) => setFormData({ ...formData, releaseDate: nextDate })}
                />
              </div>
            </div>

            <div>
              <label className="text-[11px] font-semibold uppercase tracking-[0.2em] text-white/65">
                Video URL *
              </label>
              <input
                type="url"
                value={formData.videoUrl}
                onChange={(e) => setFormData({ ...formData, videoUrl: e.target.value })}
                placeholder="https://example.com/video.mp4 or https://youtube.com/watch?v=..."
                className={inputClass}
                required
              />
              <p className="mt-1.5 text-[10px] text-white/60">
                Paste a direct video file link or a YouTube URL.
              </p>
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
                {loading ? 'Creating...' : 'Create Video'}
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
};

// Edit Video Modal Component
const EditVideoModal = ({ video, subjects, onClose, onSave }) => {
  const [formData, setFormData] = useState({
    title: video.title || '',
    description: video.description || '',
    subject: video.subject?._id || '',
    videoUrl: video.video || '',
    releaseDate: formatDateForInput(video.releaseDate) || ''
  });
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    const previousOverflow = document.body.style.overflow;
    document.body.style.overflow = 'hidden';
    return () => {
      document.body.style.overflow = previousOverflow;
    };
  }, []);

  const inputClass =
    'mt-2 block w-full rounded-2xl border border-white/10 bg-white/5 px-3.5 py-2.5 text-[13px] text-white placeholder-white/40 backdrop-blur-sm transition-all duration-200 focus:border-[#EFB078]/60 focus:outline-none focus:ring-0';

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
    <div className="fixed inset-0 z-[120] flex h-full w-full items-center justify-center bg-black/70 px-3 py-10 backdrop-blur-md sm:px-4">
      <div className="relative w-full max-w-md overflow-visible rounded-3xl border border-white/12 bg-gradient-to-br from-[#100713]/92 via-[#190d23]/85 to-[#10060f]/92 shadow-[0_20px_56px_-26px_rgba(12,6,20,0.85)]">
        <div
          className="pointer-events-none absolute inset-0 rounded-3xl bg-[radial-gradient(circle_at_top_right,rgba(136,32,82,0.55),transparent_65%)]"
          aria-hidden="true"
        />

        <div className="relative px-6 pt-7 pb-6 sm:px-7 sm:pt-8 sm:pb-7">
          <div className="absolute left-6 top-5 flex h-10 w-10 items-center justify-center rounded-2xl border border-white/12 bg-black/60 shadow-[0_12px_30px_rgba(136,32,82,0.4)] sm:left-7">
            <img src={brandIcon} alt="QSpot icon" className="h-6 w-6 object-contain" />
          </div>

          <div className="flex flex-col gap-1.5 pl-[4.3rem] sm:pl-16">
            <p className="text-[10px] font-semibold uppercase tracking-[0.24em] text-[#f3c5a0]/70">
              Video
            </p>
            <h3 className="text-xl font-semibold tracking-wide text-white">Edit Video</h3>
            <p className="text-xs text-white/70">
              Update the video information and confirm the shared link.
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
                placeholder="Enter video title"
                className={inputClass}
                required
              />
            </div>

            <div>
              <label className="text-[11px] font-semibold uppercase tracking-[0.2em] text-white/65">
                Description
              </label>
              <textarea
                value={formData.description}
                onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                placeholder="Describe the video content (optional)"
                className={`${inputClass} min-h-[96px] resize-none`}
              />
            </div>

            <div className="grid gap-4 sm:grid-cols-2 items-start">
              <div>
                <label className="text-[11px] font-semibold uppercase tracking-[0.2em] text-white/65">
                  Subject *
                </label>
                <SubjectSelect
                  subjects={subjects}
                  value={formData.subject}
                  onChange={(subjectId) => setFormData({ ...formData, subject: subjectId })}
                  placeholder="Select a subject"
                />
              </div>
              <div>
                <label className="text-[11px] font-semibold uppercase tracking-[0.2em] text-white/65">
                  Release Date
                </label>
                <VideoDatePicker
                  value={formData.releaseDate}
                  onChange={(nextDate) => setFormData({ ...formData, releaseDate: nextDate })}
                />
              </div>
            </div>

            <div>
              <label className="text-[11px] font-semibold uppercase tracking-[0.2em] text-white/65">
                Video URL *
              </label>
              <input
                type="url"
                value={formData.videoUrl}
                onChange={(e) => setFormData({ ...formData, videoUrl: e.target.value })}
                placeholder="https://example.com/video.mp4 or https://youtube.com/watch?v=..."
                className={inputClass}
                required
              />
              <p className="mt-1.5 text-[10px] text-white/60">
                Enter a direct link to a video file (MP4, WebM, etc.) or YouTube URL.
              </p>
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
                {loading ? 'Updating...' : 'Update Video'}
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
};

export default VideosPage;
