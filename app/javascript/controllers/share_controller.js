import { Controller } from "@hotwired/stimulus"

// Shares a sale card (SE08, D169): the device share sheet with the image and caption where
// the browser or app supports sharing files; otherwise the Share button stays hidden and the
// seller uses Download and Copy caption. Sharing never changes stock.
export default class extends Controller {
  static targets = ["share", "status"]
  static values = { url: String, filename: String, type: String, caption: String }

  connect() {
    if (this.hasShareTarget && navigator.canShare) {
      const probe = new File([""], this.filenameValue, { type: this.typeValue })
      if (navigator.canShare({ files: [probe] })) this.shareTarget.hidden = false
    }
  }

  async share() {
    try {
      const response = await fetch(this.urlValue, { credentials: "same-origin" })
      const file = new File([await response.blob()], this.filenameValue, { type: this.typeValue })
      await navigator.share({ files: [file], text: this.captionValue })
    } catch (error) {
      if (error.name !== "AbortError") this.say("Sharing didn't work here. Download the card instead.")
    }
  }

  async copy() {
    try {
      await navigator.clipboard.writeText(this.captionValue)
      this.say("Caption copied.")
    } catch {
      this.say("Couldn't copy. Select the caption and copy it.")
    }
  }

  say(message) {
    if (this.hasStatusTarget) this.statusTarget.textContent = message
  }
}
