import { Controller } from "@hotwired/stimulus"

// Opens the browser's print dialog, where the page can also be saved as a PDF.
export default class extends Controller {
  print() {
    window.print()
  }
}
