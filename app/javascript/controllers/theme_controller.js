import { Controller } from "@hotwired/stimulus"

// Flips data-theme on the root element and remembers the choice. data-bs-theme
// is kept in step so Bootstrap's own primitives and the native scrollbar, date
// and select controls follow the same theme.
export default class extends Controller {
  static targets = ["toggle"]

  static KEY = "cs-theme"

  connect() {
    this.#label()
  }

  toggle() {
    const next = this.#current() === "dark" ? "light" : "dark"
    document.documentElement.setAttribute("data-theme", next)
    document.documentElement.setAttribute("data-bs-theme", next)
    try {
      localStorage.setItem(this.constructor.KEY, next)
    } catch (e) {
      // private mode: the theme still applies, it just will not persist
    }
    this.#label()
  }

  #current() {
    return document.documentElement.getAttribute("data-theme") === "light" ? "light" : "dark"
  }

  // The button names the theme it switches *to*, not the one in effect.
  #label() {
    if (this.hasToggleTarget) {
      this.toggleTarget.textContent = this.#current() === "dark" ? "LIGHT" : "DARK"
    }
  }
}
