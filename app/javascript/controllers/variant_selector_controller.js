import { Controller } from "@hotwired/stimulus"

// Toggles which finish (Normal / StatTrak™ / Souvenir) price panel is shown.
// Connects to data-controller="variant-selector"
export default class extends Controller {
  static targets = ["tab", "panel"]
  static values = { current: String }

  connect() {
    const available = this.panelTargets.map((p) => p.dataset.finish)
    const initial = available.includes(this.currentValue) ? this.currentValue : available[0]
    if (initial) this.activate(initial)
  }

  select(event) {
    this.activate(event.currentTarget.dataset.finish)
  }

  activate(finish) {
    this.tabTargets.forEach((tab) => {
      const active = tab.dataset.finish === finish
      tab.classList.toggle("active", active)
      tab.setAttribute("aria-pressed", active)
    })
    this.panelTargets.forEach((panel) => {
      panel.hidden = panel.dataset.finish !== finish
    })
  }
}
