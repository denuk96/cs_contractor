import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["minFloat", "maxFloat", "currentFloat", "result", "adjValue", "interpretation"]

  calculate() {
    const min = parseFloat(this.minFloatTarget.value)
    const max = parseFloat(this.maxFloatTarget.value)
    const current = parseFloat(this.currentFloatTarget.value)

    if (isNaN(min) || isNaN(max) || isNaN(current)) {
      this.resultTarget.classList.add("d-none")
      return
    }

    const cap = max - min
    if (cap <= 0) {
      this.resultTarget.classList.add("d-none")
      return
    }

    if (current < min || current > max) {
      this.resultTarget.classList.add("d-none")
      return
    }

    const adj = (current - min) / cap
    this.adjValueTarget.textContent = adj.toFixed(4)
    this.interpretationTarget.textContent = this.#interpret(adj)
    this.resultTarget.classList.remove("d-none")
  }

  #interpret(adj) {
    if (adj < 0.14) return "Factory New range"
    if (adj < 0.30) return "Minimal Wear range"
    if (adj < 0.76) return "Field-Tested range"
    if (adj < 0.90) return "Well-Worn range"
    return "Battle-Scarred range"
  }
}
