import { CERTIFICATE_TEMPLATE, DETAILS_BOX, NAME_BOX } from '../models/certificateLayout'

export const SHEET_WIDTH = 842
export const SHEET_HEIGHT = 595

// The certificate at a fixed A4 landscape size (842 x 595, one unit per
// point): the design as a picture, the student's name on its line and the
// certificate number and date small at the foot (certificate_sheet.dart in
// the app). Paper colours, not theme colours: it looks the same in light
// and dark mode and on paper.
export default function CertificateSheet({ certificate: c, ref }) {
  return (
    <div
      ref={ref}
      role="img"
      aria-label={`Certificate of participation for ${c.studentName}. ${c.detailsLabel}`}
      className="relative overflow-hidden bg-white font-sans"
      style={{ width: SHEET_WIDTH, height: SHEET_HEIGHT }}
    >
      <img src={CERTIFICATE_TEMPLATE} alt="" width={SHEET_WIDTH} height={SHEET_HEIGHT} draggable="false" className="absolute inset-0 size-full select-none" />
      <p
        className="absolute text-center font-bold leading-[1.15] text-black"
        style={{ left: NAME_BOX.left, width: NAME_BOX.width, bottom: NAME_BOX.bottom, fontSize: c.nameSize }}
      >
        {c.studentName}
      </p>
      <p className="absolute whitespace-nowrap text-[7.5px] text-[#6b6270]" style={{ left: DETAILS_BOX.left, bottom: DETAILS_BOX.bottom }}>
        {c.detailsLabel}
      </p>
    </div>
  )
}
