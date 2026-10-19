// Accent tones (mobile-app/lib/themes/accent_tone.dart): a strong colour and
// the soft tint drawn behind it. Full class names so Tailwind finds them.
export const TONES = {
  rose: { text: 'text-rose', soft: 'bg-rose-soft', border: 'border-rose', color: 'var(--qs-rose)' },
  coral: { text: 'text-coral', soft: 'bg-coral-soft', border: 'border-coral', color: 'var(--qs-coral)' },
  amber: { text: 'text-amber', soft: 'bg-amber-soft', border: 'border-amber', color: 'var(--qs-amber)' },
  teal: { text: 'text-teal', soft: 'bg-teal-soft', border: 'border-teal', color: 'var(--qs-teal)' },
  mint: { text: 'text-mint', soft: 'bg-mint-soft', border: 'border-mint', color: 'var(--qs-mint)' },
  slate: { text: 'text-slate', soft: 'bg-slate-soft', border: 'border-slate', color: 'var(--qs-slate)' },
}

export const tone = (name) => TONES[name] ?? TONES.slate
