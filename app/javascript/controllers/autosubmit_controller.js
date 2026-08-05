import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["submit"]

  connect() {
    if (this.hasSubmitTarget) this.submitTarget.classList.add("d-none")
  }

  submit() {
    this.element.requestSubmit()
  }
}
