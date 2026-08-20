// Chartkick serialises `library:` options to JSON, so a tick callback written
// as a JS source string arrives at Chart.js as a String. Chart.js then calls it
// and the scale silently generates no ticks at all — which is why the axes had
// no tick labels. This plugin compiles those strings back into functions before
// the first draw, so TICK_CALLBACKS-style formatting works on every axis,
// including the dual-axis charts where a single global format would not do.
import "Chart.bundle"

const compiled = new WeakMap()

function toFunction(source) {
  let fn = compiled.get(source)
  if (fn) return fn

  try {
    // eslint-disable-next-line no-new-func
    fn = new Function(`return (${source});`)()
  } catch (e) {
    console.warn("[chartkick] could not compile tick callback", source, e)
    return null
  }

  if (typeof fn !== "function") return null
  return fn
}

function compileScales(options) {
  if (!options?.scales) return

  Object.values(options.scales).forEach((scale) => {
    const callback = scale?.ticks?.callback
    if (typeof callback !== "string") return

    const fn = toFunction(callback)
    if (fn) scale.ticks.callback = fn
  })
}

Chart.register({
  id: "stringTickCallbacks",
  beforeInit(chart) {
    compileScales(chart.config.options)
    compileScales(chart.options)
  }
})
