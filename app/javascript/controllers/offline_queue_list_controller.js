import { Controller } from "@hotwired/stimulus"
import { queue, QUEUE_CHANGED } from "lib/offline_queue"

// Shows this plant's observations still waiting to send, so queued state is visible (OF02).
export default class extends Controller {
  static targets = ["list"]
  static values = { plantId: Number }

  connect() {
    this.render = this.render.bind(this)
    window.addEventListener(QUEUE_CHANGED, this.render)
    this.render()
  }

  disconnect() {
    window.removeEventListener(QUEUE_CHANGED, this.render)
  }

  async render() {
    if (!window.indexedDB) return
    const userId = document.body.dataset.offlineSyncUserIdValue
    const items = (await queue.all()).filter((item) => item.plantId === this.plantIdValue && item.userId === userId)
    this.element.hidden = items.length === 0
    this.listTarget.replaceChildren(...items.map((item) => this.row(item)))
  }

  row(item) {
    const li = document.createElement("li")
    li.className = "rounded-[4px] border border-line bg-linen px-3 py-2 text-sm"
    const photos = item.files?.length ? ` · ${item.files.length} photo${item.files.length > 1 ? "s" : ""}` : ""
    li.textContent = `${item.note || "Photo"}${photos}`
    const state = document.createElement("span")
    state.className = "vv-caption block"
    state.textContent = item.errors ? `Not saved: ${item.errors.join(" ")}` : "Queued"
    li.append(state)
    if (item.errors) {
      const discard = document.createElement("button")
      discard.type = "button"
      discard.className = "btn-sm-ghost"
      discard.textContent = "Discard"
      discard.addEventListener("click", () => queue.remove(item.key))
      li.append(discard)
    }
    return li
  }
}
