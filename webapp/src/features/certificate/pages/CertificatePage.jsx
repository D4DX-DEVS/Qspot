import { useEffect, useRef } from 'react'
import { Award, Download, Printer } from 'lucide-react'
import { useLocation, useNavigate, useParams } from 'react-router-dom'
import AppBar from '../../../components/common/AppBar'
import FilledButton from '../../../components/common/FilledButton'
import OutlinedButton from '../../../components/common/OutlinedButton'
import PageShell from '../../../components/common/PageShell'
import Spinner from '../../../components/common/Spinner'
import StateMessageView from '../../../components/common/StateMessageView'
import { useLocalNotifier } from '../../../lib/useNotifier'
import { toastStore } from '../../../stores/toastStore'
import CertificatePreview from '../components/CertificatePreview'
import { CertificatesStore } from '../stores/certificatesStore'

// One issued certificate, scaled to fit, with Download PDF and Print
// (certificate_screen.dart; the app shares the PDF instead).
export default function CertificatePage() {
  const { quizId } = useParams()
  const navigate = useNavigate()
  const location = useLocation()
  const store = useLocalNotifier(() => new CertificatesStore({ initial: location.state?.certificate ?? null }))
  const sheet = useRef(null)
  useEffect(() => store.loadOnce(), [store])

  const certificate = store.forQuiz(quizId)
  const download = async () => {
    const failure = await store.download(certificate, sheet.current)
    if (failure) toastStore.show(failure, 'danger')
  }

  let body
  if (certificate) {
    body = (
      <PageShell width="max-w-4xl" className="flex flex-col items-center gap-6">
        <CertificatePreview certificate={certificate} sheetRef={sheet} />
        <div className="flex w-full max-w-[480px] flex-col gap-3">
          <FilledButton icon={Download} label={store.isDownloading ? 'Preparing PDF…' : 'Download PDF'} loading={store.isDownloading} onClick={download} />
          <OutlinedButton icon={Printer} label="Print" onClick={() => store.print(certificate)} />
        </div>
      </PageShell>
    )
  } else if (store.isLoading) {
    body = <div className="grid min-h-[50dvh] place-items-center text-brand"><Spinner size={36} stroke={3} /></div>
  } else {
    body = (
      <StateMessageView
        icon={Award}
        title="No Certificate Yet"
        message={store.error ?? 'A certificate shows here once your teacher issues one for this quiz.'}
        onRetry={store.error ? () => store.load() : undefined}
      />
    )
  }

  return (
    <div className="min-h-dvh bg-bg">
      <AppBar title="Certificate" width="max-w-4xl" onBack={() => navigate(-1)} />
      {body}
    </div>
  )
}
