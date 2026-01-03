import { Controller } from "@hotwired/stimulus"
import { Popover } from "bootstrap"

// Connects to data-controller="popover"
export default class extends Controller {
  connect() {
    const popoverTriggerList = [].slice.call(this.element.querySelectorAll('[data-bs-toggle="popover"]'))
    popoverTriggerList.map(function (popoverTriggerEl) {
      return new Popover(popoverTriggerEl)
    })
  }
}
