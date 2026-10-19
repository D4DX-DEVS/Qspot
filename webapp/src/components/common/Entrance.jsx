// Fades and slides its content up when it first appears; give list items an
// [index] and they arrive 60ms apart (StaggeredEntrance in the app). Items
// past the eighth start straight away.
export default function Entrance({ index = 0, rise = 20, as: Tag = 'div', className = '', children, ...rest }) {
  const delay = index < 8 ? index * 60 : 0
  return (
    <Tag className={`qs-enter ${className}`} style={{ '--qs-delay': `${delay}ms`, '--qs-rise': `${rise}px` }} {...rest}>
      {children}
    </Tag>
  )
}
