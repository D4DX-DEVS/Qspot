// Artwork colours for the sign-in screens (mobile-app/lib/themes/auth_palette.dart).
// The page colours themselves come from CSS variables in index.css.
export const AUTH_PALETTE = {
  light: {
    background: '#FBF7F3',
    archFill: '#FFFDFA',
    archHalo: '#F6E8E0',
    archEdge: '#EBD3C5',
    lanternFrame: '#C9A07A',
    lanternGlow: '#FFE3B8',
    skylineFar: '#F0DDD6',
    skylineNear: '#E2C6BF',
    window: '#F8EAE2',
    moon: '#F3C58F',
    floor: '#F1E0D6',
    wood: '#8E5230',
    pages: '#FFF9EF',
    waveSoft: '#F6DFDF',
    waveMid: '#EECBCB',
    cornerStart: '#8C1D4B',
    cornerEnd: '#D96A73',
  },
  dark: {
    background: '#0C0E1A',
    archFill: '#080913',
    archHalo: '#1A1320',
    archEdge: '#D9894F',
    lanternFrame: '#B8844C',
    lanternGlow: '#FFC266',
    skylineFar: '#2A1F2C',
    skylineNear: '#17121D',
    window: '#D98A5E',
    moon: '#FFE7A6',
    floor: '#1B1520',
    wood: '#7A4222',
    pages: '#EADBC0',
    waveSoft: '#1D1B2B',
    waveMid: '#2A1420',
    cornerStart: '#5B0E2E',
    cornerEnd: '#2A1420',
  },
}

// "#RRGGBB" with an alpha (0..1) as rgba().
export function withAlpha(hex, alpha) {
  const n = parseInt(hex.slice(1), 16)
  return `rgba(${(n >> 16) & 255}, ${(n >> 8) & 255}, ${n & 255}, ${alpha})`
}
