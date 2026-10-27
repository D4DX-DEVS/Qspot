import { jsonDouble, jsonInt, parseDate, text } from '../../../utils/jsonParsing'
import { dayLongMonthYear } from '../../../utils/formatDate'
import { nameFontSize } from './certificateLayout'

// One certificate issued to the signed-in student, from
// GET /api/certificates/mine (mobile-app/lib/screens/certificate/model/certificate_model.dart).
// Wording comes from the certificate's own snapshot, taken when it was
// issued; blank fields fall back to the same text the admin panel prints.
const obj = (v) => (v && typeof v === 'object' ? v : {})

export function certificateFromJson(json) {
  const snapshot = obj(json.snapshot)
  // `exam` is the populated quiz; older payloads only had `quizId`, which may
  // itself be the populated object or a bare id string.
  const exam = Object.keys(obj(json.exam)).length ? obj(json.exam) : obj(json.quizId)
  const student = obj(json.student)
  const percentage = Math.min(100, Math.max(0, jsonDouble(json.percentage) ?? 0))
  const issuedAt = parseDate(text(json.issuedAt))
  const certificateNumber = text(json.certificateNumber)
  const studentName = text(student.name, 'Student')
  const issuedLabel = issuedAt ? dayLongMonthYear(issuedAt) : ''
  return {
    id: text(json.id ?? json._id),
    quizId: text(exam._id, typeof json.quizId === 'string' ? json.quizId : ''),
    certificateNumber,
    studentName,
    // Point size of the name on the certificate.
    nameSize: nameFontSize(studentName),
    title: text(snapshot.title, 'Certificate of Achievement'),
    issuerName: text(snapshot.issuerName, 'QSPOT Learning'),
    signatoryName: text(snapshot.signatoryName, 'Authorized Signatory'),
    description: text(snapshot.description, 'For successfully completing the examination.'),
    examTitle: text(snapshot.examTitle, text(exam.title, 'Exam')),
    percentage,
    score: jsonInt(json.score) ?? 0,
    totalQuestions: jsonInt(json.totalQuestions) ?? 0,
    issuedAt,
    // "100%" or "87.5%".
    percentageLabel: percentage % 1 === 0 ? `${percentage}%` : `${percentage.toFixed(1)}%`,
    // "7 October 2026", or empty when the date is missing.
    issuedLabel,
    // "Certificate No. QSPOT-2026-… · Issued 7 October 2026", small at the
    // foot of the certificate.
    detailsLabel: [`Certificate No. ${certificateNumber}`, issuedLabel ? `Issued ${issuedLabel}` : ''].filter(Boolean).join(' · '),
  }
}

// Safe file name for the downloaded PDF.
export function certificateFileName(certificate) {
  const base = certificate.certificateNumber.replace(/[^A-Za-z0-9_-]/g, '')
  return `${base || 'certificate'}.pdf`
}
