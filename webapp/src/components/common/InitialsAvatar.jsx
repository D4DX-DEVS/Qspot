import { nameInitials } from '../../utils/nameInitials'

// Round burgundy avatar with up to two initials (same in light and dark).
export default function InitialsAvatar({ name, size = 44 }) {
  return (
    <span
      aria-hidden="true"
      className="grid shrink-0 place-items-center rounded-full bg-[#740c3b] font-bold text-white shadow-[0_4px_10px_rgb(116_12_59/0.25)]"
      style={{ width: size, height: size, fontSize: size * 0.36 }}
    >
      {nameInitials(name)}
    </span>
  )
}
