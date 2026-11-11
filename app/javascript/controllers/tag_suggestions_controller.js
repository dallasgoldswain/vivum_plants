import { Controller } from "@hotwired/stimulus"

// Adds one of the collector's earlier tags to the comma-separated tags field (D85).
export default class extends Controller {
  static targets = ["input"]

  add({ params: { tag } }) {
    const tags = this.inputTarget.value.split(",").map((t) => t.trim()).filter(Boolean)
    if (!tags.includes(tag)) tags.push(tag)
    this.inputTarget.value = tags.join(", ")
    this.inputTarget.focus()
  }
}
