import { formatDateTime } from './format';

// A4 landscape (297mm x 210mm) in CSS pixels, the size the certificate page
// renders at before it is scaled to fit the viewer.
export const CERTIFICATE_PAGE_WIDTH = 1123;
export const CERTIFICATE_PAGE_HEIGHT = 794;

const escapeHtml = (value) => String(value ?? '')
  .replaceAll('&', '&amp;')
  .replaceAll('<', '&lt;')
  .replaceAll('>', '&gt;')
  .replaceAll('"', '&quot;')
  .replaceAll("'", '&#039;');

// Full printable page for one issued certificate. Text comes from the
// certificate's snapshot, so later edits to the exam never change it.
// `print-color-adjust: exact` keeps the paper tint when printed, even with
// the browser's "Background graphics" option off.
export const certificateHtml = (certificate) => {
  const snapshot = certificate.snapshot || {};
  const student = certificate.student || {};
  return `<!doctype html><html><head><meta charset="utf-8"><title>${escapeHtml(certificate.certificateNumber)}</title><style>
    @page{size:A4 landscape;margin:0}*{box-sizing:border-box;-webkit-print-color-adjust:exact;print-color-adjust:exact}@media screen{html,body{overflow:hidden}}body{margin:0;background:#f7f1eb;color:#1c1220;font-family:Georgia,serif}.sheet{width:297mm;height:210mm;padding:18mm;display:grid;place-items:center}.certificate{width:100%;height:100%;border:3px solid #701845;padding:12mm;display:flex;flex-direction:column;align-items:center;justify-content:center;text-align:center;position:relative;background:linear-gradient(135deg,#fffaf6,#f8e9ee)}.certificate:before{content:'';position:absolute;inset:7mm;border:1px solid #e0ae73;pointer-events:none}.eyebrow{letter-spacing:.35em;text-transform:uppercase;color:#701845;font-size:12px}.title{font-size:38px;color:#701845;margin:14px 0 8px}.student{font-size:42px;font-weight:bold;color:#111827;margin:12px 0}.description{max-width:620px;font-size:18px;line-height:1.5;color:#4b4350}.meta{margin-top:28px;display:flex;gap:70px;color:#5c5360;font-size:14px}.signature{margin-top:28px;min-width:180px;border-top:1px solid #701845;padding-top:8px;font-size:14px}.number{position:absolute;bottom:12mm;font:12px Arial;color:#6b6270}</style></head><body><main class="sheet"><section class="certificate"><div class="eyebrow">${escapeHtml(snapshot.issuerName || 'QSPOT LEARNING')}</div><h1 class="title">${escapeHtml(snapshot.title || 'Certificate of Achievement')}</h1><div>This certificate is proudly presented to</div><div class="student">${escapeHtml(student.name || 'Student')}</div><div class="description">${escapeHtml(snapshot.description || 'For successfully completing the examination.')}<br><strong>${escapeHtml(snapshot.examTitle || 'Examination')}</strong></div><div class="meta"><span>Score<br><strong>${escapeHtml(certificate.percentage)}%</strong></span><span>Issued<br><strong>${escapeHtml(formatDateTime(certificate.issuedAt))}</strong></span></div><div class="signature">${escapeHtml(snapshot.signatoryName || 'Authorized Signatory')}</div><div class="number">Certificate No. ${escapeHtml(certificate.certificateNumber)}</div></section></main></body></html>`;
};
