import { useEffect } from 'react'
import { blockCopy } from '../../lib/blockCopy'

// Wraps a page whose text must not be copied (a quiz and its answers):
// nothing inside can be selected, and copy, paste and the right-click menu
// do nothing while it is on screen.
export default function NoCopy({ className = '', children }) {
  useEffect(() => blockCopy(document), [])
  return <div className={`select-none [-webkit-touch-callout:none] ${className}`}>{children}</div>
}
