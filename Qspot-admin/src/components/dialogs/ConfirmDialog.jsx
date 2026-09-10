import React, { useEffect } from 'react';
import brandIcon from '../../assets/Icon.png';

const ConfirmDialog = ({
  iconSrc,
  iconAlt = '',
  title,
  description,
  confirmLabel = 'Confirm',
  cancelLabel = 'Cancel',
  onConfirm,
  onCancel,
  confirmVariant = 'primary'
}) => {
  const confirmGradient =
    confirmVariant === 'danger'
      ? 'from-[#b91c1c]/95 via-[#ef4444]/85 to-[#f97316]/80'
      : 'from-[#701845]/90 via-[#9E4B63]/80 to-[#EFB078]/85';

  const dialogIcon = iconSrc || brandIcon;
  const dialogIconAlt = iconAlt || 'QSpot icon';

  useEffect(() => {
    const previousOverflow = document.body.style.overflow;
    document.body.style.overflow = 'hidden';

    return () => {
      document.body.style.overflow = previousOverflow;
    };
  }, []);

  return (
    <div
      className="fixed inset-0 z-[120] flex items-center justify-center bg-black/70 px-4 py-6 backdrop-blur-md"
      role="dialog"
      aria-modal="true"
      aria-labelledby="confirm-dialog-title"
    >
      <div className="relative w-full max-w-sm overflow-hidden rounded-3xl border border-white/12 bg-gradient-to-br from-[#11060d]/95 via-[#1c0b18]/85 to-[#12060f]/95 shadow-[0_25px_70px_-25px_rgba(12,6,20,0.9)]">
        <div
          className="pointer-events-none absolute inset-0 bg-[radial-gradient(circle_at_top_left,rgba(136,32,82,0.55),transparent_60%)]"
          aria-hidden="true"
        />

        <div className="relative px-6 pt-6 pb-6">
          <div className="flex items-center gap-4 mb-6">
            <div className="flex h-12 w-12 flex-shrink-0 items-center justify-center rounded-2xl border border-white/12 bg-black/65 shadow-[0_14px_36px_rgba(136,32,82,0.45)]">
              <img src={dialogIcon} alt={dialogIconAlt} className="h-7 w-7 object-contain" />
            </div>
            <h3 id="confirm-dialog-title" className="text-lg font-semibold tracking-wide text-white">
              {title}
            </h3>
          </div>
          
          <div className="flex items-start justify-between gap-4">
            <div>
              <p className="text-sm leading-relaxed text-white/70">{description}</p>
            </div>
            <span className="mt-1 inline-flex h-1.5 w-1.5 shrink-0 rounded-full bg-gradient-to-r from-[#701845] to-[#EFB078]" />
          </div>

          <div className="mt-8 flex items-center justify-end gap-3">
            <button
              type="button"
              onClick={onCancel}
              className="rounded-lg border border-white/10 bg-white/5 px-4 py-2 text-xs font-semibold uppercase tracking-[0.18em] text-white/75 transition-all duration-200 hover:border-white/25 hover:bg-white/10 hover:text-white focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-white/40"
            >
              {cancelLabel}
            </button>
            <button
              type="button"
              onClick={onConfirm}
              className={`rounded-lg bg-gradient-to-r ${confirmGradient} px-4 py-2 text-xs font-semibold uppercase tracking-[0.18em] text-white shadow-[0_16px_38px_rgba(136,32,82,0.45)] transition-transform duration-200 hover:scale-[1.02] focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#EFB078]/70`}
            >
              {confirmLabel}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default ConfirmDialog;


