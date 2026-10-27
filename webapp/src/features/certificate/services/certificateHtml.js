import { CERTIFICATE_TEMPLATE, DETAILS_BOX, NAME_BOX } from '../models/certificateLayout'

// Full printable page for one certificate: the design as an A4 landscape
// picture with the student's name on its line and the number and date at
// the foot, like the admin panel's print (Qspot-admin/src/utils/certificateHtml.js).
// `print-color-adjust: exact` keeps the picture's colours when printed, even
// with "Background graphics" off.
const escapeHtml = (value) =>
  String(value ?? '')
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#039;')

const STYLE = `@font-face{font-family:Manrope;font-weight:700;src:url('/fonts/Manrope-Bold.ttf') format('truetype')}@font-face{font-family:Manrope;font-weight:400;src:url('/fonts/Manrope-Regular.ttf') format('truetype')}@page{size:A4 landscape;margin:0}*{box-sizing:border-box;margin:0;-webkit-print-color-adjust:exact;print-color-adjust:exact}@media screen{html,body{overflow:hidden}}body{background:#fff;font-family:Manrope,Arial,sans-serif}.sheet{position:relative;width:297mm;height:210mm;overflow:hidden}.sheet img{position:absolute;inset:0;width:100%;height:100%}.name{position:absolute;left:${NAME_BOX.left}pt;width:${NAME_BOX.width}pt;bottom:${NAME_BOX.bottom}pt;text-align:center;font-weight:700;line-height:1.15;color:#000}.details{position:absolute;left:${DETAILS_BOX.left}pt;bottom:${DETAILS_BOX.bottom}pt;font-size:7.5pt;white-space:nowrap;color:#6b6270}`

export function certificateHtml(c) {
  return `<!doctype html><html><head><meta charset="utf-8"><title>${escapeHtml(c.certificateNumber)}</title><style>${STYLE}</style></head><body><main class="sheet"><img src="${CERTIFICATE_TEMPLATE}" alt=""><p class="name" style="font-size:${c.nameSize}pt">${escapeHtml(c.studentName)}</p><p class="details">${escapeHtml(c.detailsLabel)}</p></main></body></html>`
}
