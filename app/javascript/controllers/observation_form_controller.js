import { Controller } from "@hotwired/stimulus"
import { queue, send } from "lib/offline_queue"

// Saves an observation online, or queues it when there's no connection (OF02, D84).
export default class extends Controller {
  static targets = ["key", "status", "submit"]
  static values = { plantId: Number }

  async submit(event) {
    event.preventDefault()
    const form = this.element
    const item = {
      key: this.keyTarget.value,
      userId: document.body.dataset.offlineSyncUserIdValue,
      plantId: this.plantIdValue,
      url: form.action,
      note: form.elements["care_event[note]"].value,
      occurredAt: form.elements["care_event[occurred_at]"].value,
      files: Array.from(form.elements["care_event[photos][]"]?.files || []),
      queuedAt: new Date().toISOString()
    }
    if (!item.note.trim() && item.files.length === 0) return this.say("Add a note or a photo.")

    this.submitTarget.disabled = true
    const outcome = navigator.onLine ? await send(item) : { result: "offline" }
    this.submitTarget.disabled = false

    if (outcome.result === "sent") {
      window.Turbo.visit(window.location.pathname, { action: "replace" })
    } else if (outcome.result === "rejected") {
      this.say(outcome.errors.join(" "))
    } else {
      await queue.add(item)
      form.reset()
      this.keyTarget.value = crypto.randomUUID()
      this.say("Saved on this device. It'll be sent when you're back online.")
    }
  }

  say(message) {
    this.statusTarget.textContent = message
  }
}
