export const SHEET_WIDTH = 842
export const SHEET_HEIGHT = 595

const serif = { fontFamily: 'Georgia, "Times New Roman", serif' }

// The printable certificate at a fixed A4 landscape size (842 x 595), laid out
// like the app's CertificateSheet (the admin panel's print layout scaled by
// 0.75). Paper colours, not theme colours: it looks the same in light and
// dark mode and on paper.
export default function CertificateSheet({ certificate: c, ref }) {
  return (
    <div ref={ref} className="bg-[#f7f1eb] p-[51px]" style={{ width: SHEET_WIDTH, height: SHEET_HEIGHT }}>
      <div className="relative size-full border-[2.25px] border-[#701845]" style={{ background: 'linear-gradient(to bottom right, #fffaf6, #f8e9ee)' }}>
        <div className="pointer-events-none absolute inset-5 border-[0.75px] border-[#e0ae73]" />
        <div className="absolute inset-0 flex flex-col items-center justify-center px-[34px] pb-[50px] pt-[34px] text-center leading-[1.3]" style={serif}>
          <p className="text-[9px] uppercase tracking-[3.15px] text-[#701845]">{c.issuerName}</p>
          <p className="mt-[10.5px] text-[28.5px] font-bold text-[#701845]">{c.title}</p>
          <p className="mt-1.5 text-xs text-[#111827]">This certificate is proudly presented to</p>
          <p className="mt-[9px] line-clamp-2 text-[31.5px] font-bold text-[#111827]">{c.studentName}</p>
          <p className="mt-[9px] line-clamp-4 max-w-[465px] text-[13.5px] leading-normal text-[#4b4350]">
            {c.description}
            <br />
            <strong>{c.examTitle}</strong>
          </p>
          <div className="mt-[21px] flex justify-center gap-[52px] text-[10.5px] text-[#5c5360]">
            <span>
              Score
              <br />
              <strong>{c.percentageLabel}</strong>
            </span>
            {c.issuedLabel ? (
              <span>
                Issued
                <br />
                <strong>{c.issuedLabel}</strong>
              </span>
            ) : null}
          </div>
          <p className="mt-[21px] min-w-[135px] border-t-[0.75px] border-[#701845] pt-1.5 text-[10.5px] text-[#111827]">{c.signatoryName}</p>
        </div>
        <p className="absolute inset-x-0 bottom-[34px] text-center font-sans text-[9px] text-[#6b6270]">Certificate No. {c.certificateNumber}</p>
      </div>
    </div>
  )
}
