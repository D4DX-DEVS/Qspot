// One-of-a-few choice shown as a row of pills (e.g. Student / Teacher).
// options: [{ value, label }].
const SegmentedControl = ({ options, value, onChange, label }) => (
  <div
    role="radiogroup"
    aria-label={label}
    className="grid gap-1 rounded-2xl border border-white/10 bg-white/5 p-1"
    style={{ gridTemplateColumns: `repeat(${options.length}, minmax(0, 1fr))` }}
  >
    {options.map((option) => {
      const selected = option.value === value;
      return (
        <button
          key={option.value}
          type="button"
          role="radio"
          aria-checked={selected}
          onClick={() => onChange(option.value)}
          className={`rounded-xl px-4 py-2.5 text-sm font-semibold transition-all ${
            selected
              ? 'bg-gradient-to-r from-[#701845]/90 via-[#9E4B63]/80 to-[#EFB078]/85 text-white shadow-[0_8px_20px_rgba(112,24,69,0.3)]'
              : 'text-white/60 hover:bg-white/5 hover:text-white'
          }`}
        >
          {option.label}
        </button>
      );
    })}
  </div>
);

export default SegmentedControl;
