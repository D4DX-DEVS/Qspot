// The sign-in field look (AuthTheme's input decoration): filled, 16px
// corners, a hairline border that turns brand (with a soft glow) on focus
// and red on error, and the error line underneath.
export default function AuthFieldFrame({ error, prefix, children, interactive = false }) {
  const border = error
    ? 'border-danger focus-within:border-[1.6px]'
    : 'border-field-line focus-within:border-[1.6px] focus-within:border-brand'
  return (
    <div>
      <div className={`relative flex min-h-14 items-center rounded-2xl border-[1.2px] bg-field transition-[border-color,box-shadow] duration-200 focus-within:shadow-[0_0_0_4px_var(--qs-focus-ring)] ${border} ${interactive ? 'qs-press [--qs-press:0.98]' : ''}`}>
        {prefix}
        {children}
      </div>
      {error ? (
        <p role="alert" className="px-[18px] pt-1.5 text-xs text-danger">
          {error}
        </p>
      ) : null}
    </div>
  )
}
