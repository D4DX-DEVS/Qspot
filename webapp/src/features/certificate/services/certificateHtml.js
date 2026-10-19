// Full printable page for one certificate: the admin panel's layout
// (Qspot-admin/src/utils/certificateHtml.js), filled from the student's
// certificate model. `print-color-adjust: exact` keeps the paper tint when
// printed, even with "Background graphics" off.
const escapeHtml = (value) =>
  String(value ?? '')
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#039;')

const STYLE = `@page{size:A4 landscape;margin:0}*{box-sizing:border-box;-webkit-print-color-adjust:exact;print-color-adjust:exact}@media screen{html,body{overflow:hidden}}body{margin:0;background:#f7f1eb;color:#1c1220;font-family:Georgia,serif}.sheet{width:297mm;height:210mm;padding:18mm;display:grid;place-items:center}.certificate{width:100%;height:100%;border:3px solid #701845;padding:12mm;display:flex;flex-direction:column;align-items:center;justify-content:center;text-align:center;position:relative;background:linear-gradient(135deg,#fffaf6,#f8e9ee)}.certificate:before{content:'';position:absolute;inset:7mm;border:1px solid #e0ae73;pointer-events:none}.eyebrow{letter-spacing:.35em;text-transform:uppercase;color:#701845;font-size:12px}.title{font-size:38px;color:#701845;margin:14px 0 8px}.student{font-size:42px;font-weight:bold;color:#111827;margin:12px 0}.description{max-width:620px;font-size:18px;line-height:1.5;color:#4b4350}.meta{margin-top:28px;display:flex;gap:70px;color:#5c5360;font-size:14px}.signature{margin-top:28px;min-width:180px;border-top:1px solid #701845;padding-top:8px;font-size:14px}.number{position:absolute;bottom:12mm;font:12px Arial;color:#6b6270}`

export function certificateHtml(c) {
  const issued = c.issuedLabel
    ? `<span>Issued<br><strong>${escapeHtml(c.issuedLabel)}</strong></span>`
    : ''
  return `<!doctype html><html><head><meta charset="utf-8"><title>${escapeHtml(c.certificateNumber)}</title><style>${STYLE}</style></head><body><main class="sheet"><section class="certificate"><div class="eyebrow">${escapeHtml(c.issuerName)}</div><h1 class="title">${escapeHtml(c.title)}</h1><div>This certificate is proudly presented to</div><div class="student">${escapeHtml(c.studentName)}</div><div class="description">${escapeHtml(c.description)}<br><strong>${escapeHtml(c.examTitle)}</strong></div><div class="meta"><span>Score<br><strong>${escapeHtml(c.percentageLabel)}</strong></span>${issued}</div><div class="signature">${escapeHtml(c.signatoryName)}</div><div class="number">Certificate No. ${escapeHtml(c.certificateNumber)}</div></section></main></body></html>`
}
