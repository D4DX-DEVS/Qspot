// Copying, cutting, pasting, dragging and the right-click / long-press menu
// do nothing on [target] (the whole page while a quiz is open). Returns the
// undo, for a React effect's cleanup.
const BLOCKED = ['copy', 'cut', 'paste', 'contextmenu', 'dragstart']

export function blockCopy(target) {
  const stop = (event) => event.preventDefault()
  for (const type of BLOCKED) target.addEventListener(type, stop, true)
  return () => {
    for (const type of BLOCKED) target.removeEventListener(type, stop, true)
  }
}
