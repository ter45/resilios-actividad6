import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "items", "emptyMessage", "subtotal", "taxTotal", "total",
    "customerSelect", "paymentCash", "paymentCredit",
    "checkoutButton", "errorBox", "printTicket"
  ]

  static values = {
    cartId: String,
    terminalId: String,
    printBridgeUrl: String,
    resumePayload: Object
  }

  connect() {
    this.items = []
    this.paymentMethod = "cash"
    this.currentScaleWeightKg = 0
    this.csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
    this.updateUI()

    window.addEventListener("pos:add-product", (e) => this.addProduct(e.detail))
    window.addEventListener("pos:scale-weight", (e) => this.setScaleWeight(e.detail))
    window.addEventListener("pos:resume-payload", (e) => this.loadResumedItems(e.detail))

    if (this.hasResumePayloadValue) {
      this.loadResumedItems(this.resumePayloadValue)
    }
  }

  async addProduct(product) {
    this.clearError()

    const quantityToAdd = this.quantityForProduct(product)
    if (quantityToAdd <= 0) return

    const existing = this.items.find(i => i.product_id === product.id)
    const quantity = existing ? this.roundQuantity(existing.quantity + quantityToAdd) : quantityToAdd

    if (product.available_stock < quantity) {
      this.showError(`Sin stock suficiente de ${product.name}`)
      return
    }

    try {
      const response = await fetch("/pos/cart/add", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": this.csrfToken,
          "Accept": "application/json"
        },
        body: JSON.stringify({
          cart_id: this.cartIdValue,
          terminal_id: this.terminalIdValue,
          product_id: product.id,
          quantity: quantityToAdd
        })
      })

      const data = await response.json()

      if (data.success) {
        if (existing) {
          existing.quantity = this.roundQuantity(existing.quantity + quantityToAdd)
          existing.reservation_ids.push(data.reservation_id)
        } else {
          this.items.push({
            product_id:       product.id,
            name:             product.name,
            unit_price:       product.price,
            tax_rate:         product.tax_rate,
            pricing_mode:     product.pricing_mode,
            quantity:         quantityToAdd,
            reservation_ids:  [data.reservation_id]
          })
        }
        this.updateUI()
      } else {
        this.showError(data.errors.join(", "))
      }
    } catch (err) {
      this.showError(`Error de red: ${err.message}`)
    }
  }

  setScaleWeight(detail) {
    this.currentScaleWeightKg = this.roundQuantity(detail?.weightKg || 0)
  }

  quantityForProduct(product) {
    if (product.pricing_mode !== "weight") return 1

    const quantity = this.roundQuantity(product.quantity || this.currentScaleWeightKg)
    if (quantity <= 0) {
      this.showError(`Coloca ${product.name} en la balanza o ingresa el peso manualmente`)
      return 0
    }

    return quantity
  }

  roundQuantity(value) {
    const number = parseFloat(value)
    if (!Number.isFinite(number)) return 0
    return Math.round(number * 1000) / 1000
  }

  formatQuantity(item) {
    if (item.pricing_mode === "weight") return `${Number(item.quantity).toFixed(3)} kg`
    return parseInt(item.quantity).toString()
  }

  formatUnitPrice(item) {
    const suffix = item.pricing_mode === "weight" ? "/kg" : " c/u"
    return `$${parseInt(item.unit_price).toLocaleString("es-CO")}${suffix}`
  }

  async removeItem(event) {
    const productId = parseInt(event.currentTarget.dataset.productId)
    const item = this.items.find(i => i.product_id === productId)
    if (!item) return

    for (const resId of item.reservation_ids) {
      await fetch(`/pos/cart/remove?id=${resId}`, {
        method: "DELETE",
        headers: { "X-CSRF-Token": this.csrfToken, "Accept": "application/json" }
      })
    }

    this.items = this.items.filter(i => i.product_id !== productId)
    this.updateUI()
  }

  async increment(event) {
    const productId = parseInt(event.currentTarget.dataset.productId)
    const item = this.items.find(i => i.product_id === productId)
    if (!item) return
    if (item.pricing_mode === "weight") return

    try {
      const response = await fetch("/pos/cart/add", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": this.csrfToken,
          "Accept": "application/json"
        },
        body: JSON.stringify({
          cart_id: this.cartIdValue,
          terminal_id: this.terminalIdValue,
          product_id: productId,
          quantity: 1
        })
      })
      const data = await response.json()
      if (data.success) {
        item.quantity += 1
        item.reservation_ids.push(data.reservation_id)
        this.updateUI()
      } else {
        this.showError(data.errors.join(", "))
      }
    } catch (err) {
      this.showError(`Error: ${err.message}`)
    }
  }

  async decrement(event) {
    const productId = parseInt(event.currentTarget.dataset.productId)
    const item = this.items.find(i => i.product_id === productId)
    if (!item) return
    if (item.pricing_mode === "weight") return

    if (item.quantity <= 1) {
      await this.removeItemByProductId(productId)
      return
    }

    const resId = item.reservation_ids.pop()
    if (resId) {
      await fetch(`/pos/cart/remove?id=${resId}`, {
        method: "DELETE",
        headers: { "X-CSRF-Token": this.csrfToken }
      })
    }

    item.quantity -= 1
    this.updateUI()
  }

  async removeItemByProductId(productId) {
    const item = this.items.find(i => i.product_id === productId)
    if (!item) return
    for (const resId of item.reservation_ids) {
      await fetch(`/pos/cart/remove?id=${resId}`, {
        method: "DELETE",
        headers: { "X-CSRF-Token": this.csrfToken }
      })
    }
    this.items = this.items.filter(i => i.product_id !== productId)
    this.updateUI()
  }

  async clear() {
    if (this.items.length === 0) return
    if (!confirm("¿Vaciar el carrito?")) return

    await fetch(`/pos/cart/clear?cart_id=${this.cartIdValue}`, {
      method: "DELETE",
      headers: { "X-CSRF-Token": this.csrfToken }
    })

    this.items = []
    this.updateUI()
  }

  customerChanged() {
    const opt = this.customerSelectTarget.selectedOptions[0]
    const limit = parseFloat(opt.dataset.creditLimit || 0)
    if (limit > 0) {
      this.paymentCreditTarget.disabled = false
    } else {
      this.paymentCreditTarget.disabled = true
      if (this.paymentMethod === "credit") this.setPaymentMethodValue("cash")
    }
  }

  setPaymentMethod(event) {
    this.setPaymentMethodValue(event.currentTarget.dataset.method)
  }

  setPaymentMethodValue(method) {
    this.paymentMethod = method
    this.paymentCashTarget.classList.toggle("bg-emerald-600", method === "cash")
    this.paymentCashTarget.classList.toggle("bg-slate-700", method !== "cash")
    this.paymentCreditTarget.classList.toggle("bg-emerald-600", method === "credit")
    this.paymentCreditTarget.classList.toggle("bg-slate-700", method !== "credit")
  }

  async checkout() {
    if (this.items.length === 0) return
    this.clearError()
    this.checkoutButtonTarget.disabled = true

    const customerId = this.customerSelectTarget.value
    if (this.paymentMethod === "credit" && !customerId) {
      this.showError("Para venta a crédito se requiere cliente")
      this.checkoutButtonTarget.disabled = false
      return
    }

    const itemsPayload = {}
    this.items.forEach((item, idx) => {
      itemsPayload[idx] = {
        product_id: item.product_id,
        quantity: item.quantity
      }
    })

    try {
      const response = await fetch("/pos/sales", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": this.csrfToken,
          "Accept": "application/json"
        },
        body: JSON.stringify({
          cart_id: this.cartIdValue,
          terminal_id: this.terminalIdValue,
          payment_method: this.paymentMethod,
          customer_id: customerId,
          items: itemsPayload
        })
      })

      const data = await response.json()

      if (data.success) {
        if (this.shouldPrintTicket()) {
          window.location.assign(`/pos/sales/${data.sale_id}/receipt`)
          return
        }
        let printMessage = "Ticket no impreso."

        alert(`Venta ${data.sale_number} confirmada por $${data.total.toLocaleString("es-CO")}\n${printMessage}`)
        window.location.reload()
      } else {
        this.showError(data.errors.join(", "))
        this.checkoutButtonTarget.disabled = false
      }
    } catch (err) {
      this.showError(`Error: ${err.message}`)
      this.checkoutButtonTarget.disabled = false
    }
  }

  async suspend() {
    if (this.items.length === 0) {
      this.showError("Carrito vacío")
      return
    }
    this.clearError()

    const notes = prompt("Notas (opcional). Ej: 'Cliente fue al ATM'", "")
    if (notes === null) return

    this.checkoutButtonTarget.disabled = true

    const customerId = this.customerSelectTarget.value
    const itemsPayload = {}
    this.items.forEach((item, idx) => {
      itemsPayload[idx] = {
        product_id: item.product_id,
        quantity: item.quantity
      }
    })

    try {
      const response = await fetch("/pos/sales/suspend", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": this.csrfToken,
          "Accept": "application/json"
        },
        body: JSON.stringify({
          cart_id: this.cartIdValue,
          terminal_id: this.terminalIdValue,
          payment_method: this.paymentMethod,
          customer_id: customerId,
          items: itemsPayload,
          notes: notes
        })
      })

      const data = await response.json()

      if (data.success) {
        alert(`${data.display} guardada con ${data.items_count} items por $${data.total.toLocaleString("es-CO")}`)
        window.location.href = "/pos"
      } else {
        this.showError(data.errors.join(", "))
        this.checkoutButtonTarget.disabled = false
      }
    } catch (err) {
      this.showError(`Error: ${err.message}`)
      this.checkoutButtonTarget.disabled = false
    }
  }

  shouldPrintTicket() {
    return this.hasPrintTicketTarget && this.printTicketTarget.checked
  }

  loadResumedItems(payload) {
    if (!payload || !payload.items || payload.items.length === 0) return

    if (payload.cart_id) {
      this.cartIdValue = payload.cart_id
    }

    payload.items.forEach(item => {
      this.items.push({
        product_id:      item.product_id,
        name:            item.product_name,
        unit_price:      parseFloat(item.unit_price),
        tax_rate:        item.tax_rate || 0.19,
        pricing_mode:    item.pricing_mode || "unit",
        quantity:        parseFloat(item.quantity),
        reservation_ids: []
      })
    })

    if (payload.customer_id && this.hasCustomerSelectTarget) {
      this.customerSelectTarget.value = payload.customer_id
      this.customerChanged()
    }

    this.updateUI()

    if (payload.warnings && payload.warnings.length > 0) {
      alert("Aviso al reanudar:\n" + payload.warnings.join("\n"))
    }
  }

  async printSaleTicket(saleId) {
    try {
      const ticketResponse = await fetch(`/pos/sales/${saleId}/ticket`, {
        method: "GET",
        headers: {
          "Accept": "application/json",
          "X-CSRF-Token": this.csrfToken
        }
      })

      if (!ticketResponse.ok) {
        return { ok: false, message: "Rails no genero el ticket" }
      }

      const ticket = await ticketResponse.json()
      const bridgeResponse = await fetch(`${this.printBridgeUrlValue}/print`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json"
        },
        body: JSON.stringify({
          payload: ticket.payload,
          encoding: ticket.encoding,
          openDrawer: ticket.open_drawer || false
        })
      })

      const bridgeData = await bridgeResponse.json().catch(() => ({}))
      if (!bridgeResponse.ok || bridgeData.ok === false) {
        return { ok: false, message: bridgeData.message || "Print Bridge rechazo la impresion" }
      }

      return { ok: true, message: bridgeData.message || "OK" }
    } catch (err) {
      return { ok: false, message: err.message }
    }
  }

  updateUI() {
    if (this.items.length === 0) {
      this.emptyMessageTarget.classList.remove("hidden")
      this.itemsTarget.querySelectorAll(".cart-item").forEach(n => n.remove())
      this.checkoutButtonTarget.disabled = true
    } else {
      this.emptyMessageTarget.classList.add("hidden")
      this.renderItems()
      this.checkoutButtonTarget.disabled = false
    }
    this.updateTotals()
  }

  renderItems() {
    this.itemsTarget.querySelectorAll(".cart-item").forEach(n => n.remove())

    this.items.forEach(item => {
      const lineTotal = (item.quantity * item.unit_price * (1 + item.tax_rate)).toFixed(0)
      const quantityControls = item.pricing_mode === "weight"
        ? `<span class="text-xs text-slate-400">Peso</span>
           <span class="min-w-20 text-center font-medium">${this.formatQuantity(item)}</span>`
        : `<button data-action="click->cart#decrement"
                    data-product-id="${item.product_id}"
                    class="w-7 h-7 bg-slate-600 hover:bg-slate-500 rounded text-sm font-bold">−</button>
            <span class="w-10 text-center font-medium">${this.formatQuantity(item)}</span>
            <button data-action="click->cart#increment"
                    data-product-id="${item.product_id}"
                    class="w-7 h-7 bg-slate-600 hover:bg-slate-500 rounded text-sm font-bold">+</button>`
      const div = document.createElement("div")
      div.className = "cart-item bg-slate-700 rounded p-3"
      div.innerHTML = `
        <div class="flex justify-between items-start mb-2">
          <div class="flex-1 pr-2">
            <div class="font-medium text-sm">${item.name}</div>
            <div class="text-xs text-slate-400">${this.formatUnitPrice(item)}</div>
          </div>
          <button data-action="click->cart#removeItem"
                  data-product-id="${item.product_id}"
                  class="text-red-400 hover:text-red-300 text-xl leading-none">×</button>
        </div>
        <div class="flex items-center justify-between">
          <div class="flex items-center gap-2">
            ${quantityControls}
          </div>
          <div class="text-sm font-bold">$${parseInt(lineTotal).toLocaleString("es-CO")}</div>
        </div>
      `
      this.itemsTarget.appendChild(div)
    })
  }

  updateTotals() {
    let subtotal = 0
    let tax = 0
    this.items.forEach(item => {
      const base = item.quantity * item.unit_price
      subtotal += base
      tax += base * item.tax_rate
    })
    const total = subtotal + tax

    this.subtotalTarget.textContent = `$ ${parseInt(subtotal).toLocaleString("es-CO")}`
    this.taxTotalTarget.textContent = `$ ${parseInt(tax).toLocaleString("es-CO")}`
    this.totalTarget.textContent = `$ ${parseInt(total).toLocaleString("es-CO")}`
  }

  showError(msg) {
    this.errorBoxTarget.textContent = msg
    this.errorBoxTarget.classList.remove("hidden")
  }

  clearError() {
    this.errorBoxTarget.classList.add("hidden")
    this.errorBoxTarget.textContent = ""
  }
}
