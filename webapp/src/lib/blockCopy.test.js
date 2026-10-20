import { describe, expect, it } from 'vitest'
import { blockCopy } from './blockCopy'

const fire = (target, type) => {
  const event = new Event(type, { cancelable: true, bubbles: true })
  target.dispatchEvent(event)
  return event.defaultPrevented
}

describe('blockCopy', () => {
  it('stops copy, cut, paste, the context menu and dragging', () => {
    const page = new EventTarget()
    blockCopy(page)
    for (const type of ['copy', 'cut', 'paste', 'contextmenu', 'dragstart']) {
      expect(fire(page, type)).toBe(true)
    }
  })

  it('leaves other events alone', () => {
    const page = new EventTarget()
    blockCopy(page)
    expect(fire(page, 'click')).toBe(false)
    expect(fire(page, 'keydown')).toBe(false)
  })

  it('lets copying work again once undone', () => {
    const page = new EventTarget()
    const undo = blockCopy(page)
    undo()
    expect(fire(page, 'copy')).toBe(false)
    expect(fire(page, 'contextmenu')).toBe(false)
  })
})
