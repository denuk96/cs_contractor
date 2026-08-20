import { Controller } from "@hotwired/stimulus"

// A clickable HTML legend for the item dashboards. Chart.js's own legend is
// switched off in favour of this one so it can carry the design's type and
// swatches, but the click does exactly what the built-in legend does — hide the
// series and let the axis rescale to what is left visible.
export default class extends Controller {
  static targets = ["list"]
  static values = { chartId: String }

  connect() {
    this.#whenReady((chart) => {
      this.chart = chart
      this.#render()
    })
  }

  disconnect() {
    clearTimeout(this.retry)
  }

  toggle(event) {
    const index = Number(event.currentTarget.dataset.index)
    this.chart.setDatasetVisibility(index, !this.chart.isDatasetVisible(index))
    this.chart.update()
    this.#render()
  }

  // Chartkick builds its charts from an inline script after this element is
  // parsed, so the chart may not exist yet on connect.
  #whenReady(callback, attempt = 0) {
    const chartkick = window.Chartkick?.charts?.[this.chartIdValue]
    const chart = chartkick?.getChartObject?.()

    if (chart) return callback(chart)
    if (attempt > 40) return

    this.retry = setTimeout(() => this.#whenReady(callback, attempt + 1), 50)
  }

  #render() {
    this.listTarget.innerHTML = ""

    this.chart.data.datasets.forEach((dataset, index) => {
      const visible = this.chart.isDatasetVisible(index)
      const button = document.createElement("button")
      button.type = "button"
      button.className = `legend-item${visible ? "" : " off"}`
      button.dataset.index = index
      button.dataset.action = "chart-legend#toggle"
      button.setAttribute("aria-pressed", String(visible))

      const swatch = document.createElement("span")
      swatch.className = "swatch"
      swatch.style.background = dataset.borderColor || dataset.backgroundColor

      button.append(swatch, document.createTextNode(dataset.label))
      this.listTarget.append(button)
    })
  }
}
