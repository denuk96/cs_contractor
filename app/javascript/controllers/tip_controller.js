import { Controller } from "@hotwired/stimulus"

// One shared tooltip layer for every ⓘ in the app. Any element carrying
// data-tip="Title|Body" drives it on hover. The box is pointer-events:none and
// clamped to the viewport so it can never sit under the cursor or off-screen.
export default class extends Controller {
  static targets = ["box", "title", "body"]

  static MARGIN = 8

  show(event) {
    const trigger = event.target.closest?.("[data-tip]")
    if (!trigger || trigger === this.trigger) return

    const [title, body] = (trigger.dataset.tip || "").split("|")
    this.trigger = trigger
    this.titleTarget.textContent = title || ""
    this.bodyTarget.textContent = body || ""
    this.titleTarget.hidden = !title
    this.boxTarget.hidden = false
    this.#place(trigger)
  }

  // The box is fixed, so a scroll would otherwise leave it stranded mid-page.
  dismiss() {
    this.trigger = null
    this.boxTarget.hidden = true
  }

  hide(event) {
    if (!this.trigger) return
    if (event?.relatedTarget && this.trigger.contains(event.relatedTarget)) return

    this.trigger = null
    this.boxTarget.hidden = true
  }

  #place(trigger) {
    const anchor = trigger.getBoundingClientRect()
    const box = this.boxTarget.getBoundingClientRect()
    const margin = this.constructor.MARGIN

    const maxLeft = window.innerWidth - box.width - margin
    const left = Math.max(margin, Math.min(anchor.left, maxLeft))

    // Flip above the trigger when there is not enough room below it.
    const below = anchor.bottom + margin
    const top = below + box.height > window.innerHeight
      ? Math.max(margin, anchor.top - box.height - margin)
      : below

    this.boxTarget.style.left = `${left}px`
    this.boxTarget.style.top = `${top}px`
  }
}
