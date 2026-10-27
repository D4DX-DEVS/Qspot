import { useEffect, useRef } from 'react'
import { Maximize2, Minimize2 } from 'lucide-react'
import CertificateSheet, { SHEET_HEIGHT, SHEET_WIDTH } from './CertificateSheet'

// The sheet scaled to fit the width it is given, with a soft brand shadow.
// On a phone the fitted text is tiny, so a button shows it full size to
// scroll around ([zoomed]), the way the app allows pinch-zoom.
export default function CertificatePreview({ certificate, zoomed, onToggleZoom }) {
  const frame = useRef(null)
  const full = useRef(null)
  // Opened full size: start in the middle, where the name is.
  useEffect(() => {
    const box = full.current
    if (zoomed && box) box.scrollTo({ left: (box.scrollWidth - box.clientWidth) / 2, top: (box.scrollHeight - box.clientHeight) / 2 })
  }, [zoomed])
  useEffect(() => {
    const box = frame.current
    if (!box || zoomed) return undefined
    const fit = () => box.style.setProperty('--qs-scale', String(box.clientWidth / SHEET_WIDTH))
    fit()
    const observer = new ResizeObserver(fit)
    observer.observe(box)
    return () => observer.disconnect()
  }, [zoomed])

  const ZoomIcon = zoomed ? Minimize2 : Maximize2
  return (
    <div className="relative w-full">
      {zoomed ? (
        <div ref={full} className="max-h-[70dvh] w-full overflow-auto border border-line" tabIndex={0} aria-label="Certificate at full size">
          <CertificateSheet certificate={certificate} />
        </div>
      ) : (
        <div
          ref={frame}
          className="relative w-full overflow-hidden border border-line shadow-[0_6px_18px_color-mix(in_srgb,var(--qs-brand)_12%,transparent)]"
          style={{ aspectRatio: `${SHEET_WIDTH} / ${SHEET_HEIGHT}` }}
        >
          <div className="absolute left-0 top-0 origin-top-left" style={{ transform: 'scale(var(--qs-scale, 0.4))' }}>
            <CertificateSheet certificate={certificate} />
          </div>
        </div>
      )}
      <button
        type="button"
        onClick={onToggleZoom}
        className="qs-press absolute bottom-2 right-2 inline-flex min-h-11 items-center gap-1.5 rounded-full bg-card/95 px-3.5 text-[13px] font-semibold text-brand shadow-md md:hidden"
      >
        <ZoomIcon size={16} aria-hidden="true" />
        {zoomed ? 'Fit to Screen' : 'Zoom In'}
      </button>
    </div>
  )
}
