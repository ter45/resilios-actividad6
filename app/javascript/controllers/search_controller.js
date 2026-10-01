import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "results", "previous", "next", "pageLabel", "status"]

  connect() {
    this.requestId = 0
    this.currentCategoryId = null
    this.currentPage = 1
    this.fetchResults("", null)
  }

  disconnect() { this.invalidate() }

  invalidate() {
    clearTimeout(this.debounceTimer)
    this.abortController?.abort()
    this.requestId = (this.requestId || 0) + 1
    return this.requestId
  }

  perform() {
    this.invalidate()
    this.resultsTarget.replaceChildren()
    this.setBusy(true)
    const query = this.inputTarget.value.trim()
    this.debounceTimer = setTimeout(() => this.fetchResults(query, this.currentCategoryId), 200)
  }

  async scan(event) {
    event.preventDefault()
    const value = this.inputTarget.value.trim()
    if (!value) return
    const requestId = this.invalidate()
    if (/^\d{8,14}$/.test(value)) {
      this.abortController = new AbortController()
      this.resultsTarget.replaceChildren()
      this.setBusy(true)
      try {
        const response = await fetch(`/pos/products/lookup_barcode?barcode=${encodeURIComponent(value)}`, {
          headers: { "Accept": "application/json" }, signal: this.abortController.signal
        })
        if (requestId !== this.requestId) return
        if (response.ok) {
          const product = await response.json()
          if (requestId !== this.requestId) return
          if (product.available_stock <= 0) {
            this.statusTarget.textContent = "Producto sin disponibilidad"
            this.setBusy(false)
            return
          }
          window.dispatchEvent(new CustomEvent("pos:add-product", { detail: product }))
          this.inputTarget.value = ""
          await this.fetchResults("", this.currentCategoryId)
          return
        }
        if (response.status !== 404) throw new Error("No se pudo consultar el código")
      } catch (error) {
        if (requestId !== this.requestId || error.name === "AbortError") return
        this.statusTarget.textContent = error.message
        this.setBusy(false)
        return
      }
    }
    await this.fetchResults(value, this.currentCategoryId)
  }

  filterCategory(event) {
    const id = event.currentTarget.dataset.categoryId || ""
    this.currentCategoryId = id || null
    this.element.querySelectorAll("[data-category-id]").forEach(button => {
      const selected = button.dataset.categoryId === id
      button.classList.toggle("bg-emerald-600", selected)
      button.classList.toggle("bg-slate-700", !selected)
      button.setAttribute("aria-pressed", String(selected))
    })
    this.fetchResults(this.inputTarget.value.trim(), this.currentCategoryId)
  }

  previousPage() {
    if (this.currentPage > 1) this.fetchResults(this.inputTarget.value.trim(), this.currentCategoryId, this.currentPage - 1)
  }

  nextPage() {
    if (this.hasMore) this.fetchResults(this.inputTarget.value.trim(), this.currentCategoryId, this.currentPage + 1)
  }

  setBusy(busy) {
    this.resultsTarget.setAttribute("aria-busy", String(busy))
    this.previousTarget.disabled = busy || this.currentPage <= 1
    this.nextTarget.disabled = busy || !this.hasMore
  }

  async fetchResults(query, categoryId, page = 1) {
    const requestId = this.invalidate()
    this.abortController = new AbortController()
    const params = new URLSearchParams({ page })
    if (query) params.append("q", query)
    if (categoryId) params.append("category_id", categoryId)
    this.resultsTarget.replaceChildren()
    this.statusTarget.textContent = "Buscando…"
    this.setBusy(true)
    try {
      const response = await fetch(`/pos/products/search?${params}`, {
        headers: { "Accept": "application/json" }, signal: this.abortController.signal
      })
      if (requestId !== this.requestId) return
      if (!response.ok) throw new Error("No se pudo cargar el catálogo. Intenta de nuevo.")
      const body = await response.json()
      if (requestId !== this.requestId) return
      this.currentPage = body.page
      this.hasMore = body.has_more
      this.renderResults(body.products)
      this.pageLabelTarget.textContent = `Página ${body.page}`
      this.statusTarget.textContent = body.products.length ? `${body.products.length} productos en esta página` : "Sin resultados"
    } catch (error) {
      if (requestId !== this.requestId || error.name === "AbortError") return
      this.statusTarget.textContent = error.message
      this.hasMore = false
    } finally {
      if (requestId === this.requestId) this.setBusy(false)
    }
  }

  renderResults(products) {
    this.resultsTarget.replaceChildren()
    products.forEach(product => {
      const button = document.createElement("button")
      button.type = "button"
      button.dataset.action = "click->search#selectProduct"
      button.dataset.product = JSON.stringify(product)
      button.disabled = product.available_stock <= 0
      button.className = "text-left bg-slate-700 hover:bg-slate-600 rounded-lg p-3 transition disabled:opacity-40 disabled:cursor-not-allowed"
      const lines = [
        [product.name, "text-sm font-medium leading-tight mb-1 truncate"],
        [product.category_name, "text-xs text-slate-400"],
        [`${product.display_price}${product.pricing_mode === "weight" ? "/kg" : ""}`, "font-bold text-emerald-400"],
        [button.disabled ? "Sin stock" : `${product.available_stock}${product.pricing_mode === "weight" ? " kg" : ""} disp.`, "text-xs text-slate-400"]
      ]
      lines.forEach(([text, className]) => {
        const line = document.createElement("div")
        line.className = className
        line.textContent = text
        button.append(line)
      })
      this.resultsTarget.append(button)
    })
  }

  selectProduct(event) {
    const product = JSON.parse(event.currentTarget.dataset.product)
    if (product.available_stock <= 0) return
    window.dispatchEvent(new CustomEvent("pos:add-product", { detail: product }))
  }
}
