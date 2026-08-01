import { Controller } from "@hotwired/stimulus"

const THEME_KEY = "theme-preference"
const THEMES = ["light", "dark", "system"]

export default class extends Controller {
  static targets = ["sun", "moon", "monitor"]

  connect() {
    this.#applyTheme(this.#stored())
  }

  cycle() {
    const next = THEMES[(THEMES.indexOf(this.#stored()) + 1) % THEMES.length]
    localStorage.setItem(THEME_KEY, next)
    this.#applyTheme(next)
  }

  #stored() {
    return localStorage.getItem(THEME_KEY) || "system"
  }

  #applyTheme(theme) {
    const dark = theme === "dark" ||
      (theme === "system" &&
        window.matchMedia("(prefers-color-scheme: dark)").matches)
    document.documentElement.classList.toggle("dark", dark)
    this.sunTarget.classList.toggle("hidden", theme !== "light")
    this.moonTarget.classList.toggle("hidden", theme !== "dark")
    this.monitorTarget.classList.toggle("hidden", theme !== "system")
  }
}
