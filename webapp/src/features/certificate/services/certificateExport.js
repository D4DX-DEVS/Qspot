import { CERTIFICATE_TEMPLATE, DETAILS_BOX, NAME_BOX } from '../models/certificateLayout'
import { certificateFileName } from '../models/certificateModel'
import { certificateHtml } from './certificateHtml'

// Prints the certificate through a hidden frame holding the same printable
// page the admin panel uses, once its picture and fonts are in; the
// browser's dialog also offers "Save as PDF".
export function printCertificate(certificate) {
  // A frame left from an earlier print (some browsers never send afterprint).
  document.getElementById('qs-print-frame')?.remove()
  const frame = document.createElement('iframe')
  frame.id = 'qs-print-frame'
  frame.setAttribute('aria-hidden', 'true')
  frame.style.cssText = 'position:fixed;right:0;bottom:0;width:0;height:0;border:0;'
  document.body.appendChild(frame)
  const remove = () => setTimeout(() => frame.remove(), 1000)
  frame.onload = async () => {
    const win = frame.contentWindow
    await win.document.fonts?.ready
    win.addEventListener('afterprint', remove, { once: true })
    win.focus()
    win.print()
  }
  frame.srcdoc = certificateHtml(certificate)
}

// A4 landscape in points, drawn at 2.5 pixels per point: sharp on paper and
// ~200 KB as a JPEG.
const PAGE_WIDTH = 842
const PAGE_HEIGHT = 595
const PIXELS_PER_POINT = 2.5

// Greedy word wrap, like the browser wraps the name on the on-screen sheet.
function wrapLines(ctx, text, maxWidth) {
  const lines = []
  let line = ''
  for (const word of text.split(/\s+/).filter(Boolean)) {
    const next = line ? `${line} ${word}` : word
    if (line && ctx.measureText(next).width > maxWidth) {
      lines.push(line)
      line = word
    } else {
      line = next
    }
  }
  if (line) lines.push(line)
  return lines
}

// Sets [lines] the way CSS sets a block of them with this line height whose
// bottom edge is at [bottom] (points from the top of the page).
function drawLines(ctx, lines, x, bottom, size, lineHeight) {
  const box = ctx.measureText(lines[0] ?? '')
  const ascent = box.fontBoundingBoxAscent ?? size * 0.85
  const descent = box.fontBoundingBoxDescent ?? size * 0.25
  const top = bottom - lines.length * lineHeight
  lines.forEach((line, i) => ctx.fillText(line, x, top + i * lineHeight + (lineHeight - ascent - descent) / 2 + ascent))
}

// The certificate painted straight onto a canvas: the design picture, the
// name in black bold on its line and the number and date at the foot, at the
// on-screen sheet's positions (CertificateSheet). Not a snapshot of the page,
// which a phone browser's dark mode repaints (the name turned white and the
// picture dimmed in the PDF).
async function drawCertificate(certificate) {
  // The load event, not decode(): decode() waits while the tab is hidden.
  const picture = new Image()
  const loaded = new Promise((resolve, reject) => {
    picture.onload = resolve
    picture.onerror = reject
  })
  picture.src = CERTIFICATE_TEMPLATE
  await Promise.all([loaded, document.fonts.load(`700 ${certificate.nameSize}px Manrope`), document.fonts.load('400 7.5px Manrope')])

  const canvas = document.createElement('canvas')
  canvas.width = PAGE_WIDTH * PIXELS_PER_POINT
  canvas.height = PAGE_HEIGHT * PIXELS_PER_POINT
  const ctx = canvas.getContext('2d')
  ctx.scale(PIXELS_PER_POINT, PIXELS_PER_POINT)
  ctx.fillStyle = '#ffffff'
  ctx.fillRect(0, 0, PAGE_WIDTH, PAGE_HEIGHT)
  ctx.drawImage(picture, 0, 0, PAGE_WIDTH, PAGE_HEIGHT)

  const size = certificate.nameSize
  ctx.font = `700 ${size}px Manrope, sans-serif`
  ctx.fillStyle = '#000000'
  ctx.textAlign = 'center'
  const name = wrapLines(ctx, certificate.studentName, NAME_BOX.width)
  drawLines(ctx, name, NAME_BOX.left + NAME_BOX.width / 2, PAGE_HEIGHT - NAME_BOX.bottom, size, size * 1.15)

  ctx.font = '400 7.5px Manrope, sans-serif'
  ctx.fillStyle = '#6b6270'
  ctx.textAlign = 'left'
  drawLines(ctx, [certificate.detailsLabel], DETAILS_BOX.left, PAGE_HEIGHT - DETAILS_BOX.bottom, 7.5, 7.5 * 1.5)
  return canvas
}

// Draws the certificate into a one-page A4 landscape PDF and downloads it,
// like the app's "Share PDF". The PDF library loads only when asked for.
export async function downloadCertificatePdf(certificate) {
  const [canvas, { jsPDF }] = await Promise.all([drawCertificate(certificate), import('jspdf')])
  const pdf = new jsPDF({ orientation: 'landscape', unit: 'pt', format: 'a4' })
  // JPEG keeps the file small; a PNG page is stored uncompressed.
  pdf.addImage(canvas.toDataURL('image/jpeg', 0.95), 'JPEG', 0, 0, pdf.internal.pageSize.getWidth(), pdf.internal.pageSize.getHeight())
  pdf.save(certificateFileName(certificate))
}
