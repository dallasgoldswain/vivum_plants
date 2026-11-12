import { Controller } from "@hotwired/stimulus"

// Scales a recipe to a target volume as you type (SU03, D98). Same rule as Recipe::Scale:
// each part rounds to the nearest 50 mL, or 25 mL when the total is under 1 L.
export default class extends Controller {
  static targets = ["amount", "unit", "volume", "total"]

  update() {
    const amount = parseFloat(this.amountTarget.value.replace(",", "."))
    const millilitres = this.unitTarget.value === "L" ? amount * 1000 : amount
    if (!(millilitres > 0)) {
      this.volumeTargets.forEach((cell) => cell.textContent = "–")
      this.totalTarget.textContent = "–"
      return
    }

    const step = millilitres < 1000 ? 25 : 50
    let total = 0
    this.volumeTargets.forEach((cell) => {
      const volume = Math.round((millilitres * parseFloat(cell.dataset.fraction)) / step) * step
      total += volume
      cell.textContent = this.#label(volume)
    })
    this.totalTarget.textContent = this.#label(total)
  }

  #label(millilitres) {
    if (millilitres >= 1000) return `${parseFloat((millilitres / 1000).toFixed(2))} L`
    return `${millilitres} mL`
  }
}
