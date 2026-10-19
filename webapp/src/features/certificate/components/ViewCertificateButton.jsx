import { useEffect } from 'react'
import { Award } from 'lucide-react'
import { useNavigate } from 'react-router-dom'
import FilledButton from '../../../components/common/FilledButton'
import { useLocalNotifier } from '../../../lib/useNotifier'
import { CertificatesStore } from '../stores/certificatesStore'

// "View Certificate" for one exam. Takes no space until a certificate issued
// for [quizId] is found, so it can sit on any result; a failed lookup also
// stays hidden (view_certificate_button.dart).
export default function ViewCertificateButton({ quizId, className = '' }) {
  const store = useLocalNotifier(() => new CertificatesStore())
  const navigate = useNavigate()
  useEffect(() => store.loadOnce(), [store])
  const certificate = store.forQuiz(quizId)
  if (!certificate) return null
  return (
    <div className={className}>
      <FilledButton icon={Award} label="View Certificate" onClick={() => navigate(`/certificates/${quizId}`, { state: { certificate } })} />
    </div>
  )
}
