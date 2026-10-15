import React, { useEffect, useState } from 'react';
import apiClient from '../../api/client';
import EntitySelect, { CourseSelect } from '../ui/EntitySelect';
import { isoToLocalDateTimeInput, localDateTimeToISO } from '../../utils/format';

const labelClass = 'text-[11px] font-semibold uppercase tracking-[0.2em] text-white/65';
const selectClass = 'mt-2 block w-full rounded-2xl border border-white/10 bg-[#160b17] px-3.5 py-2.5 text-[13px] text-white outline-none focus:border-[#EFB078]/60';

// What a tap on the notification opens, and where to pick it from.
const TARGETS = {
  lesson: { label: 'A lesson', path: '/videos', labelKey: 'title' },
  quiz: { label: 'A quiz', path: '/quiz-definitions?limit=100', labelKey: 'title' },
  assignment: { label: 'An assignment', path: '/admin/assignments?limit=100', labelKey: 'title' },
  course: { label: 'A course', path: '/courses', labelKey: 'title' },
};

// Who gets an announcement, what a tap opens, and when it is sent. Once it
// has been sent, who and when are fixed (`sent`).
const AnnouncementOptions = ({ value, onChange, sent = false }) => {
  const [classes, setClasses] = useState([]);
  const [later, setLater] = useState(Boolean(value.sendAt) && new Date(value.sendAt) > new Date());

  useEffect(() => {
    apiClient.get('/admin/gradebook/classes')
      .then((response) => setClasses(Array.isArray(response.data) ? response.data : []))
      .catch(() => setClasses([]));
  }, []);

  const set = (patch) => onChange({ ...value, ...patch });

  return (
    <div className="space-y-4">
      <div>
        <label className={labelClass} htmlFor="announcement-audience">Send to</label>
        <select id="announcement-audience" disabled={sent} value={value.audience.kind} onChange={(e) => set({ audience: { kind: e.target.value, value: '' } })} className={selectClass}>
          <option value="all">All learners</option>
          <option value="class">One class</option>
          <option value="course">Learners in one course</option>
        </select>
        {value.audience.kind === 'class' && (
          <select id="announcement-class" disabled={sent} value={value.audience.value} onChange={(e) => set({ audience: { kind: 'class', value: e.target.value } })} className={selectClass} required>
            <option value="">Pick a class</option>
            {classes.map((c) => <option key={c} value={c}>{/^\d+$/.test(c) ? `Class ${c}` : c}</option>)}
          </select>
        )}
        {value.audience.kind === 'course' && (
          <div className="mt-2"><CourseSelect value={value.audience.value} onChange={(id) => set({ audience: { kind: 'course', value: id } })} required /></div>
        )}
      </div>

      <div>
        <label className={labelClass} htmlFor="announcement-target">A tap opens</label>
        <select id="announcement-target" value={value.target.kind} onChange={(e) => set({ target: { kind: e.target.value, id: '' } })} className={selectClass}>
          <option value="none">Just this message</option>
          {Object.entries(TARGETS).map(([kind, t]) => <option key={kind} value={kind}>{t.label}</option>)}
        </select>
        {TARGETS[value.target.kind] && (
          <div className="mt-2">
            <EntitySelect
              key={value.target.kind}
              path={TARGETS[value.target.kind].path}
              labelKey={TARGETS[value.target.kind].labelKey}
              placeholder={`Pick ${TARGETS[value.target.kind].label.toLowerCase()}`}
              value={value.target.id}
              onChange={(id) => set({ target: { kind: value.target.kind, id } })}
              required
            />
          </div>
        )}
      </div>

      {!sent && (
        <div>
          <span className={labelClass}>When</span>
          <div className="mt-2 flex gap-2">
            <button type="button" onClick={() => { setLater(false); set({ sendAt: '' }); }} className={`rounded-xl border px-3 py-2 text-xs font-semibold ${!later ? 'border-[#EFB078] text-[#EFB078]' : 'border-white/10 text-white/60'}`}>Send now</button>
            <button type="button" onClick={() => setLater(true)} className={`rounded-xl border px-3 py-2 text-xs font-semibold ${later ? 'border-[#EFB078] text-[#EFB078]' : 'border-white/10 text-white/60'}`}>Schedule</button>
          </div>
          {later && (
            <input
              id="announcement-send-at"
              type="datetime-local"
              required
              value={isoToLocalDateTimeInput(value.sendAt)}
              onChange={(e) => set({ sendAt: localDateTimeToISO(e.target.value) })}
              className={selectClass}
            />
          )}
        </div>
      )}
    </div>
  );
};

export default AnnouncementOptions;
