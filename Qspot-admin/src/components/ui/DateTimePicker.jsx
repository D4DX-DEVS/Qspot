import { localDateTimeToISO, isoToLocalDateTimeInput } from '../../utils/format';

// Single date/time picker used by every form that needs a scheduled
// moment (quiz start/end, schedule slot, video release date). Wraps a
// native `datetime-local` input, but always emits/accepts ISO 8601 strings
// with timezone (per CONTRACT.md) so callers never touch offsets.
const DateTimePicker = ({ valueISO, onChangeISO, required = false, min, className = '' }) => (
  <input
    type="datetime-local"
    required={required}
    min={min}
    value={isoToLocalDateTimeInput(valueISO)}
    onChange={(e) => onChangeISO(localDateTimeToISO(e.target.value))}
    className={`block w-full rounded-2xl border border-white/10 bg-white/5 px-4 py-3 text-sm text-white backdrop-blur-sm transition-all focus:border-[#EFB078]/60 focus:outline-none ${className}`}
  />
);

export default DateTimePicker;
