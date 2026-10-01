import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["countedInput", "differenceBox", "differenceText", "differenceStatus", "notes", "errorBox", "submitButton"]
  static values = { terminalId: String, expected: Number }

  connect() {
    this.csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
  }

  updateDifference() {
    const counted = parseFloat(this.countedInputTarget.value || 0)
    const diff = counted - this.expectedValue

    this.differenceBoxTarget.classList.remove("hidden")

    let prefix = ""
    let color = "text-emerald-400"
    let status = "Caja cuadrada"
    let statusColor = "text-emerald-300"

    if (diff < 0) {
      prefix = "-"
      color = "text-red-400"
      status = `Faltante de $${Math.abs(diff).toLocaleString("es-CO")}`
      statusColor = "text-red-300"
    } else if (diff > 0) {
      prefix = "+"
      color = "text-yellow-400"
      status = `Sobrante de $${diff.toLocaleString("es-CO")}`
      statusColor = "text-yellow-300"
    }

    this.differenceTextTarget.textContent = `${prefix}$ ${Math.abs(diff).toLocaleString("es-CO")}`
    this.differenceTextTarget.className = `text-2xl font-bold ${color}`
    this.differenceStatusTarget.textContent = status
    this.differenceStatusTarget.className = `text-xs mt-1 ${statusColor}`
  }

  async submit() {
    this.clearError()
    const counted = parseFloat(this.countedInputTarget.value || 0)

    if (counted < 0) {
      this.showError("El monto contado no puede ser negativo")
      return
    }

    if (!confirm(`¿Confirmar cierre con efectivo contado de $${counted.toLocaleString("es-CO")}?`)) return

    this.submitButtonTarget.disabled = true
    this.submitButtonTarget.textContent = "Procesando..."

    try {
      const response = await fetch("/pos/closings", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": this.csrfToken,
          "Accept": "application/json"
        },
        body: JSON.stringify({
          terminal_id: this.terminalIdValue,
          counted_cash: counted,
          notes: this.notesTarget.value
        })
      })

      const data = await response.json()

      if (data.success) {
        let msg = `Cierre confirmado.\nEsperado: $${data.expected_cash.toLocaleString("es-CO")}\nContado: $${data.counted_cash.toLocaleString("es-CO")}\n`
        if (data.status === "balanced") msg += "Diferencia: $0 (CUADRADO)"
        else if (data.status === "shortage") msg += `Faltante: $${Math.abs(data.difference).toLocaleString("es-CO")}`
        else msg += `Sobrante: $${data.difference.toLocaleString("es-CO")}`
        alert(msg)
        window.location.href = "/pos/sales/new"
      } else {
        this.showError(data.errors.join(", "))
        this.submitButtonTarget.disabled = false
        this.submitButtonTarget.textContent = "Confirmar cierre"
      }
    } catch (err) {
      this.showError(`Error: ${err.message}`)
      this.submitButtonTarget.disabled = false
      this.submitButtonTarget.textContent = "Confirmar cierre"
    }
  }

  showError(msg) {
    this.errorBoxTarget.textContent = msg
    this.errorBoxTarget.classList.remove("hidden")
  }

  clearError() {
    this.errorBoxTarget.classList.add("hidden")
  }
}
