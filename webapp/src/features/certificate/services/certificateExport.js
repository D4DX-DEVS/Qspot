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

// Draws the on-screen sheet ([node], at its full A4 size) into a one-page A4
// landscape PDF and downloads it, like the app's "Share PDF". The libraries
// load only when asked for.
export async function downloadCertificatePdf(certificate, node) {
  const [{ toJpeg }, { jsPDF }] = await Promise.all([import('html-to-image'), import('jspdf')])
  // JPEG keeps the file small (~200 KB); a PNG page is stored uncompressed.
  const image = await toJpeg(node, { pixelRatio: 2.5, quality: 0.95, cacheBust: true, backgroundColor: '#ffffff' })
  const pdf = new jsPDF({ orientation: 'landscape', unit: 'pt', format: 'a4' })
  pdf.addImage(image, 'JPEG', 0, 0, pdf.internal.pageSize.getWidth(), pdf.internal.pageSize.getHeight())
  pdf.save(certificateFileName(certificate))
}
