import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["amountInput", "notesInput", "balanceText", "errorBox", "submitButton"]
  static values = { creditId: Number, balance: Number }

  connect() {
    this.csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
  }

  setAmount(event) {
    const amount = Math.min(parseInt(event.currentTarget.dataset.amount), this.balanceValue)
    this.amountInputTarget.value = amount
    this.amountInputTarget.focus()
  }

  payFull() {
    this.amountInputTarget.value = this.balanceValue
    this.amountInputTarget.focus()
  }

  async submit() {
    this.clearError()
    const amount = parseFloat(this.amountInputTarget.value || 0)

    if (amount <= 0) {
      this.showError("Ingresá un monto mayor a 0")
      return
    }

    if (amount > this.balanceValue) {
      this.showError(`Monto excede el saldo pendiente ($${this.balanceValue.toLocaleString("es-CO")})`)
      return
    }

    if (!confirm(`¿Confirmar abono de $${amount.toLocaleString("es-CO")}?`)) return

    this.submitButtonTarget.disabled = true
    this.submitButtonTarget.textContent = "Procesando..."

    try {
      const response = await fetch(`/pos/credits/${this.creditIdValue}/pay`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": this.csrfToken,
          "Accept": "application/json"
        },
        body: JSON.stringify({
          amount: amount,
          notes: this.notesInputTarget.value
        })
      })

      const data = await response.json()

      if (data.success) {
        let msg = `Abono de $${amount.toLocaleString("es-CO")} registrado.`
        if (data.fully_paid) {
          msg += "\nCRÉDITO LIQUIDADO."
        } else {
          msg += `\nNuevo saldo: $${data.new_balance.toLocaleString("es-CO")}`
        }
        alert(msg)
        window.location.href = "/pos/credits"
      } else {
        this.showError(data.errors.join(", "))
        this.submitButtonTarget.disabled = false
        this.submitButtonTarget.textContent = "Confirmar abono"
      }
    } catch (err) {
      this.showError(`Error: ${err.message}`)
      this.submitButtonTarget.disabled = false
      this.submitButtonTarget.textContent = "Confirmar abono"
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
