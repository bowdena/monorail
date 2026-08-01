import { Controller } from "@hotwired/stimulus"

// basecoat's combobox clears its hidden input on every keystroke and
// keeps whatever was typed when focus leaves. A half-typed or unmatched
// entry then sits on screen with nothing submitted behind it — the field
// reads as one value and submits another, or silently drops the value it
// had. Remember each committed selection and put it back when focus
// leaves the combobox, so the field can only ever rest on a real option.
export default class extends Controller {
  connect() {
    this.selected = this.#hiddenInput.value
  }

  // basecoat dispatches its change event on the combobox root; the
  // visible input fires a native one of its own, which is not a
  // selection and must not be remembered.
  remember({ target }) {
    if (target !== this.element) return

    this.selected = this.#hiddenInput.value
  }

  restore({ relatedTarget }) {
    if (this.element.contains(relatedTarget)) return

    this.element.setValue?.(this.selected)
  }

  get #hiddenInput() {
    return this.element.querySelector("input[type='hidden']")
  }
}
