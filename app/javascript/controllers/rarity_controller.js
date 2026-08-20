import { Controller } from "@hotwired/stimulus"

// The rarity chips are a styled single select: the query takes one rarity, so
// picking a chip writes it into the hidden field and clicking the active chip
// clears it back to "all rarities".
export default class extends Controller {
  static values = { selected: String }

  pick(event) {
    const chip = event.currentTarget
    const value = chip.dataset.value === this.selectedValue ? "" : chip.dataset.value

    this.selectedValue = value
    this.#input().value = value

    this.element.querySelectorAll(".rarity-chip").forEach((c) => {
      c.classList.toggle("on", c.dataset.value === value && value !== "")
    })
  }

  #input() {
    return this.element.closest("form").querySelector('input[name="rarity"]')
  }
}
