// The one place quiz code reads the time (like package:clock in the app), so
// tests can move time forward. Milliseconds since the epoch.
export const clock = {
  now: () => Date.now(),
}
