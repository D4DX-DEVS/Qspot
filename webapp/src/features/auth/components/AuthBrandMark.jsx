// The QSPOT mark, centred. The image carries ~20% clear margin on each side,
// so [size] is the box, not the visible mark.
export default function AuthBrandMark({ size = 150 }) {
  return (
    <div className="flex justify-center">
      <img src="/qspot-mark.png" alt="QSPOT" width={size} height={size} className="object-contain" style={{ width: size, height: size }} />
    </div>
  )
}
