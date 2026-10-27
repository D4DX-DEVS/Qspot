// The certificate design (EXAM CERTIFICATE_QSPOT.pdf) as one A4 landscape
// picture, and where the filled-in parts sit on it, in points on the
// 842 x 595 page (measured from the design). Keep these the same as the
// admin panel's (Qspot-admin/src/utils/certificateHtml.js) and the app's
// (mobile-app/lib/screens/certificate/widgets/certificate_sheet.dart).
export const CERTIFICATE_TEMPLATE = '/certificate/participation.jpg'

// The name stands centred on the blank line (x 336.8..789.4, y 300.5), its
// last line 6pt above it; `bottom` is measured from the foot of the page.
export const NAME_BOX = { left: 336.8, width: 452.6, bottom: 301 }

// The small certificate number and date line, bottom left of the text side.
export const DETAILS_BOX = { left: 336.8, bottom: 20 }

const NAME_SIZE = 26
const NAME_MIN_SIZE = 17
const NAME_FULL_SIZE_CHARS = 22

// Point size of the name: 26, smaller for long names so they stay on the
// line (a very long one may still wrap to a second line above it).
export function nameFontSize(name) {
  const length = [...String(name ?? '')].length
  if (length <= NAME_FULL_SIZE_CHARS) return NAME_SIZE
  return Math.max(NAME_MIN_SIZE, Math.round(((NAME_SIZE * NAME_FULL_SIZE_CHARS) / length) * 10) / 10)
}
