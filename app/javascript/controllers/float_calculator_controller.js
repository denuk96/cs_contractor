import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "scrim", "minFloat", "maxFloat", "currentFloat",
    "result", "adjValue", "interpretation", "strip", "stripLabels", "marker",
    "termNumerator", "termCap",
    "error", "errorTitle", "errorBody"
  ]

  // Cut points on the ADJUSTED float. They differ from the raw-float wear
  // bands on purpose — that difference is what the tool exists to show.
  static BANDS = [
    { slug: "fn", max: 0.14, name: "Factory New" },
    { slug: "mw", max: 0.30, name: "Minimal Wear" },
    { slug: "ft", max: 0.76, name: "Field-Tested" },
    { slug: "ww", max: 0.90, name: "Well-Worn" },
    { slug: "bs", max: Infinity, name: "Battle-Scarred" }
  ]

  open() {
    this.scrimTarget.hidden = false
    this.minFloatTarget.focus()
  }

  close() {
    this.scrimTarget.hidden = true
  }

  closeFromScrim(event) {
    if (event.target === this.scrimTarget) this.close()
  }

  closeOnEscape(event) {
    if (event.key === "Escape" && !this.scrimTarget.hidden) this.close()
  }

  calculate() {
    const min = parseFloat(this.minFloatTarget.value)
    const max = parseFloat(this.maxFloatTarget.value)
    const current = parseFloat(this.currentFloatTarget.value)

    if (isNaN(min) || isNaN(max) || isNaN(current)) {
      this.#explain(
        "Waiting for input",
        "Enter a min float, a max float and the item's float to see its adjusted value."
      )
      return
    }

    const cap = max - min
    if (cap <= 0) {
      this.#explain(
        "Invalid range",
        "Max float must be greater than min float — the range would otherwise have no width."
      )
      return
    }

    if (current < min || current > max) {
      this.#explain(
        "Float outside the range",
        "An item's float always sits inside its skin's own min–max range, so this pairing can't exist."
      )
      return
    }

    this.#render((current - min) / cap, current - min, cap)
  }

  #render(adj, numerator, cap) {
    const band = this.constructor.BANDS.find((b) => adj < b.max) ?? this.constructor.BANDS.at(-1)
    const on = `on-${band.slug}`

    this.adjValueTarget.textContent = adj.toFixed(4)
    this.interpretationTarget.textContent = `${band.name} range`
    this.termNumeratorTarget.textContent = numerator.toFixed(4)
    this.termCapTarget.textContent = cap.toFixed(4)

    this.#setBandClass(this.adjValueTarget, on)
    this.#setBandClass(this.interpretationTarget, on)
    this.#setBandClass(this.stripTarget, on)
    this.#setBandClass(this.stripLabelsTarget, on)

    this.stripLabelsTarget.querySelectorAll("[data-band]").forEach((label) => {
      label.classList.toggle("on", label.dataset.band === band.slug)
    })

    this.markerTarget.style.left = `${(adj * 100).toFixed(2)}%`

    this.errorTarget.hidden = true
    this.resultTarget.hidden = false
  }

  // Each blank-out condition gets a named state rather than an empty card, so
  // the user learns why the result is missing.
  #explain(title, body) {
    this.errorTitleTarget.textContent = title
    this.errorBodyTarget.textContent = body
    this.resultTarget.hidden = true
    this.errorTarget.hidden = false
  }

  #setBandClass(element, on) {
    this.constructor.BANDS.forEach((b) => element.classList.remove(`on-${b.slug}`))
    element.classList.add(on)
  }
}
