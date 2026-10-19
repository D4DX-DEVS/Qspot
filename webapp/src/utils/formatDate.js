// Date wording used across the quiz screens, matching the app.

const MONTHS_SHORT = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
const MONTHS_LONG = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December']

// "7/10/2026"
export const dayMonthYear = (d) => `${d.getDate()}/${d.getMonth() + 1}/${d.getFullYear()}`

// "7/10/2026 at 9:05"
export const dateAtTime = (d) => `${dayMonthYear(d)} at ${d.getHours()}:${String(d.getMinutes()).padStart(2, '0')}`

// "9:05 am"
export function clockTime(d) {
  const hours = d.getHours() % 12 === 0 ? 12 : d.getHours() % 12
  return `${hours}:${String(d.getMinutes()).padStart(2, '0')} ${d.getHours() < 12 ? 'am' : 'pm'}`
}

// "9:05 AM", like Flutter's TimeOfDay.format.
export const clockTimeUpper = (d) => clockTime(d).toUpperCase()

// "7 Oct"
export const dayShortMonth = (d) => `${d.getDate()} ${MONTHS_SHORT[d.getMonth()]}`

// "7 October 2026"
export const dayLongMonthYear = (d) => `${d.getDate()} ${MONTHS_LONG[d.getMonth()]} ${d.getFullYear()}`

export const sameDay = (a, b) =>
  a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate()

// "today 6:10 pm" / "tomorrow 9:00 am" / "26 Oct".
export function whenLabel(date, now = new Date()) {
  const tomorrow = new Date(now.getFullYear(), now.getMonth(), now.getDate() + 1)
  if (sameDay(date, now)) return `today ${clockTime(date)}`
  if (sameDay(date, tomorrow)) return `tomorrow ${clockTime(date)}`
  return dayShortMonth(date)
}
