import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["status", "weight", "manualWeight", "connectButton"]
  static values = {
    bridgeUrl: { type: String, default: "http://127.0.0.1:8088" }
  }

  connect() {
    this.port = null
    this.reader = null
    this.keepReading = false
    this.bridgePolling = null
    this.currentWeightKg = 0
    this.updateStatus("Desconectada")
    this.updateWeight(0)
    this.startBridgePolling()
  }

  disconnect() {
    this.stopBridgePolling()
    this.disconnectScale()
  }

  async connectScale() {
    if (await this.connectBridgeScale()) return

    if (!window.isSecureContext) {
      this.updateStatus("Web Serial requiere localhost o HTTPS.")
      return
    }

    if (!("serial" in navigator)) {
      this.updateStatus("Web Serial no disponible. Usa Chrome o Edge.")
      return
    }

    try {
      await this.disconnectScale()
      this.port = await navigator.serial.requestPort()
      await this.port.open({ baudRate: 9600, dataBits: 8, stopBits: 1, parity: "none" })
      this.keepReading = true
      this.updateStatus("Conectada")
      this.connectButtonTarget.textContent = "Reconectar"
      this.readLoop()
    } catch (err) {
      this.updateStatus(`Error: ${err.message}`)
    }
  }

  async connectBridgeScale() {
    try {
      const response = await fetch(`${this.bridgeUrlValue}/scale/connect`, {
        method: "POST",
        headers: { "Content-Type": "application/json", "Accept": "application/json" },
        body: JSON.stringify({})
      })

      if (!response.ok) return false
      const data = await response.json()
      this.applyBridgeScale(data.scale || data)
      this.updateStatus("Bridge conectado")
      return true
    } catch (_) {
      return false
    }
  }

  startBridgePolling() {
    this.stopBridgePolling()
    this.pollBridgeScale()
    this.bridgePolling = setInterval(() => this.pollBridgeScale(), 500)
  }

  stopBridgePolling() {
    if (!this.bridgePolling) return
    clearInterval(this.bridgePolling)
    this.bridgePolling = null
  }

  async pollBridgeScale() {
    try {
      const response = await fetch(`${this.bridgeUrlValue}/scale`, {
        headers: { "Accept": "application/json" }
      })
      if (!response.ok) return

      const data = await response.json()
      this.applyBridgeScale(data)
    } catch (_) {
      // El bridge es opcional; Web Serial o peso manual siguen disponibles.
    }
  }

  applyBridgeScale(data) {
    if (!data) return
    if (data.weightKg !== undefined && data.weightKg !== null) this.updateWeight(data.weightKg)
    if (data.connected) this.updateStatus("Bridge conectado")
    if (data.error) this.updateStatus(`Bridge: ${data.error}`)
  }

  async disconnectScale() {
    this.keepReading = false
    try {
      if (this.reader) {
        await this.reader.cancel()
        this.reader.releaseLock()
      }
      if (this.port) await this.port.close()
    } catch (_) {
      // La desconexion puede fallar si el puerto ya fue retirado.
    } finally {
      this.reader = null
      this.port = null
    }
  }

  useManualWeight() {
    const value = this.normalizeWeight(this.manualWeightTarget.value)
    if (value <= 0) {
      this.updateStatus("Ingresa un peso valido")
      return
    }
    this.updateWeight(value)
    this.updateStatus("Peso manual listo")
  }

  async readLoop() {
    const decoder = new TextDecoderStream()
    this.port.readable.pipeTo(decoder.writable).catch(() => {})
    this.reader = decoder.readable.getReader()
    let buffer = ""

    while (this.keepReading) {
      try {
        const { value, done } = await this.reader.read()
        if (done) break
        buffer += value
        if (buffer.length > 100) buffer = buffer.slice(-100)

        const lines = buffer.split(/\r?\n/)
        buffer = lines.pop() || ""

        lines.forEach((line) => {
          const weight = this.parseWeight(line)
          this.updateWeight(weight)
        })

        // Esperar una linea completa evita usar una lectura serial parcial.

      } catch (err) {
        this.updateStatus(`Lectura detenida: ${err.message}`)
        break
      }
    }
  }

  parseWeight(raw) {
    const text = String(raw || "").replace(",", ".")
    const match = text.match(/-?\d+(?:\.\d+)?/)
    if (!match) return 0

    const value = parseFloat(match[0])
    if (!Number.isFinite(value) || value <= 0) return 0

    if (/g\b/i.test(text) && !/kg\b/i.test(text)) {
      return this.normalizeWeight(value / 1000)
    }

    return this.normalizeWeight(value)
  }

  normalizeWeight(value) {
    const number = parseFloat(value)
    if (!Number.isFinite(number)) return 0
    return Math.round(number * 1000) / 1000
  }

  updateWeight(weightKg) {
    this.currentWeightKg = this.normalizeWeight(weightKg)
    this.weightTarget.textContent = `${this.currentWeightKg.toFixed(3)} kg`
    window.dispatchEvent(new CustomEvent("pos:scale-weight", {
      detail: { weightKg: this.currentWeightKg }
    }))
  }

  updateStatus(message) {
    this.statusTarget.textContent = message
  }
}
