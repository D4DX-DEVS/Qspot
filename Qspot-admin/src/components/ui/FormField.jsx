// Label + field + optional hint line in the dialog style used across the admin
// panel. Pass the input or select as children. An error replaces the hint, in
// red; give it errorId and point the input's aria-describedby at it.
const FormField = ({ label, htmlFor, hint, hintWarn = false, error, errorId, children }) => (
  <div>
    <label htmlFor={htmlFor} className="text-xs font-semibold uppercase tracking-[0.18em] text-white/65">
      {label}
    </label>
    <div className="mt-2">{children}</div>
    {error ? (
      <p id={errorId} role="alert" className="mt-1.5 text-xs font-medium text-red-300">{error}</p>
    ) : (
      hint && <p className={`mt-1.5 text-xs ${hintWarn ? 'text-amber-200' : 'text-white/45'}`}>{hint}</p>
    )}
  </div>
);

export default FormField;
