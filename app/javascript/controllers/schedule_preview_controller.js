import { Controller } from "@hotwired/stimulus"

// The next dates of a reminder, worked out the same way as CareSchedule#preview (CA02,
// D117): after-completion counts from each date, fixed keeps to the calendar from the first
// date, and months clamp to the last valid day.
export default class extends Controller {
  static targets = ["once", "fixed", "interval", "unit", "start", "dates"]

  connect() { this.update() }

  update() {
    const start = this.parse(this.startTarget.value)
    if (!start) return (this.datesTarget.textContent = "Choose a first date.")
    const interval = parseInt(this.intervalTarget.value, 10)
    if (this.onceTarget.checked || !(interval > 0)) return this.show([start])

    const unit = this.unitTarget.value
    const dates = [start]
    for (let step = 1; dates.length < 5; step++) {
      dates.push(this.fixedTarget.checked ? this.advance(start, unit, interval * step) : this.advance(dates[dates.length - 1], unit, interval))
    }
    this.show(dates)
  }

  advance(date, unit, amount) {
    if (unit === "month") {
      const target = new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth() + amount, 1))
      const lastDay = new Date(Date.UTC(target.getUTCFullYear(), target.getUTCMonth() + 1, 0)).getUTCDate()
      target.setUTCDate(Math.min(date.getUTCDate(), lastDay))
      return target
    }
    const days = unit === "week" ? amount * 7 : amount
    return new Date(date.getTime() + days * 86400000)
  }

  parse(value) {
    const match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(value)
    return match ? new Date(Date.UTC(+match[1], +match[2] - 1, +match[3])) : null
  }

  show(dates) {
    const part = (options) => new Intl.DateTimeFormat("en-GB", { ...options, timeZone: "UTC" })
    const weekday = part({ weekday: "short" }), month = part({ month: "short" })
    // "Sun 31 Jan", as the server writes it
    this.datesTarget.textContent = dates.map((date) => `${weekday.format(date)} ${date.getUTCDate()} ${month.format(date)}`).join(" · ")
  }
}
