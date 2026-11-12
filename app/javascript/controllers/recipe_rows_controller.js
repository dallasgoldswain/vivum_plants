import { Controller } from "@hotwired/stimulus"

// Ingredient rows on the recipe form: add and remove rows, and show the running total so a
// % recipe can be brought to 100% before it's marked ready (SU02, D98).
export default class extends Controller {
  static targets = ["rows", "template", "quantity", "basis", "total"]

  connect() {
    this.update()
  }

  add(event) {
    event.preventDefault()
    const index = Date.now()
    this.rowsTarget.insertAdjacentHTML("beforeend", this.templateTarget.innerHTML.replaceAll("NEW_ROW", index))
    this.rowsTarget.lastElementChild.querySelector("select")?.focus()
    this.update()
  }

  remove(event) {
    event.preventDefault()
    event.target.closest("[data-recipe-rows-row]").remove()
    this.update()
  }

  update() {
    const total = this.quantityTargets.reduce((sum, input) => sum + (parseFloat(input.value.replace(",", ".")) || 0), 0)
    const percent = this.basisTargets.find((input) => input.checked)?.value === "percent"
    const rounded = parseFloat(total.toFixed(2))
    this.totalTarget.textContent = percent ? `Total: ${rounded}%${rounded === 100 ? "" : " (needs to be 100% to mark ready)"}` : `Total: ${rounded} ${rounded === 1 ? "part" : "parts"}`
  }
}
