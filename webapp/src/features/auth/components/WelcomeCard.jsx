import GlassCard from '../../../components/common/GlassCard'

// The sign-in card: warm-rimmed glass with a centred title and subtitle over
// the form. On phones and tablets it is a sheet rising from the bottom of
// the screen, edge to edge; on wide screens a floating card.
export default function WelcomeCard({ title, subtitle, children }) {
  return (
    <GlassCard
      rim
      radius="rounded-t-[28px] lg:rounded-[28px]"
      padding="px-5 pb-[calc(28px+env(safe-area-inset-bottom))] pt-7 sm:px-10 lg:py-10"
      className="flex-1 border-x-0 border-b-0 bg-card lg:flex-none lg:border lg:bg-glass"
    >
      <div className="mx-auto w-full max-w-[440px] lg:max-w-none">
        <h2 className="text-center text-2xl font-bold text-ink sm:text-[32px]">{title}</h2>
        <p className="mt-1.5 text-center text-sm text-muted sm:mt-2 sm:text-base">{subtitle}</p>
        <div className="mt-6 sm:mt-7">{children}</div>
      </div>
    </GlassCard>
  )
}
