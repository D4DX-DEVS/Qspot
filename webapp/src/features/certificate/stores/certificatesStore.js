import { ChangeNotifier } from '../../../lib/ChangeNotifier'
import { userFriendlyError } from '../../../utils/userFriendlyError'
import { downloadCertificatePdf, printCertificate } from '../services/certificateExport'
import { fetchMyCertificates } from '../services/certificateService'

// The student's certificates: loading, error and the loaded items
// (mobile-app/lib/screens/certificate/provider/certificates_screen_provider.dart),
// plus the PDF download state.
export class CertificatesStore extends ChangeNotifier {
  items = []
  isLoading = false
  error = null
  isDownloading = false
  // The preview at full size (scrollable) instead of fitted to the screen.
  zoomed = false
  #loaded = false

  // [initial] shows a certificate handed over by the page before, without
  // waiting for the list.
  constructor({ fetch = fetchMyCertificates, initial = null } = {}) {
    super()
    this.fetch = fetch
    // Counts as loading until the first answer, so the page never flashes
    // "No Certificate Yet" before the list has been asked for.
    this.isLoading = initial == null
    if (initial) {
      this.items = [initial]
      this.#loaded = true
    }
  }

  toggleZoom() {
    this.zoomed = !this.zoomed
    this.notifyListeners()
  }

  // The certificate issued for [quizId], or null when there is none.
  forQuiz(quizId) {
    return this.items.find((item) => item.quizId === quizId) ?? null
  }

  // Loads once per store, however many components ask.
  loadOnce() {
    if (this.#loaded) return
    this.#loaded = true
    this.load()
  }

  async load() {
    this.isLoading = true
    this.error = null
    this.notifyListeners()
    try {
      this.items = await this.fetch()
    } catch (e) {
      console.warn('Certificates load failed:', e)
      this.error = userFriendlyError(e)
    } finally {
      this.isLoading = false
      this.notifyListeners()
    }
  }

  print(certificate) {
    printCertificate(certificate)
  }

  // Null on success, or a message to show.
  async download(certificate, node) {
    if (this.isDownloading || !node) return null
    this.isDownloading = true
    this.notifyListeners()
    try {
      await downloadCertificatePdf(certificate, node)
      return null
    } catch (e) {
      console.warn('Certificate PDF failed:', e)
      return "Couldn't prepare the PDF. Please try Print instead."
    } finally {
      this.isDownloading = false
      this.notifyListeners()
    }
  }
}
