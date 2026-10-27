// A4 landscape (297mm x 210mm) in CSS pixels, the size the certificate page
// renders at before it is scaled to fit the viewer.
export const CERTIFICATE_PAGE_WIDTH = 1123;
export const CERTIFICATE_PAGE_HEIGHT = 794;

// The certificate design (EXAM CERTIFICATE_QSPOT.pdf) as one A4 landscape
// picture, and where the filled-in parts sit on it, in points on the
// 842 x 595 page. Keep these the same as the web app's
// (webapp/src/features/certificate/models/certificateLayout.js) and the
// app's (mobile-app/lib/screens/certificate/widgets/certificate_sheet.dart).
const TEMPLATE = '/certificate/participation.jpg';
// The name stands centred on the blank line, its last line 6pt above it.
const NAME_BOX = { left: 336.8, width: 452.6, bottom: 301 };
// The small certificate number and date line, bottom left of the text side.
const DETAILS_BOX = { left: 336.8, bottom: 20 };

const escapeHtml = (value) => String(value ?? '')
  .replaceAll('&', '&amp;')
  .replaceAll('<', '&lt;')
  .replaceAll('>', '&gt;')
  .replaceAll('"', '&quot;')
  .replaceAll("'", '&#039;');

// Point size of the name: 26, smaller for long names so they stay on the
// line (a very long one may still wrap to a second line above it).
const nameFontSize = (name) => {
  const length = [...String(name ?? '')].length;
  if (length <= 22) return 26;
  return Math.max(17, Math.round(((26 * 22) / length) * 10) / 10);
};

// "21 October 2026", or empty when the date is missing.
const issuedLabel = (value) => {
  const date = value ? new Date(value) : null;
  if (!date || Number.isNaN(date.getTime())) return '';
  return date.toLocaleDateString('en-GB', { day: 'numeric', month: 'long', year: 'numeric' });
};

const STYLE = `@font-face{font-family:Manrope;font-weight:700;src:url('/fonts/Manrope-Bold.ttf') format('truetype')}@font-face{font-family:Manrope;font-weight:400;src:url('/fonts/Manrope-Regular.ttf') format('truetype')}@page{size:A4 landscape;margin:0}*{box-sizing:border-box;margin:0;-webkit-print-color-adjust:exact;print-color-adjust:exact}@media screen{html,body{overflow:hidden}}body{background:#fff;font-family:Manrope,Arial,sans-serif}.sheet{position:relative;width:297mm;height:210mm;overflow:hidden}.sheet img{position:absolute;inset:0;width:100%;height:100%}.name{position:absolute;left:${NAME_BOX.left}pt;width:${NAME_BOX.width}pt;bottom:${NAME_BOX.bottom}pt;text-align:center;font-weight:700;line-height:1.15;color:#000}.details{position:absolute;left:${DETAILS_BOX.left}pt;bottom:${DETAILS_BOX.bottom}pt;font-size:7.5pt;white-space:nowrap;color:#6b6270}`;

// Full printable page for one issued certificate: the design as a picture
// with the student's name on its line and the certificate number and issue
// date small at the foot. `print-color-adjust: exact` keeps the picture's
// colours when printed, even with the browser's "Background graphics"
// option off.
export const certificateHtml = (certificate) => {
  const name = certificate.student?.name || 'Student';
  const issued = issuedLabel(certificate.issuedAt);
  const details = [`Certificate No. ${certificate.certificateNumber}`, issued ? `Issued ${issued}` : '']
    .filter(Boolean)
    .join(' · ');
  return `<!doctype html><html><head><meta charset="utf-8"><title>${escapeHtml(certificate.certificateNumber)}</title><style>${STYLE}</style></head><body><main class="sheet"><img src="${TEMPLATE}" alt=""><p class="name" style="font-size:${nameFontSize(name)}pt">${escapeHtml(name)}</p><p class="details">${escapeHtml(details)}</p></main></body></html>`;
};
