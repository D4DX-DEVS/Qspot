import React from 'react';
import { FiPlus, FiTrash2 } from 'react-icons/fi';
import { MAX_RUBRIC_PARTS, rubricTotal } from '../../utils/rubric';

const inputClass = 'w-full rounded-xl border border-white/10 bg-white/5 px-3 py-2 text-sm text-white placeholder-white/40 outline-none focus:border-[#EFB078]/60';

// In the assignment form: switch marking by parts on or off, and list the
// parts with what each is out of. When on, the total is the sum of the parts.
const RubricEditor = ({ value, onChange }) => {
  const criteria = value.criteria || [];
  const setPart = (index, patch) => onChange({ ...value, criteria: criteria.map((part, i) => (i === index ? { ...part, ...patch } : part)) });
  const addPart = () => onChange({ ...value, criteria: [...criteria, { label: '', maxPoints: 2 }] });
  const removePart = (index) => onChange({ ...value, criteria: criteria.filter((_, i) => i !== index) });
  const toggle = () => {
    const enabled = !value.enabled;
    onChange({ enabled, criteria: enabled && criteria.length === 0 ? [{ label: '', maxPoints: 4 }] : criteria });
  };

  return (
    <div className="rounded-xl border border-white/10 bg-white/[0.03] p-3">
      <label className="flex cursor-pointer items-center justify-between gap-3">
        <span>
          <span className="block text-sm font-semibold text-white">Mark by parts (rubric)</span>
          <span className="block text-xs text-white/50">
            {value.enabled ? 'Teachers score each part; the mark is the total.' : 'Off: teachers give one mark out of the max points.'}
          </span>
        </span>
        <input id="rubric-enabled" type="checkbox" checked={Boolean(value.enabled)} onChange={toggle} className="h-5 w-5 accent-[#EFB078]" />
      </label>

      {value.enabled && (
        <div className="mt-3 space-y-2">
          {criteria.map((part, index) => (
            <div key={index} className="grid grid-cols-[minmax(0,1fr)_96px_auto] items-center gap-2">
              <input
                id={`rubric-label-${index}`}
                value={part.label}
                maxLength={80}
                onChange={(event) => setPart(index, { label: event.target.value })}
                placeholder={`Part ${index + 1}, e.g. Makharij`}
                className={inputClass}
                required
              />
              <input
                id={`rubric-points-${index}`}
                type="number"
                min="1"
                max="1000"
                value={part.maxPoints}
                onChange={(event) => setPart(index, { maxPoints: event.target.value })}
                aria-label={`Points for part ${index + 1}`}
                className={inputClass}
                required
              />
              <button type="button" onClick={() => removePart(index)} disabled={criteria.length === 1} aria-label={`Remove part ${index + 1}`} className="rounded-lg p-2 text-white/50 hover:bg-white/10 disabled:opacity-30">
                <FiTrash2 size={14} />
              </button>
            </div>
          ))}
          <div className="flex items-center justify-between pt-1">
            <button type="button" onClick={addPart} disabled={criteria.length >= MAX_RUBRIC_PARTS} className="inline-flex items-center gap-1 text-xs font-semibold text-[#EFB078] disabled:opacity-40">
              <FiPlus size={13} /> Add part
            </button>
            <span className="text-xs text-white/60">Total: <b className="text-white">{rubricTotal(value)}</b> points</span>
          </div>
        </div>
      )}
    </div>
  );
};

export default RubricEditor;
