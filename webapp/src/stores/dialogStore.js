import { ChangeNotifier } from '../lib/ChangeNotifier'

// Open dialogs and bottom sheets, newest last. show() resolves with the value
// the dialog closes with, like Flutter's showDialog, so a flow can await the
// student's choice.
class DialogStore extends ChangeNotifier {
  stack = []
  #nextId = 1

  // [render](close) returns the dialog's content. [dismissValue] is what an
  // outside tap or Escape resolves with; dismissible: false turns those off.
  show(render, { kind = 'dialog', dismissible = true, dismissValue = null } = {}) {
    return new Promise((resolve) => {
      const id = this.#nextId++
      const close = (value) => {
        if (!this.stack.some((d) => d.id === id)) return
        this.stack = this.stack.filter((d) => d.id !== id)
        this.notifyListeners()
        resolve(value)
      }
      this.stack = [...this.stack, { id, render, kind, dismissible, dismiss: () => close(dismissValue), close }]
      this.notifyListeners()
    })
  }

  // Closes everything (a timed-out submit closes an open "Submit Quiz?").
  closeAll() {
    for (const dialog of [...this.stack].reverse()) dialog.dismiss()
  }
}

export const dialogStore = new DialogStore()
