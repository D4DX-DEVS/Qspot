// Flag + country code + divider before a phone number. Always visible, so an
// empty field still reads as a phone input.
export default function CountryCodePrefix({ leftPadding = 18 }) {
  return (
    <span className="flex shrink-0 items-center pr-3" style={{ paddingLeft: leftPadding }} aria-hidden="true">
      <span className="text-lg leading-none">🇮🇳</span>
      <span className="ml-2 text-base font-medium text-ink">+91</span>
      <span className="ml-3 h-[22px] w-px bg-line" />
    </span>
  )
}
