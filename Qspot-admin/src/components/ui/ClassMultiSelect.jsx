import { useEffect, useId, useRef, useState } from 'react';
import { FiCheck, FiChevronDown, FiX } from 'react-icons/fi';

const CLASS_NUMBERS = Array.from({ length: 12 }, (_, index) => String(index + 1));
const isClassNumber = (value) => CLASS_NUMBERS.includes(value);

// 1-12 in number order, then any other saved values alphabetically.
const byClassOrder = (a, b) => {
  if (isClassNumber(a) && isClassNumber(b)) return Number(a) - Number(b);
  if (isClassNumber(a) !== isClassNumber(b)) return isClassNumber(a) ? -1 : 1;
  return a.localeCompare(b);
};

const chipLabel = (value) => (isClassNumber(value) ? `Class ${value}` : value);

// Dropdown for picking any number of classes from 1 to 12. Values are the
// bare numbers ("8") the app registers students with, so they match exactly
// on the server. An empty selection means every class.
//
// A record may already hold a value outside 1-12 (typed by hand before this
// dropdown existed). It stays selected and shows as a removable chip, so
// opening and saving a form never drops it silently.
const ClassMultiSelect = ({
  value = [],
  onChange,
  labelId,
  placeholder = 'All classes',
  disabled = false,
  className = ''
}) => {
  const [open, setOpen] = useState(false);
  const rootRef = useRef(null);
  const panelId = useId();
  const isOpen = open && !disabled;
  const selected = [...new Set(value.map((item) => String(item).trim()).filter(Boolean))].sort(byClassOrder);

  // Close on a click outside or Escape.
  useEffect(() => {
    if (!isOpen) return undefined;
    const onPointerDown = (event) => {
      if (!rootRef.current?.contains(event.target)) setOpen(false);
    };
    const onKeyDown = (event) => {
      if (event.key === 'Escape') {
        event.stopPropagation();
        setOpen(false);
      }
    };
    document.addEventListener('mousedown', onPointerDown);
    document.addEventListener('keydown', onKeyDown, true);
    return () => {
      document.removeEventListener('mousedown', onPointerDown);
      document.removeEventListener('keydown', onKeyDown, true);
    };
  }, [isOpen]);

  const toggle = (item) => onChange(
    selected.includes(item) ? selected.filter((value) => value !== item) : [...selected, item].sort(byClassOrder)
  );
  const remove = (item) => onChange(selected.filter((value) => value !== item));
  const extras = selected.filter((item) => !isClassNumber(item));

  return (
    <div ref={rootRef} className={`relative text-sm font-normal normal-case tracking-normal ${className}`}>
      <div
        className={`flex min-h-[42px] w-full items-center gap-2 rounded-xl border bg-white/5 px-3 py-1.5 text-white transition ${isOpen ? 'border-[#EFB078]/60' : 'border-white/15'} ${disabled ? 'cursor-not-allowed opacity-50' : 'cursor-pointer'}`}
        onClick={() => !disabled && setOpen((current) => !current)}
      >
        <div className="flex min-w-0 flex-1 flex-wrap items-center gap-1.5">
          {selected.map((item) => (
            <span key={item} className="inline-flex items-center gap-1 rounded-lg border border-[#EFB078]/30 bg-[#EFB078]/10 py-0.5 pl-2 pr-1 text-xs font-semibold text-[#F5D3B0]">
              {chipLabel(item)}
              <button
                type="button"
                disabled={disabled}
                onClick={(event) => {
                  event.stopPropagation();
                  remove(item);
                }}
                aria-label={`Remove ${chipLabel(item)}`}
                className="rounded p-0.5 text-[#F5D3B0]/70 hover:bg-white/10 hover:text-white"
              >
                <FiX size={12} />
              </button>
            </span>
          ))}
          <button
            type="button"
            disabled={disabled}
            aria-haspopup="true"
            aria-expanded={isOpen}
            aria-controls={panelId}
            aria-labelledby={labelId}
            className="min-w-[6rem] flex-1 py-1 text-left text-white/45 focus:outline-none disabled:cursor-not-allowed"
          >
            {selected.length === 0 ? placeholder : <span className="sr-only">Change classes</span>}
          </button>
        </div>
        <FiChevronDown className={`flex-shrink-0 text-white/55 transition-transform ${isOpen ? 'rotate-180' : ''}`} />
      </div>

      {isOpen && (
        <div
          id={panelId}
          role="group"
          aria-labelledby={labelId}
          className="absolute left-0 right-0 top-full z-40 mt-2 rounded-2xl border border-white/12 bg-[#150a19] p-3 shadow-[0_18px_40px_rgba(0,0,0,0.55)]"
        >
          <div className="grid grid-cols-4 gap-2 sm:grid-cols-6">
            {CLASS_NUMBERS.map((item) => {
              const checked = selected.includes(item);
              return (
                <button
                  key={item}
                  type="button"
                  aria-pressed={checked}
                  aria-label={`Class ${item}`}
                  onClick={() => toggle(item)}
                  className={`relative flex h-10 items-center justify-center rounded-xl border text-sm font-semibold transition ${checked ? 'border-[#EFB078]/70 bg-[#EFB078]/20 text-white' : 'border-white/10 bg-white/5 text-white/70 hover:border-white/25 hover:text-white'}`}
                >
                  {item}
                  {checked && <FiCheck size={11} className="absolute right-1.5 top-1.5 text-[#EFB078]" />}
                </button>
              );
            })}
          </div>
          {extras.length > 0 && (
            <p className="mt-3 text-xs text-white/50">
              Also saved: {extras.join(', ')}. Remove with × above if no longer needed.
            </p>
          )}
          <div className="mt-3 flex items-center justify-between gap-2 border-t border-white/10 pt-3">
            <div className="flex gap-1">
              <button type="button" onClick={() => onChange([...CLASS_NUMBERS, ...extras])} className="rounded-lg px-2.5 py-1.5 text-xs font-semibold text-white/70 hover:bg-white/10 hover:text-white">Select all</button>
              <button type="button" onClick={() => onChange([])} className="rounded-lg px-2.5 py-1.5 text-xs font-semibold text-white/70 hover:bg-white/10 hover:text-white">Clear</button>
            </div>
            <button type="button" onClick={() => setOpen(false)} className="rounded-lg bg-white/10 px-3 py-1.5 text-xs font-semibold text-white hover:bg-white/15">Done</button>
          </div>
        </div>
      )}
    </div>
  );
};

export default ClassMultiSelect;
