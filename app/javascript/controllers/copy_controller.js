import { Controller } from "@hotwired/stimulus"

// Copies a value, such as an order link in Closeout (SC02), and says so.
export default class extends Controller {
  static targets = ["status"]
  static values = { text: String }

  async copy() {
    try {
      await navigator.clipboard.writeText(this.textValue)
      this.say("Link copied.")
    } catch {
      this.say("Couldn't copy here.")
    }
  }

  say(message) {
    if (this.hasStatusTarget) this.statusTarget.textContent = message
  }
}
