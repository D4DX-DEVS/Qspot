import { useEffect, useRef } from 'react'
import CertificateSheet, { SHEET_HEIGHT, SHEET_WIDTH } from './CertificateSheet'

// The sheet scaled to fit the width it is given, with a soft brand shadow.
// [sheetRef] points at the full-size sheet, for the PDF.
export default function CertificatePreview({ certificate, sheetRef }) {
  const frame = useRef(null)
  useEffect(() => {
    const box = frame.current
    if (!box) return undefined
    const fit = () => box.style.setProperty('--qs-scale', String(box.clientWidth / SHEET_WIDTH))
    fit()
    const observer = new ResizeObserver(fit)
    observer.observe(box)
    return () => observer.disconnect()
  }, [])
  return (
    <div
      ref={frame}
      className="relative w-full overflow-hidden border border-line shadow-[0_6px_18px_color-mix(in_srgb,var(--qs-brand)_12%,transparent)]"
      style={{ aspectRatio: `${SHEET_WIDTH} / ${SHEET_HEIGHT}` }}
    >
      <div className="absolute left-0 top-0 origin-top-left" style={{ transform: 'scale(var(--qs-scale, 0.4))' }}>
        <CertificateSheet ref={sheetRef} certificate={certificate} />
      </div>
    </div>
  )
}
