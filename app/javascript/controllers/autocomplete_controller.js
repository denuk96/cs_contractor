import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="autocomplete"
export default class extends Controller {
  static targets = ["input", "results"]
  static values = { url: String, minLength: { type: Number, default: 2 } }

  connect() {
    this.debounceTimeout = null
  }

  disconnect() {
    clearTimeout(this.debounceTimeout)
  }

  search() {
    clearTimeout(this.debounceTimeout)

    const query = this.inputTarget.value.trim()
    if (query.length < this.minLengthValue) {
      this.close()
      return
    }

    this.debounceTimeout = setTimeout(() => this.fetchResults(query), 200)
  }

  async fetchResults(query) {
    const response = await fetch(`${this.urlValue}?q=${encodeURIComponent(query)}`, {
      headers: { Accept: "application/json" }
    })
    if (!response.ok) return

    const names = await response.json()
    this.render(names)
  }

  render(names) {
    if (names.length === 0) {
      this.close()
      return
    }

    this.resultsTarget.innerHTML = names
      .map((name) => `<button type="button" class="list-group-item list-group-item-action py-1 text-truncate" data-action="click->autocomplete#select">${this.escapeHtml(name)}</button>`)
      .join("")
    this.resultsTarget.classList.remove("d-none")
  }

  select(event) {
    this.inputTarget.value = event.currentTarget.textContent
    this.close()
  }

  closeOnClickOutside(event) {
    if (!this.element.contains(event.target)) this.close()
  }

  close() {
    this.resultsTarget.innerHTML = ""
    this.resultsTarget.classList.add("d-none")
  }

  escapeHtml(value) {
    const div = document.createElement("div")
    div.textContent = value
    return div.innerHTML
  }
}
