import { FiChevronLeft, FiChevronRight } from 'react-icons/fi';

// Shared pagination control. Works for both server-side (page/total/limit)
// and any list that already knows totalPages — pass either `totalPages`
// directly or `total` + `limit`.
const Pagination = ({ page, totalPages, total, limit, onChange, label = 'items' }) => {
  const resolvedTotalPages = totalPages ?? Math.max(1, Math.ceil((total || 0) / (limit || 1)));
  if (resolvedTotalPages <= 1) return null;

  const pages = [];
  for (let p = 1; p <= resolvedTotalPages; p += 1) {
    if (p === 1 || p === resolvedTotalPages || Math.abs(p - page) <= 1) {
      pages.push(p);
    } else if (pages[pages.length - 1] !== '...') {
      pages.push('...');
    }
  }

  return (
    <div className="flex flex-col gap-3 border-t border-white/5 px-1 py-4 sm:flex-row sm:items-center sm:justify-between">
      {typeof total === 'number' && (
        <div className="text-sm text-gray-400">
          Page {page} of {resolvedTotalPages} &middot; {total} {label}
        </div>
      )}
      <div className="flex items-center gap-2 overflow-x-auto">
        <button
          onClick={() => onChange(page - 1)}
          disabled={page <= 1}
          className="flex h-9 w-9 shrink-0 items-center justify-center rounded-xl border border-white/10 bg-white/5 text-slate-300 transition-all hover:border-[#701845]/50 hover:text-white disabled:cursor-not-allowed disabled:opacity-50"
        >
          <FiChevronLeft size={16} />
        </button>
        {pages.map((p, idx) =>
          p === '...' ? (
            <span key={`ellipsis-${idx}`} className="px-1 text-gray-500">
              …
            </span>
          ) : (
            <button
              key={p}
              onClick={() => onChange(p)}
              className={`flex h-9 w-9 shrink-0 items-center justify-center rounded-xl text-sm font-semibold transition-all ${
                page === p
                  ? 'bg-gradient-to-r from-[#701845]/90 to-[#EFB078]/80 text-white'
                  : 'border border-white/10 bg-white/5 text-slate-300 hover:border-[#701845]/50 hover:text-white'
              }`}
            >
              {p}
            </button>
          )
        )}
        <button
          onClick={() => onChange(page + 1)}
          disabled={page >= resolvedTotalPages}
          className="flex h-9 w-9 shrink-0 items-center justify-center rounded-xl border border-white/10 bg-white/5 text-slate-300 transition-all hover:border-[#701845]/50 hover:text-white disabled:cursor-not-allowed disabled:opacity-50"
        >
          <FiChevronRight size={16} />
        </button>
      </div>
    </div>
  );
};

export default Pagination;
