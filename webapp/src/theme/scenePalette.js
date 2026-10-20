import { AUTH_PALETTE } from './authPalette'

// Colours of the drawn night scenes (sign-in, home and quiz artwork). The
// pictures stay at night in light mode too; only the page around them
// changes. Builds on the app's dark artwork palette, so the lanterns, book
// stand and skyline match the other screens.
export const NIGHT_PALETTE = {
  ...AUTH_PALETTE.dark,
  skyTop: '#0E0B24',
  skyMid: '#2A1745',
  skyLow: '#6A2852',
  horizon: '#D9734F',
  horizonGlow: '#F39A5B',
  star: '#FFF3D6',
  skylineBack: '#3A2343',
  skylineFar: '#21162D',
  skylineNear: '#110C19',
  window: '#F2A65E',
  waterTop: '#4A2041',
  water: '#120E26',
  floorTop: '#2A1220',
  floor: '#140B14',
  carpet: '#5A1A2C',
  archFrame: '#120E1C',
  archEdge: '#D9894F',
}
