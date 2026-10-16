import React, { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import { FiAward, FiCheck, FiEye, FiRefreshCw, FiShield, FiUsers } from 'react-icons/fi';
import Sidebar from '../components/Sidebar';
import CertificateViewer from '../components/certificates/CertificateViewer';
import ClassMultiSelect from '../components/ui/ClassMultiSelect';
import ErrorState from '../components/ui/ErrorState';
import Spinner from '../components/ui/Spinner';
import Pagination from '../components/ui/Pagination';
import PageHeader from '../components/ui/PageHeader';
import apiClient from '../api/client';
import { formatDateTime } from '../utils/format';
import usePageTitle from '../hooks/usePageTitle';

const cardClass = 'rounded-2xl border border-white/10 bg-gradient-to-br from-[#11060d]/80 via-[#1c0b18]/55 to-[#12060f]/80 shadow-[0_10px_32px_rgba(0,0,0,0.3)]';
const inputClass = 'mt-2 w-full rounded-xl border border-white/15 bg-white/5 px-3 py-2 text-sm text-white focus:border-[#EFB078]/60 focus:outline-none';

const ATTEMPTS_PAGE_SIZE = 20;

const CertificatesPage = () => {
  usePageTitle('Certificates');
  const navigate = useNavigate();
  const [searchParams, setSearchParams] = useSearchParams();
  const selectedQuizId = searchParams.get('quizId') || '';

  const [quizOptions, setQuizOptions] = useState([]);
  const [quiz, setQuiz] = useState(null);
  // One page of the exam's attempts from the server, for picking students.
  const [attempts, setAttempts] = useState([]);
  const [attemptsPage, setAttemptsPage] = useState(1);
  const [attemptsTotal, setAttemptsTotal] = useState(0);
  const [completedCount, setCompletedCount] = useState(0);
  const [studentSearchInput, setStudentSearchInput] = useState('');
  const [studentSearch, setStudentSearch] = useState('');
  const latestAttemptsRequest = useRef(0);
  const [certificates, setCertificates] = useState([]);
  const [mode, setMode] = useState('criteria');
  const [minimumPercentage, setMinimumPercentage] = useState('0');
  const [classes, setClasses] = useState([]);
  const [selectedIds, setSelectedIds] = useState(new Set());
  const [loading, setLoading] = useState(true);
  const [issuing, setIssuing] = useState(false);
  const [error, setError] = useState('');
  const [notice, setNotice] = useState('');
  const [viewing, setViewing] = useState(null);

  // The exam picker lists every exam, fetched 100 at a time.
  const loadQuizOptions = async () => {
    const items = [];
    for (let page = 1; ; page += 1) {
      const response = await apiClient.get('/quiz-definitions', { params: { page, limit: 100 } });
      const batch = Array.isArray(response.data?.items) ? response.data.items : [];
      items.push(...batch);
      if (!batch.length || items.length >= (response.data?.total || 0)) break;
    }
    setQuizOptions(items);
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
      const [quizResponse, certificateResponse] = await Promise.all([
        apiClient.get(`/quiz-definitions/${id}`),
        apiClient.get(`/certificates/quiz/${id}`)
      ]);
      const loadedQuiz = quizResponse.data || {};
      setQuiz(loadedQuiz);
      setCertificates(Array.isArray(certificateResponse.data?.items) ? certificateResponse.data.items : []);
      setMinimumPercentage(String(loadedQuiz.certificate?.minimumPercentage ?? 0));
      setClasses(Array.isArray(loadedQuiz.certificate?.eligibleClasses) ? loadedQuiz.certificate.eligibleClasses : []);
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

  const loadAttempts = useCallback(async () => {
    if (!selectedQuizId) return;
    // Only the newest request may update the list (the search can change mid-load).
    const request = ++latestAttemptsRequest.current;
    try {
      const response = await apiClient.get(`/quiz-definitions/${selectedQuizId}/results`, {
        params: { page: attemptsPage, limit: ATTEMPTS_PAGE_SIZE, search: studentSearch.trim() || undefined },
      });
      if (request !== latestAttemptsRequest.current) return;
      setAttempts(Array.isArray(response.data?.items) ? response.data.items : []);
      setAttemptsTotal(response.data?.total || 0);
      if (!studentSearch.trim()) setCompletedCount(response.data?.total || 0);
    } catch (err) {
      if (request === latestAttemptsRequest.current) setError(err.message || 'Failed to load certificate data.');
    }
  }, [selectedQuizId, attemptsPage, studentSearch]);

  useEffect(() => {
    loadAttempts();
  }, [loadAttempts]);

  // Debounce the student search into the server-side `search` param.
  useEffect(() => {
    const timer = setTimeout(() => setStudentSearch(studentSearchInput), 350);
    return () => clearTimeout(timer);
  }, [studentSearchInput]);

  // Another exam or a new search starts again from the first page.
  useEffect(() => {
    setAttemptsPage(1);
  }, [selectedQuizId, studentSearch]);

  const refresh = () => {
    loadExam();
    loadAttempts();
  };

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
      <div className="flex-1 min-w-0 flex flex-col w-full pb-28 md:ml-64 md:pb-0">
        <main className="flex-1 p-6 md:p-8 flex flex-col gap-6">
          <PageHeader
            title="Certificates"
            actions={<button type="button" onClick={refresh} className="inline-flex items-center gap-2 rounded-xl border border-white/15 bg-white/5 px-3 py-2 text-xs font-semibold text-white/75 hover:border-[#EFB078]/50"><FiRefreshCw size={13} /> Refresh</button>}
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

          {error && <ErrorState message={error} onRetry={refresh} />}
          {notice && <div className="rounded-2xl border border-emerald-400/25 bg-emerald-400/10 px-4 py-3 text-sm text-emerald-200">{notice}</div>}

          {loading ? <Spinner /> : quiz && (
            <>
              <section className={`${cardClass} p-5`}>
                <div className="flex flex-wrap items-start justify-between gap-4">
                  <div>
                    <p className="text-xs font-semibold uppercase tracking-[0.2em] text-[#EFB078]">{quiz.assessmentType === 'practical' ? 'Practical exam' : 'Knowledge exam'}</p>
                    <h2 className="mt-2 text-2xl font-bold text-white">{quiz.title}</h2>
                    <p className="mt-1 text-sm text-white/55">Ended {formatDateTime(quiz.endDate)} · {completedCount} completed attempt(s)</p>
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
                  <div className="block text-xs font-semibold uppercase tracking-[0.16em] text-white/60"><span id="issue-classes">Classes (optional)</span><ClassMultiSelect labelId="issue-classes" value={classes} onChange={setClasses} disabled={mode !== 'criteria'} className="mt-2" /></div>
                  <button type="button" disabled={issuing || !quiz.certificate?.enabled || !ended || (mode === 'selected' && selectedIds.size === 0)} onClick={issueCertificates} className="self-end inline-flex items-center justify-center gap-2 rounded-xl bg-gradient-to-r from-[#8C2852] via-[#B74A6D] to-[#F0B47F] px-4 py-2.5 text-sm font-semibold text-white shadow-[0_8px_20px_rgba(112,24,69,0.25)] disabled:cursor-not-allowed disabled:opacity-40"><FiAward size={15} />{issuing ? 'Issuing…' : 'Issue certificates'}</button>
                </div>
              </section>

              {mode === 'selected' && (
                <section className={`${cardClass} p-5`}>
                  <div className="flex items-center justify-between gap-3"><div className="flex items-center gap-2"><FiUsers className="text-[#EFB078]" /><h2 className="text-lg font-semibold text-white">Select students</h2></div><span className="text-xs text-white/50">{selectedIds.size} selected</span></div>
                  <input type="search" value={studentSearchInput} onChange={(event) => setStudentSearchInput(event.target.value)} placeholder="Search students by name or class" className={inputClass} />
                  <div className="mt-4 grid grid-cols-1 gap-2 md:grid-cols-2">
                    {selectableAttempts.map((attempt) => <label key={attempt.attemptId} className="flex cursor-pointer items-center gap-3 rounded-xl border border-white/10 bg-white/5 px-3 py-3 hover:border-[#EFB078]/40"><input type="checkbox" checked={selectedIds.has(String(attempt.userId))} onChange={() => toggleStudent(attempt.userId)} className="h-4 w-4 accent-[#EFB078]" /><span className="min-w-0 flex-1"><span className="block truncate text-sm font-semibold text-white">{attempt.name || 'Unknown'}</span><span className="text-xs text-white/50">Class {attempt.class || '—'} · {attempt.percentage}%</span></span>{issuedUserIds.has(String(attempt.userId)) && <FiCheck className="text-emerald-300" />}</label>)}
                  </div>
                  <Pagination page={attemptsPage} total={attemptsTotal} limit={ATTEMPTS_PAGE_SIZE} onChange={setAttemptsPage} label="attempts" />
                </section>
              )}

              <section className={`${cardClass} overflow-hidden`}>
                <div className="flex items-center justify-between border-b border-white/10 px-5 py-4"><h2 className="text-lg font-semibold text-white">Issued certificates</h2><span className="text-xs text-white/50">{certificates.length} total</span></div>
                {certificates.length === 0 ? <p className="px-5 py-8 text-sm text-white/50">No certificates issued for this exam yet.</p> : <div className="overflow-x-auto"><table className="min-w-full text-left text-sm"><thead className="bg-white/5 text-xs uppercase tracking-[0.14em] text-white/45"><tr><th className="px-5 py-3">Student</th><th className="px-5 py-3">Score</th><th className="px-5 py-3">Certificate</th><th className="px-5 py-3">Issued</th><th className="px-5 py-3 text-right">Actions</th></tr></thead><tbody className="divide-y divide-white/10">{certificates.map((certificate) => <tr key={certificate.id} className="text-white/75"><td className="px-5 py-3"><div className="font-semibold text-white">{certificate.student?.name || 'Unknown'}</div><div className="text-xs text-white/45">Class {certificate.student?.class || '—'}</div></td><td className="px-5 py-3">{certificate.percentage}%</td><td className="px-5 py-3 font-mono text-xs">{certificate.certificateNumber}<div className={`mt-1 font-sans text-[11px] ${certificate.status === 'issued' ? 'text-emerald-300' : 'text-red-300'}`}>{certificate.status}</div></td><td className="px-5 py-3 text-xs">{formatDateTime(certificate.issuedAt)}</td><td className="px-5 py-3"><div className="flex justify-end gap-2"><button type="button" onClick={() => setViewing(certificate)} className="inline-flex items-center gap-1.5 rounded-lg border border-white/15 bg-white/5 px-2.5 py-1.5 text-xs font-semibold text-white/75 hover:border-[#EFB078]/50"><FiEye size={13} /> View</button>{certificate.status === 'issued' && <button type="button" onClick={() => revokeCertificate(certificate)} className="rounded-lg border border-red-400/25 bg-red-400/10 px-2.5 py-1.5 text-xs font-semibold text-red-200 hover:border-red-300/60">Revoke</button>}</div></td></tr>)}</tbody></table></div>}
              </section>
            </>
          )}
        </main>
      </div>
      {viewing && <CertificateViewer certificate={viewing} onClose={() => setViewing(null)} />}
    </div>
  );
};

export default CertificatesPage;
