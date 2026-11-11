import { Controller } from "@hotwired/stimulus"

// On the sign-in page: drop cached collection pages so the next person on this device
// can't read them offline. Queued observations stay, tied to their own account.
export default class extends Controller {
  connect() {
    if (window.caches) caches.keys().then((keys) => keys.filter((key) => key.startsWith("vivum-pages")).forEach((key) => caches.delete(key)))
  }
}
