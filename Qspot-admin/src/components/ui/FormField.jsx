// Label + field + optional hint line in the dialog style used across the admin
// panel. Pass the input or select as children.
const FormField = ({ label, htmlFor, hint, hintWarn = false, children }) => (
  <div>
    <label htmlFor={htmlFor} className="text-xs font-semibold uppercase tracking-[0.18em] text-white/65">
      {label}
    </label>
    <div className="mt-2">{children}</div>
    {hint && <p className={`mt-1.5 text-xs ${hintWarn ? 'text-amber-200' : 'text-white/45'}`}>{hint}</p>}
  </div>
);

export default FormField;
