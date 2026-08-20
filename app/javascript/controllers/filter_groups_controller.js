import { Controller } from "@hotwired/stimulus"

// Independent disclosure per filter group: several can be open at once, and
// each button tints, flips its caret and reports its own field count. Which
// groups are open survives a filter submit, since the page reloads on it.
export default class extends Controller {
  static targets = ["group", "button", "panel"]

  static KEY = "cs-screener-groups"

  connect() {
    this.#restore()
  }

  toggle(event) {
    const name = event.currentTarget.dataset.group
    const group = this.#group(name)
    if (!group) return

    this.#apply(name, group.hidden)
    this.#persist()
  }

  #apply(name, open) {
    const group = this.#group(name)
    const button = this.buttonTargets.find((b) => b.dataset.group === name)
    if (group) group.hidden = !open
    if (button) button.setAttribute("aria-expanded", String(open))
    if (this.hasPanelTarget) {
      this.panelTarget.hidden = this.groupTargets.every((g) => g.hidden)
    }
  }

  #group(name) {
    return this.groupTargets.find((g) => g.dataset.group === name)
  }

  #open() {
    return this.groupTargets.filter((g) => !g.hidden).map((g) => g.dataset.group)
  }

  #persist() {
    try {
      sessionStorage.setItem(this.constructor.KEY, JSON.stringify(this.#open()))
    } catch (e) {
      // private mode: the panel still toggles, it just will not be remembered
    }
  }

  #restore() {
    let open = []
    try {
      open = JSON.parse(sessionStorage.getItem(this.constructor.KEY)) || []
    } catch (e) {
      open = []
    }

    this.groupTargets.forEach((g) => this.#apply(g.dataset.group, open.includes(g.dataset.group)))
  }
}
