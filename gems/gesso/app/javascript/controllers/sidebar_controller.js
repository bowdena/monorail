import { Controller } from "@hotwired/stimulus"

const STORAGE_KEY = "sidebar-collapsed"

export default class extends Controller {
  connect() {
    if (localStorage.getItem(STORAGE_KEY) === "true") {
      this.element.dataset.collapsed = "true"
    }
  }

  toggle() {
    const collapsed = this.element.dataset.collapsed === "true"
    this.element.dataset.collapsed = !collapsed
    localStorage.setItem(STORAGE_KEY, !collapsed)
  }
}
