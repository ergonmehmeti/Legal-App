import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "input" ]

  search(event) {
    const form = event.target.closest("form")
    form.requestSubmit(); // Triggers form submission, handled by Turbo
  }
}
