import AuthFieldFrame from './AuthFieldFrame'

// Themed single-line field with an optional leading icon or custom [prefix].
export default function AuthTextField({ label, value, onChange, error, icon: Icon, prefix, inputMode, autoComplete, autoCapitalize, maxLength, type = 'text' }) {
  const lead =
    prefix ??
    (Icon ? (
      <span className="grid w-12 shrink-0 place-items-center pl-1 text-field-icon" aria-hidden="true">
        <Icon size={22} />
      </span>
    ) : null)
  return (
    <AuthFieldFrame error={error} prefix={lead}>
      <input
        type={type}
        value={value}
        onChange={(e) => onChange(e.target.value)}
        placeholder={label}
        aria-label={label}
        aria-invalid={error ? 'true' : undefined}
        inputMode={inputMode}
        autoComplete={autoComplete}
        autoCapitalize={autoCapitalize}
        maxLength={maxLength}
        className={`h-14 min-w-0 flex-1 bg-transparent pr-[18px] text-base text-ink outline-none placeholder:text-[15px] placeholder:text-muted ${lead ? '' : 'pl-[18px]'}`}
      />
    </AuthFieldFrame>
  )
}
