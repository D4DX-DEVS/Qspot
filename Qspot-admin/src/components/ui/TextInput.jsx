// Text, phone, email or date box in the admin dialog style. Passes every other
// prop (id, required, min, max…) to the <input>.
const TextInput = ({ value, onChange, type = 'text', className = '', ...props }) => (
  <input
    type={type}
    value={value}
    onChange={(e) => onChange(e.target.value)}
    className={`block w-full rounded-2xl border border-white/10 bg-white/5 px-4 py-3 text-sm text-white placeholder-white/40 [color-scheme:dark] focus:border-[#EFB078]/60 focus:outline-none ${className}`}
    {...props}
  />
);

export default TextInput;
