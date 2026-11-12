import { Controller } from "@hotwired/stimulus"
import { queue, send } from "lib/offline_queue"

// Saves a form online, or queues it on this device when there's no connection (OF02, D84,
// D94, D110). Used for observations, care entries and environment readings. The form
// carries an idempotency key (the `key` target) so a resend never saves twice. `content`
// targets are what the entry says; with an `emptyMessage`, at least one must be filled in
// or a file chosen. `label` heads the queued summary ("Watered"); `afterSave` is where to
// go once it's sent (this page by default).
export default class extends Controller {
  static targets = ["key", "status", "submit", "content"]
  static values = { subject: String, emptyMessage: String, label: String, afterSave: String }

  async submit(event) {
    event.preventDefault()
    const form = this.element
    const fields = [], files = []
    for (const [name, value] of new FormData(form)) {
      if (value instanceof File) { if (value.size > 0) files.push([name, value]) } else fields.push([name, value])
    }
    const filled = this.contentTargets.filter((input) => input.value.trim())
    if (this.emptyMessageValue && filled.length === 0 && files.length === 0) return this.say(this.emptyMessageValue)

    const item = {
      key: this.keyTarget.value,
      userId: document.body.dataset.offlineSyncUserIdValue,
      subject: this.subjectValue,
      url: form.action,
      summary: [this.labelValue, ...filled.map((input) => [input.dataset.summaryLabel, input.value.trim()].filter(Boolean).join(" "))].filter(Boolean).join(" · "),
      fields,
      files,
      queuedAt: new Date().toISOString()
    }

    this.submitTarget.disabled = true
    const outcome = navigator.onLine ? await send(item) : { result: "offline" }
    this.submitTarget.disabled = false

    if (outcome.result === "sent") {
      window.Turbo.visit(this.afterSaveValue || window.location.pathname + window.location.hash, { action: this.afterSaveValue ? "advance" : "replace" })
    } else if (outcome.result === "rejected") {
      this.say(outcome.errors.join(" "))
    } else {
      await queue.add(item)
      form.reset()
      this.keyTarget.value = crypto.randomUUID()
      form.closest("dialog")?.close()
      this.say("Saved on this device. It'll be sent when you're back online.")
    }
  }

  say(message) {
    this.statusTarget.textContent = message
  }
}
