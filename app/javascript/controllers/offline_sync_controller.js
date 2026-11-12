import { Controller } from "@hotwired/stimulus"
import { queue, send, QUEUE_CHANGED } from "lib/offline_queue"

// Sends queued entries for the signed-in user whenever the app is online (OF02, D84).
export default class extends Controller {
  static values = { userId: String }

  connect() {
    this.sync = this.sync.bind(this)
    window.addEventListener("online", this.sync)
    window.addEventListener(QUEUE_CHANGED, this.sync)
    this.sync()
  }

  disconnect() {
    window.removeEventListener("online", this.sync)
    window.removeEventListener(QUEUE_CHANGED, this.sync)
  }

  async sync() {
    if (this.syncing || !navigator.onLine || !window.indexedDB) return
    this.syncing = true
    let sent = false
    try {
      const items = (await queue.all()).filter((item) => item.userId === this.userIdValue && !item.errors)
      for (const item of items) {
        const outcome = await send(item)
        if (outcome.result === "offline") break
        if (outcome.result === "sent") { await queue.remove(item.key); sent = true }
        if (outcome.result === "rejected") await queue.update({ ...item, errors: outcome.errors })
      }
    } finally {
      this.syncing = false
    }
    if (sent && /^\/($|plants|environments)/.test(window.location.pathname)) window.Turbo.visit(window.location.pathname, { action: "replace" })
  }
}
