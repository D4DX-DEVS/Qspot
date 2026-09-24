// Single inline-SVG placeholder used everywhere an image is missing
// (speaker photo, subject/course cover, video thumbnail, banner). Avoids
// third-party placeholder requests (picsum.photos etc.) and duplicated
// hand-rolled SVGs per page.
export const PLACEHOLDER_IMAGE =
  'data:image/svg+xml;utf8,' +
  encodeURIComponent(
    `<svg xmlns="http://www.w3.org/2000/svg" width="400" height="400" viewBox="0 0 400 400">
      <rect width="400" height="400" fill="#1c0b18"/>
      <path d="M200 130a45 45 0 1 0 0 90 45 45 0 0 0 0-90Zm0 110c-53 0-100 27-100 60v30h200v-30c0-33-47-60-100-60Z" fill="#701845" opacity="0.6"/>
    </svg>`
  );
