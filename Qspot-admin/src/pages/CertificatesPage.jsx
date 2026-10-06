import React, { useEffect, useMemo, useState } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import { FiAward, FiCheck, FiPrinter, FiRefreshCw, FiShield, FiUsers } from 'react-icons/fi';
import Sidebar from '../components/Sidebar';
import ErrorState from '../components/ui/ErrorState';
import Spinner from '../components/ui/Spinner';
import PageHeader from '../components/ui/PageHeader';
import apiClient from '../api/client';
import { formatDateTime } from '../utils/format';
import usePageTitle from '../hooks/usePageTitle';

const cardClass = 'rounded-2xl border border-white/10 bg-gradient-to-br from-[#11060d]/80 via-[#1c0b18]/55 to-[#12060f]/80 shadow-[0_10px_32px_rgba(0,0,0,0.3)]';
const inputClass = 'mt-2 w-full rounded-xl border border-white/15 bg-white/5 px-3 py-2 text-sm text-white focus:border-[#EFB078]/60 focus:outline-none';

const escapeHtml = (value) => String(value ?? '')
  .replaceAll('&', '&amp;')
  .replaceAll('<', '&lt;')
  .replaceAll('>', '&gt;')
  .replaceAll('"', '&quot;')
  .replaceAll("'", '&#039;');

const printCertificate = (certificate) => {
  const popup = window.open('', '_blank', 'width=1100,height=800');
  if (!popup) return false;
  const snapshot = certificate.snapshot || {};
  const student = certificate.student || {};
  popup.document.write(`<!doctype html><html><head><title>${escapeHtml(certificate.certificateNumber)}</title><style>
    @page{size:A4 landscape;margin:0}*{box-sizing:border-box}body{margin:0;background:#f7f1eb;color:#1c1220;font-family:Georgia,serif}.sheet{width:297mm;height:210mm;padding:18mm;display:grid;place-items:center}.certificate{width:100%;height:100%;border:3px solid #701845;padding:12mm;display:flex;flex-direction:column;align-items:center;justify-content:center;text-align:center;position:relative;background:linear-gradient(135deg,#fffaf6,#f8e9ee)}.certificate:before{content:'';position:absolute;inset:7mm;border:1px solid #e0ae73;pointer-events:none}.eyebrow{letter-spacing:.35em;text-transform:uppercase;color:#701845;font-size:12px}.title{font-size:38px;color:#701845;margin:14px 0 8px}.student{font-size:42px;font-weight:bold;color:#111827;margin:12px 0}.description{max-width:620px;font-size:18px;line-height:1.5;color:#4b4350}.meta{margin-top:28px;display:flex;gap:70px;color:#5c5360;font-size:14px}.signature{margin-top:28px;min-width:180px;border-top:1px solid #701845;padding-top:8px;font-size:14px}.number{position:absolute;bottom:12mm;font:12px Arial;color:#6b6270}</style></head><body><main class="sheet"><section class="certificate"><div class="eyebrow">${escapeHtml(snapshot.issuerName || 'QSPOT LEARNING')}</div><h1 class="title">${escapeHtml(snapshot.title || 'Certificate of Achievement')}</h1><div>This certificate is proudly presented to</div><div class="student">${escapeHtml(student.name || 'Student')}</div><div class="description">${escapeHtml(snapshot.description || 'For successfully completing the examination.')}<br><strong>${escapeHtml(snapshot.examTitle || 'Examination')}</strong></div><div class="meta"><span>Score<br><strong>${escapeHtml(certificate.percentage)}%</strong></span><span>Issued<br><strong>${escapeHtml(formatDateTime(certificate.issuedAt))}</strong></span></div><div class="signature">${escapeHtml(snapshot.signatoryName || 'Authorized Signatory')}</div><div class="number">Certificate No. ${escapeHtml(certificate.certificateNumber)}</div></section></main><script>window.onload=()=>{window.print()}</script></body></html>`);
  popup.document.close();
  return true;
};

const CertificatesPage = () => {
  usePageTitle('Certificates');
  const navigate = useNavigate();
  const [searchParams, setSearchParams] = useSearchParams();
  const selectedQuizId = searchParams.get('quizId') || '';

  const [quizOptions, setQuizOptions] = useState([]);
  const [quiz, setQuiz] = useState(null);
  const [attempts, setAttempts] = useState([]);
  const [certificates, setCertificates] = useState([]);
  const [mode, setMode] = useState('criteria');
  const [minimumPercentage, setMinimumPercentage] = useState('0');
  const [classes, setClasses] = useState('');
  const [selectedIds, setSelectedIds] = useState(new Set());
  const [loading, setLoading] = useState(true);
  const [issuing, setIssuing] = useState(false);
  const [error, setError] = useState('');
  const [notice, setNotice] = useState('');

  const loadQuizOptions = async () => {
    const response = await apiClient.get('/quiz-definitions', { params: { page: 1, limit: 100 } });
    setQuizOptions(Array.isArray(response.data?.items) ? response.data.items : []);
  };

  const loadExam = async (id = selectedQuizId) => {
    if (!id) {
      setQuiz(null);
      setAttempts([]);
      setCertificates([]);
      setLoading(false);
      return;
    }
    try {
      setLoading(true);
      setError('');
      const [quizResponse, resultResponse, certificateResponse] = await Promise.all([
        apiClient.get(`/quiz-definitions/${id}`),
        apiClient.get(`/quiz-definitions/${id}/results`, { params: { page: 1, limit: 100 } }),
        apiClient.get(`/certificates/quiz/${id}`)
      ]);
      const loadedQuiz = quizResponse.data || {};
      setQuiz(loadedQuiz);
      setAttempts(Array.isArray(resultResponse.data?.items) ? resultResponse.data.items : []);
      setCertificates(Array.isArray(certificateResponse.data?.items) ? certificateResponse.data.items : []);
      setMinimumPercentage(String(loadedQuiz.certificate?.minimumPercentage ?? 0));
      setClasses(Array.isArray(loadedQuiz.certificate?.eligibleClasses) ? loadedQuiz.certificate.eligibleClasses.join(', ') : '');
      setSelectedIds(new Set());
    } catch (err) {
      setError(err.message || 'Failed to load certificate data.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadQuizOptions().catch((err) => setError(err.message || 'Failed to load exams.'));
  }, []);

  useEffect(() => {
    loadExam();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [selectedQuizId]);

  const ended = Boolean(quiz && new Date(quiz.endDate) <= new Date());
  const issuedUserIds = useMemo(() => new Set(certificates.map((item) => String(item.userId))), [certificates]);
  const selectableAttempts = useMemo(() => {
    const seen = new Set();
    return attempts.filter((attempt) => {
      const userId = String(attempt.userId || '');
      if (!userId || issuedUserIds.has(userId) || seen.has(userId)) return false;
      seen.add(userId);
      return true;
    });
  }, [attempts, issuedUserIds]);

  const handleQuizChange = (value) => {
    setSearchParams(value ? { quizId: value } : {});
  };

  const toggleStudent = (userId) => {
    setSelectedIds((current) => {
      const next = new Set(current);
      if (next.has(String(userId))) next.delete(String(userId));
      else next.add(String(userId));
      return next;
    });
  };

  const issueCertificates = async () => {
    if (!selectedQuizId) return;
    try {
      setIssuing(true);
      setError('');
      setNotice('');
      const response = await apiClient.post(`/certificates/quiz/${selectedQuizId}/issue`, {
        mode,
        studentIds: [...selectedIds],
        minimumPercentage: Number(minimumPercentage || 0),
        classes
      });
      setNotice(`${response.data?.created || 0} certificate(s) issued. ${response.data?.existing || 0} already existed.`);
      await loadExam();
    } catch (err) {
      setError(err.message || 'Failed to issue certificates.');
    } finally {
      setIssuing(false);
    }
  };

  const revokeCertificate = async (certificate) => {
    if (!window.confirm(`Revoke ${certificate.certificateNumber}?`)) return;
    try {
      await apiClient.post(`/certificates/${certificate.id}/revoke`);
      await loadExam();
    } catch (err) {
      setError(err.message || 'Failed to revoke certificate.');
    }
  };

  return (
    <div className="flex min-h-screen overflow-x-hidden bg-black">
      <Sidebar currentPage="certificates" onNavigate={navigate} />
      <div className="flex-1 flex flex-col w-full pb-28 md:ml-64 md:pb-0">
        <main className="flex-1 p-6 md:p-8 flex flex-col gap-6">
          <PageHeader
            title="Certificates"
            actions={<button type="button" onClick={() => loadExam()} className="inline-flex items-center gap-2 rounded-xl border border-white/15 bg-white/5 px-3 py-2 text-xs font-semibold text-white/75 hover:border-[#EFB078]/50"><FiRefreshCw size={13} /> Refresh</button>}
          />

          <section className={`${cardClass} p-5`}>
            <label className="block text-xs font-semibold uppercase tracking-[0.18em] text-white/60">
              Exam
              <select value={selectedQuizId} onChange={(event) => handleQuizChange(event.target.value)} className={inputClass}>
                <option value="">Select an exam…</option>
                {quizOptions.map((item) => <option key={item._id} value={item._id}>{item.title}</option>)}
              </select>
            </label>
          </section>

          {error && <ErrorState message={error} onRetry={() => loadExam()} />}
          {notice && <div className="rounded-2xl border border-emerald-400/25 bg-emerald-400/10 px-4 py-3 text-sm text-emerald-200">{notice}</div>}

          {loading ? <Spinner /> : quiz && (
            <>
              <section className={`${cardClass} p-5`}>
                <div className="flex flex-wrap items-start justify-between gap-4">
                  <div>
                    <p className="text-xs font-semibold uppercase tracking-[0.2em] text-[#EFB078]">{quiz.assessmentType === 'practical' ? 'Practical exam' : 'Knowledge exam'}</p>
                    <h2 className="mt-2 text-2xl font-bold text-white">{quiz.title}</h2>
                    <p className="mt-1 text-sm text-white/55">Ended {formatDateTime(quiz.endDate)} · {attempts.length} completed attempt(s)</p>
                  </div>
                  <div className={`rounded-full px-3 py-1.5 text-xs font-semibold ${quiz.certificate?.enabled ? 'bg-emerald-400/15 text-emerald-200' : 'bg-white/10 text-white/55'}`}>
                    {quiz.certificate?.enabled ? 'Certificate enabled' : 'Certificate disabled'}
                  </div>
                </div>
                {!quiz.certificate?.enabled && <p className="mt-4 rounded-xl border border-amber-300/20 bg-amber-300/10 px-3 py-2 text-sm text-amber-100">Enable certificate settings in the exam editor before issuing certificates.</p>}
                {!ended && <p className="mt-4 rounded-xl border border-blue-300/20 bg-blue-300/10 px-3 py-2 text-sm text-blue-100">Certificates become available after the exam end time.</p>}
              </section>

              <section className={`${cardClass} p-5`}>
                <div className="flex items-center gap-2"><FiShield className="text-[#EFB078]" /><h2 className="text-lg font-semibold text-white">Issue certificates</h2></div>
                <p className="mt-1 text-sm text-white/55">Choose who receives a certificate. Existing certificates are never duplicated.</p>
                <div className="mt-5 grid gap-4 lg:grid-cols-[1fr_1fr_1fr_auto]">
                  <label className="block text-xs font-semibold uppercase tracking-[0.16em] text-white/60">Issuance group<select value={mode} onChange={(event) => setMode(event.target.value)} className={inputClass}><option value="criteria">Based on criteria</option><option value="all">All students with an attempt</option><option value="selected">Selected students</option></select></label>
                  <label className="block text-xs font-semibold uppercase tracking-[0.16em] text-white/60">Minimum percentage<input type="number" min="0" max="100" value={minimumPercentage} onChange={(event) => setMinimumPercentage(event.target.value)} disabled={mode === 'all'} className={`${inputClass} disabled:opacity-50`} /></label>
                  <label className="block text-xs font-semibold uppercase tracking-[0.16em] text-white/60">Classes (optional)<input value={classes} onChange={(event) => setClasses(event.target.value)} disabled={mode !== 'criteria'} className={`${inputClass} disabled:opacity-50`} placeholder="8, 9" /></label>
                  <button type="button" disabled={issuing || !quiz.certificate?.enabled || !ended || (mode === 'selected' && selectedIds.size === 0)} onClick={issueCertificates} className="self-end inline-flex items-center justify-center gap-2 rounded-xl bg-gradient-to-r from-[#8C2852] via-[#B74A6D] to-[#F0B47F] px-4 py-2.5 text-sm font-semibold text-white shadow-[0_8px_20px_rgba(112,24,69,0.25)] disabled:cursor-not-allowed disabled:opacity-40"><FiAward size={15} />{issuing ? 'Issuing…' : 'Issue certificates'}</button>
                </div>
              </section>

              {mode === 'selected' && (
                <section className={`${cardClass} p-5`}>
                  <div className="flex items-center justify-between gap-3"><div className="flex items-center gap-2"><FiUsers className="text-[#EFB078]" /><h2 className="text-lg font-semibold text-white">Select students</h2></div><span className="text-xs text-white/50">{selectedIds.size} selected</span></div>
                  <div className="mt-4 grid gap-2 md:grid-cols-2">
                    {selectableAttempts.map((attempt) => <label key={attempt.attemptId} className="flex cursor-pointer items-center gap-3 rounded-xl border border-white/10 bg-white/5 px-3 py-3 hover:border-[#EFB078]/40"><input type="checkbox" checked={selectedIds.has(String(attempt.userId))} onChange={() => toggleStudent(attempt.userId)} className="h-4 w-4 accent-[#EFB078]" /><span className="min-w-0 flex-1"><span className="block truncate text-sm font-semibold text-white">{attempt.name || 'Unknown'}</span><span className="text-xs text-white/50">Class {attempt.class || '—'} · {attempt.percentage}%</span></span>{issuedUserIds.has(String(attempt.userId)) && <FiCheck className="text-emerald-300" />}</label>)}
                  </div>
                </section>
              )}

              <section className={`${cardClass} overflow-hidden`}>
                <div className="flex items-center justify-between border-b border-white/10 px-5 py-4"><h2 className="text-lg font-semibold text-white">Issued certificates</h2><span className="text-xs text-white/50">{certificates.length} total</span></div>
                {certificates.length === 0 ? <p className="px-5 py-8 text-sm text-white/50">No certificates issued for this exam yet.</p> : <div className="overflow-x-auto"><table className="min-w-full text-left text-sm"><thead className="bg-white/5 text-xs uppercase tracking-[0.14em] text-white/45"><tr><th className="px-5 py-3">Student</th><th className="px-5 py-3">Score</th><th className="px-5 py-3">Certificate</th><th className="px-5 py-3">Issued</th><th className="px-5 py-3 text-right">Actions</th></tr></thead><tbody className="divide-y divide-white/10">{certificates.map((certificate) => <tr key={certificate.id} className="text-white/75"><td className="px-5 py-3"><div className="font-semibold text-white">{certificate.student?.name || 'Unknown'}</div><div className="text-xs text-white/45">Class {certificate.student?.class || '—'}</div></td><td className="px-5 py-3">{certificate.percentage}%</td><td className="px-5 py-3 font-mono text-xs">{certificate.certificateNumber}<div className={`mt-1 font-sans text-[11px] ${certificate.status === 'issued' ? 'text-emerald-300' : 'text-red-300'}`}>{certificate.status}</div></td><td className="px-5 py-3 text-xs">{formatDateTime(certificate.issuedAt)}</td><td className="px-5 py-3"><div className="flex justify-end gap-2"><button type="button" disabled={certificate.status !== 'issued'} onClick={() => printCertificate(certificate)} className="inline-flex items-center gap-1.5 rounded-lg border border-white/15 bg-white/5 px-2.5 py-1.5 text-xs font-semibold text-white/75 hover:border-[#EFB078]/50 disabled:opacity-30"><FiPrinter size={13} /> Print</button>{certificate.status === 'issued' && <button type="button" onClick={() => revokeCertificate(certificate)} className="rounded-lg border border-red-400/25 bg-red-400/10 px-2.5 py-1.5 text-xs font-semibold text-red-200 hover:border-red-300/60">Revoke</button>}</div></td></tr>)}</tbody></table></div>}
              </section>
            </>
          )}
        </main>
      </div>
    </div>
  );
};

export default CertificatesPage;
