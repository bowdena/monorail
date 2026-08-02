import { Controller } from "@hotwired/stimulus"

// Toggles a button into a loading state: shows the spinner and disables
// the button so it cannot be activated twice (e.g. on form submit).
export default class extends Controller {
  static targets = ["spinner"]
  static values = { loading: Boolean }

  load() {
    this.loadingValue = true
  }

  loadingValueChanged() {
    this.spinnerTarget.classList.toggle("hidden", !this.loadingValue)

    // Disabling a submit button while its own click is still being
    // dispatched cancels the submission, so the button stays enabled
    // until the browser has acted on the click.
    setTimeout(() => { this.element.disabled = this.loadingValue })
  }
}
