// The crosshair the designs call for: on mousemove, a dashed vertical line at
// the nearest index, a dot on every visible series, and one tooltip listing
// each visible series' value at that date.
//
// Chart.js gives the index-mode tooltip and the hover dots; the vertical rule
// is ours to draw. Charts that switch their tooltip off — the feed sparklines —
// opt out of the whole thing.
import "Chart.bundle"

function enabled(chart) {
  return chart.options?.plugins?.tooltip?.enabled !== false
}

Chart.register({
  id: "crosshair",

  afterDatasetsDraw(chart) {
    if (!enabled(chart)) return

    const active = chart.tooltip?._active
    if (!active?.length) return

    const { ctx, chartArea } = chart
    const x = active[0].element.x

    ctx.save()
    ctx.beginPath()
    ctx.setLineDash([4, 4])
    ctx.lineWidth = 1
    ctx.strokeStyle = "rgba(125, 135, 150, 0.55)"
    ctx.moveTo(x, chartArea.top)
    ctx.lineTo(x, chartArea.bottom)
    ctx.stroke()
    ctx.restore()
  }
})
