// Rounded outlined brand button on the card colour ("Try Again").
export default function SoftOutlineButton({ icon: Icon, label, onClick }) {
  return (
    <button
      type="button"
      onClick={onClick}
      className="qs-press inline-flex min-h-[54px] items-center justify-center gap-2 rounded-2xl border-[1.4px] border-brand/35 bg-card px-7 text-[15px] font-semibold text-brand"
    >
      <Icon size={20} aria-hidden="true" />
      {label}
    </button>
  )
}
