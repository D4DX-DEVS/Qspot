import { tone as toneOf } from '../../../theme/tones'

// Tinted banner with an icon, a message and action pills underneath, used for
// answers waiting to be sent and answers that were refused.
export default function QuizNoticeBanner({ icon: Icon, tone, message, children }) {
  const t = toneOf(tone)
  return (
    <div role="status" className={`rounded-[18px] p-4 ${t.soft}`}>
      <div className="flex items-start gap-3">
        <Icon size={22} className={`shrink-0 ${t.text}`} aria-hidden="true" />
        <p className="text-[13px] leading-normal text-ink">{message}</p>
      </div>
      <div className="mt-2.5 flex flex-wrap justify-end gap-2">{children}</div>
    </div>
  )
}
