const { test } = require('node:test')
const assert = require('node:assert/strict')
const fs = require('node:fs')
const vm = require('node:vm')
const path = require('node:path')
const source = fs.readFileSync(path.resolve(__dirname, '../../app/javascript/controllers/scale_controller.js'), 'utf8').replace('import { Controller } from "@hotwired/stimulus"', 'class Controller {}').replace('export default class', 'globalThis.ScaleController = class')
const context = vm.createContext({ TextDecoderStream })
vm.runInContext(source, context)
function controller() {
  const scale = new context.ScaleController()
  scale.currentWeightKg = 1.25
  scale.updateWeight = (weight) => { scale.currentWeightKg = scale.normalizeWeight(weight) }
  scale.updateStatus = () => {}
  return scale
}
test('bridge: volver a cero elimina el peso anterior', () => {
  const scale = controller()
  scale.applyBridgeScale({ weightKg: 0, connected: true })
  assert.equal(scale.currentWeightKg, 0)
})
test('bridge: mensaje sin peso conserva la lectura', () => {
  const scale = controller()
  scale.applyBridgeScale({ connected: true })
  assert.equal(scale.currentWeightKg, 1.25)
})
test('interpreta gramos y coma decimal', () => {
  const scale = controller()
  assert.equal(scale.parseWeight('250 g'), 0.25)
  assert.equal(scale.parseWeight('1,250 kg'), 1.25)
})
test('serial: espera lineas completas y propaga el cero', async () => {
  const scale = controller()
  const readings = []
  scale.updateWeight = (weight) => readings.push(weight)
  scale.keepReading = true
  scale.port = { readable: new ReadableStream({ start(stream) {
    for (const chunk of ['1.', '250 kg\n', '0.000 kg\n']) stream.enqueue(new TextEncoder().encode(chunk))
    stream.close()
  } }) }
  await scale.readLoop()
  assert.deepEqual(readings, [1.25, 0])
})