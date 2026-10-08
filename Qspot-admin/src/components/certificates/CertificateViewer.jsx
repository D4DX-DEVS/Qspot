import { useEffect, useMemo, useRef, useState } from 'react';
import { FiPrinter } from 'react-icons/fi';
import Modal from '../ui/Modal';
import {
  CERTIFICATE_PAGE_HEIGHT,
  CERTIFICATE_PAGE_WIDTH,
  certificateHtml
} from '../../utils/certificateHtml';

// Shows an issued certificate inside the page, scaled to fit, and prints it
// from the same frame. No pop-up window is involved, so pop-up blockers
// cannot stop it.
const CertificateViewer = ({ certificate, onClose }) => {
  const frameRef = useRef(null);
  const boxRef = useRef(null);
  const [scale, setScale] = useState(0);
  const [loaded, setLoaded] = useState(false);
  const html = useMemo(() => certificateHtml(certificate), [certificate]);
  const revoked = certificate.status !== 'issued';

  // Fit the full-size A4 page to the modal's width, and refit on resize.
  useEffect(() => {
    const box = boxRef.current;
    if (!box) return undefined;
    const fit = () => setScale(box.clientWidth / CERTIFICATE_PAGE_WIDTH);
    fit();
    const observer = new ResizeObserver(fit);
    observer.observe(box);
    return () => observer.disconnect();
  }, []);

  const print = () => {
    const frameWindow = frameRef.current?.contentWindow;
    if (!frameWindow) return;
    frameWindow.focus();
    frameWindow.print();
  };

  return (
    <Modal
      title={certificate.student?.name || 'Certificate'}
      subtitle={certificate.certificateNumber}
      onClose={onClose}
      maxWidth="max-w-5xl"
    >
      {/* Width is capped by the window height too, so the whole page and
          the Print button fit without scrolling the modal (~190px is the
          modal header, padding and the action row). */}
      <div
        ref={boxRef}
        className="relative mx-auto w-full overflow-hidden rounded-xl border border-white/10 bg-[#f7f1eb]"
        style={{
          height: CERTIFICATE_PAGE_HEIGHT * scale,
          maxWidth: `calc((90vh - 190px) * ${CERTIFICATE_PAGE_WIDTH / CERTIFICATE_PAGE_HEIGHT})`
        }}
      >
        <iframe
          ref={frameRef}
          title={`Certificate ${certificate.certificateNumber}`}
          srcDoc={html}
          onLoad={() => setLoaded(true)}
          className="absolute left-0 top-0 origin-top-left border-0"
          style={{
            width: CERTIFICATE_PAGE_WIDTH,
            height: CERTIFICATE_PAGE_HEIGHT,
            transform: `scale(${scale})`
          }}
        />
      </div>
      <div className="mt-4 flex flex-col-reverse gap-3 sm:flex-row sm:items-center sm:justify-between">
        <p className="text-xs text-white/50">
          {revoked
            ? 'This certificate was revoked and can no longer be printed.'
            : 'To save a PDF, choose "Save as PDF" as the printer.'}
        </p>
        <button
          type="button"
          onClick={print}
          disabled={!loaded || revoked}
          className="inline-flex items-center justify-center gap-2 rounded-xl bg-gradient-to-r from-[#8C2852] via-[#B74A6D] to-[#F0B47F] px-4 py-2.5 text-sm font-semibold text-white shadow-[0_8px_20px_rgba(112,24,69,0.25)] disabled:cursor-not-allowed disabled:opacity-40"
        >
          <FiPrinter size={15} /> Print / Save as PDF
        </button>
      </div>
    </Modal>
  );
};

export default CertificateViewer;
