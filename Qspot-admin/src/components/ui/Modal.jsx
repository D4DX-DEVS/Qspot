import { FiX } from 'react-icons/fi';
import useBodyScrollLock from '../../hooks/useBodyScrollLock';
import brandIcon from '../../assets/Icon.png';

// Shared modal shell used by every page's create/edit dialog. Locks body
// scroll, closes on backdrop click, and gives a consistent header/close
// button so every "Add X" / "Edit X" form looks the same.
const Modal = ({ title, subtitle, icon, onClose, children, maxWidth = 'max-w-lg' }) => {
  useBodyScrollLock(true);

  return (
    <div className="fixed inset-0 z-[120] flex items-center justify-center overflow-y-auto bg-black/70 px-4 py-8 backdrop-blur-md">
      <div
        className="absolute inset-0"
        onClick={onClose}
        aria-hidden="true"
      />
      <div
        className={`relative z-10 w-full ${maxWidth} max-h-[90vh] overflow-y-auto rounded-3xl border border-white/12 bg-gradient-to-br from-[#100713]/95 via-[#190d23]/85 to-[#10060f]/95 shadow-[0_28px_80px_-28px_rgba(12,6,20,0.92)]`}
        onClick={(e) => e.stopPropagation()}
      >
        <div className="relative flex items-start justify-between gap-4 border-b border-white/10 px-5 py-4 sm:px-6">
          <div className="flex items-center gap-3">
            <div className="flex h-10 w-10 flex-shrink-0 items-center justify-center rounded-xl border border-white/12 bg-black/50 shadow-[0_10px_28px_rgba(136,32,82,0.4)]">
              <img src={icon || brandIcon} alt="" className="h-6 w-6 object-contain" />
            </div>
            <div>
              {subtitle && (
                <p className="text-[11px] font-semibold uppercase tracking-[0.22em] text-white/50">{subtitle}</p>
              )}
              <h3 className="mt-0.5 text-lg font-semibold text-white">{title}</h3>
            </div>
          </div>
          <button
            type="button"
            onClick={onClose}
            aria-label="Close"
            className="flex h-9 w-9 flex-shrink-0 items-center justify-center rounded-xl border border-white/10 bg-white/5 text-white/75 transition-all hover:border-white/25 hover:bg-white/10 hover:text-white"
          >
            <FiX size={18} />
          </button>
        </div>
        <div className="px-5 py-5 sm:px-6">{children}</div>
      </div>
    </div>
  );
};

export default Modal;
