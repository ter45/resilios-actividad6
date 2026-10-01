const { test } = require('node:test')
const assert = require('node:assert/strict')
const fs = require('node:fs')
const vm = require('node:vm')
const path = require('node:path')
const source = fs.readFileSync(path.resolve(__dirname, '../../app/javascript/controllers/search_controller.js'), 'utf8').replace('import { Controller } from "@hotwired/stimulus"', 'class Controller {}').replace('export default class', 'globalThis.SearchController = class')
function element() {
  return { dataset: {}, children: [], textContent: '', disabled: false, setAttribute() {}, append(child) { this.children.push(child) }, replaceChildren() { this.children = [] } }
}
function fixture(fetch) {
  const events = []
  const context = vm.createContext({ fetch, URLSearchParams, AbortController, setTimeout, clearTimeout,
    document: { createElement: element }, window: { dispatchEvent: event => events.push(event) },
    CustomEvent: class { constructor(type, data) { this.type = type; this.detail = data.detail } } })
  vm.runInContext(source, context)
  const controller = new context.SearchController()
  for (const name of ['input', 'results', 'previous', 'next', 'pageLabel', 'status']) controller[`${name}Target`] = element()
  controller.inputTarget.value = ''
  controller.currentPage = 1
  controller.requestId = 0
  controller.element = { querySelectorAll: () => [] }
  return { controller, events }
}
const response = (name, page = 1, has_more = false) => ({ ok: true, json: async () => ({ products: [{ id: 1, name, category_name: 'Granos', display_price: '$ 100', available_stock: 2, pricing_mode: 'unit' }], page, has_more }) })

test('una respuesta antigua no reemplaza una búsqueda reciente', async () => {
  const pending = []
  const { controller: c } = fixture(() => new Promise(resolve => pending.push(resolve)))
  const first = c.fetchResults('vieja', null)
  const second = c.fetchResults('nueva', null)
  pending[1](response('Nueva')); await second
  pending[0](response('Vieja')); await first
  assert.equal(c.resultsTarget.children[0].children[0].textContent, 'Nueva')
})

test('escribir invalida inmediatamente la solicitud anterior antes del debounce', async () => {
  let resolve
  const { controller: c } = fixture(() => new Promise(r => { resolve = r }))
  const old = c.fetchResults('anterior', null)
  c.inputTarget.value = 'nuevo'; c.perform()
  resolve(response('Vieja')); await old
  assert.equal(c.resultsTarget.children.length, 0)
  c.disconnect()
})

test('paginación conserva texto y categoría y habilita controles', async () => {
  const urls = []
  const { controller: c } = fixture(async url => { urls.push(url); return response('Arroz', 2, true) })
  await c.fetchResults('Arroz', '7', 2)
  assert.match(urls[0], /page=2/); assert.match(urls[0], /category_id=7/)
  assert.equal(c.currentPage, 2); assert.equal(c.nextTarget.disabled, false); assert.equal(c.previousTarget.disabled, false)
})

test('nombres se representan como texto y los productos agotados no se seleccionan', () => {
  const { controller: c, events } = fixture()
  const product = { name: '<img onerror=alert(1)>', available_stock: 0 }
  c.renderResults([product])
  assert.equal(c.resultsTarget.children[0].children[0].textContent, product.name)
  assert.equal(c.resultsTarget.children[0].disabled, true)
  c.selectProduct({ currentTarget: { dataset: { product: JSON.stringify(product) } } })
  assert.equal(events.length, 0)
})

test('selección conserva el producto por peso enviado al carrito', () => {
  const { controller: c, events } = fixture()
  c.selectProduct({ currentTarget: { dataset: { product: JSON.stringify({ id: 42, available_stock: 2.5, pricing_mode: 'weight' }) } } })
  assert.equal(events[0].type, 'pos:add-product'); assert.equal(events[0].detail.pricing_mode, 'weight')
})

test('escaneo sin stock no agrega al carrito', async () => {
  const { controller: c, events } = fixture(async () => ({ ok: true, json: async () => ({ id: 1, available_stock: 0 }) }))
  c.inputTarget.value = '1234567890123'
  await c.scan({ preventDefault() {} })
  assert.equal(events.length, 0); assert.equal(c.statusTarget.textContent, 'Producto sin disponibilidad')
})

test('error HTTP libera controles y muestra mensaje', async () => {
  const { controller: c } = fixture(async () => ({ ok: false, status: 500 }))
  await c.fetchResults('Arroz', null)
  assert.match(c.statusTarget.textContent, /No se pudo cargar/)
  assert.equal(c.nextTarget.disabled, true)
})
