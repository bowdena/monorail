import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel"]

  open() {
    this.panelTarget.showModal()
  }

  close() {
    this.panelTarget.close()
  }

  backdropClick(event) {
    if (event.target === this.panelTarget) this.close()
  }
}
