<script setup>
import { fmtArs as fmt, fmtFecha } from '~/composables/useFormato'

const route = useRoute()
const db = useDb()
const obraId = route.params.id

// Tabs internos: Caja / Presupuesto / Retiros
const tab = ref('caja')
const tabs = [
  { id: 'caja', label: 'Caja' },
  { id: 'presupuesto', label: 'Presupuesto' },
  { id: 'retiros', label: 'Retiros' },
]

// ─── Estado cargado de la DB ───────────────────────────────────────────────
const obra = ref({ id: obraId, nombre_direccion: '', estado: 'activa', cliente: null, tipo_cambio_fallback: null })
const saldosRaw = ref(null)
const movimientos = ref([])
const items = ref([])
const retiros = ref([])
const convergencia = ref(null)
const proveedores = ref([])
const cargando = ref(true)

// TC efectivo para una moneda: ARS=1, USD=fallback de la obra (o pide cargarlo)
function tcPara(moneda) {
  if (moneda === 'ARS') return 1
  return obra.value.tipo_cambio_fallback || null
}

async function cargarObra() {
  obra.value = await db.getObra(obraId)
}
async function cargarSaldos() {
  saldosRaw.value = await db.getSaldosObra(obraId)
}
async function cargarMovimientos() {
  movimientos.value = await db.getMovimientos(obraId)
}
async function cargarItems() {
  items.value = await db.getItems(obraId)
}
async function cargarRetiros() {
  retiros.value = await db.getRetiros(obraId)
}
async function cargarConvergencia() {
  convergencia.value = await db.getConvergencia(obraId)
}

onMounted(async () => {
  try {
    await cargarObra()
    await Promise.all([cargarSaldos(), cargarMovimientos(), cargarItems(), cargarRetiros(), cargarConvergencia()])
    proveedores.value = await db.getProveedores()
  } catch (e) {
    console.error(e)
  } finally {
    cargando.value = false
  }
})

// Saldos clave de la obra (labels reales del Excel, hoja Caja)
const saldos = computed(() => ({
  aCobrar: Number(saldosRaw.value?.saldo_a_cobrar_ars ?? 0),
  deudaProveedores: Number(saldosRaw.value?.deuda_proveedores_ars ?? 0),
  saldoCaja: Number(saldosRaw.value?.saldo_caja_ars ?? 0),
  honorariosRetirar: Number(convergencia.value?.disponible_para_retirar_ars ?? 0),
}))

const tipoMeta = {
  cobro_cliente: { label: 'Cobro', badge: 'badge--cobro' },
  pago_proveedor: { label: 'Pago', badge: 'badge--pago' },
  retiro: { label: 'Retiro', badge: 'badge--retiro' },
}

// Monto firmado en ARS de un movimiento (cobro +, pago -), para la columna Monto
function montoFirmado(m) {
  const ars = Number(m.monto) * Number(m.tipo_cambio)
  return m.tipo === 'cobro_cliente' ? ars : -ars
}
// Texto de descripción: para pagos muestra el proveedor
function descMov(m) {
  if (m.tipo === 'pago_proveedor' && m.proveedor?.nombre) return m.proveedor.nombre
  return m.medio_pago ? `(${m.medio_pago})` : ''
}

const fechaHoy = new Date().toISOString().split('T')[0]
const formMov = reactive({ tipo: '', proveedorId: '', monto: '', moneda: 'ARS', medio: '', fecha: fechaHoy })
const esPago = computed(() => formMov.tipo === 'pago_proveedor')
const cajaFormOpen = ref(false)
const guardandoMov = ref(false)
const enDolares = computed({
  get: () => formMov.moneda === 'USD',
  set: (v) => { formMov.moneda = v ? 'USD' : 'ARS' },
})
const errMov = reactive({})
async function agregarMovimiento() {
  Object.keys(errMov).forEach((k) => delete errMov[k])
  if (!formMov.tipo) errMov.tipo = 'Elegí el tipo.'
  if (esPago.value && !formMov.proveedorId) errMov.proveedor = 'Elegí el proveedor.'
  if (!formMov.monto || Number(formMov.monto) <= 0) errMov.monto = 'Ingresá un monto mayor a cero.'
  if (!formMov.fecha) errMov.fecha = 'Elegí la fecha.'
  if (!formMov.medio) errMov.medio = 'Elegí el medio de pago.'
  const tc = tcPara(formMov.moneda)
  if (tc == null) errMov.monto = 'Cargá el valor del dólar en Configuración para usar USD.'
  if (Object.keys(errMov).length) return

  guardandoMov.value = true
  try {
    await db.crearMovimiento({
      obra_id: obraId,
      tipo: formMov.tipo,
      proveedor_id: esPago.value ? formMov.proveedorId : null,
      monto: Number(formMov.monto),
      moneda: formMov.moneda,
      tipo_cambio: tc,
      medio_pago: formMov.medio,
      fecha: formMov.fecha,
    })
    Object.assign(formMov, { tipo: '', proveedorId: '', monto: '', moneda: 'ARS', medio: '', fecha: fechaHoy })
    cajaFormOpen.value = false
    await Promise.all([cargarMovimientos(), cargarSaldos(), cargarConvergencia()])
  } catch (e) {
    errMov.monto = 'No se pudo guardar. Reintentá.'
    console.error(e)
  } finally {
    guardandoMov.value = false
  }
}

function esPositivo(n) {
  return Number(n) >= 0
}

// Presupuesto: totales desde las columnas derivadas de la view
const totalPresupuesto = computed(() => items.value.reduce((a, i) => a + Number(i.total_ars || 0), 0))
const totalHonorarios = computed(() => items.value.reduce((a, i) => a + Number(i.honorario_ars || 0), 0))

const itemFormOpen = ref(false)
// costo = valor proveedor [interno]; presupuesto = precio de lista al cliente (H);
// final = lo que paga el cliente (I, default = presupuesto); notas [interno].
const formItem = reactive({ rubro: '', detalle: '', costo: '', presupuesto: '', valor: '', notas: '' })
const guardandoItem = ref(false)
const errItem = reactive({})

// Autocompletar como el Excel: al cargar el costo, sugerir presupuesto = costo × 1.21.
// Al cargar/cambiar el presupuesto, sugerir valor final = presupuesto. Todo editable.
function sugerirPresupuesto() {
  const costo = Number(formItem.costo) || 0
  if (costo > 0 && !formItem.presupuesto) {
    formItem.presupuesto = String(Math.round(costo * 1.21))
  }
}
function sugerirFinal() {
  if (formItem.presupuesto && !formItem.valor) {
    formItem.valor = formItem.presupuesto
  }
  delete errItem.valor
}

async function agregarItem() {
  Object.keys(errItem).forEach((k) => delete errItem[k])
  if (!formItem.rubro.trim()) errItem.rubro = 'Elegí o escribí un rubro.'
  if (!formItem.detalle.trim()) errItem.detalle = 'Ingresá el detalle.'
  if (!formItem.valor || Number(formItem.valor) <= 0) errItem.valor = 'Ingresá un valor mayor a cero.'
  if (Object.keys(errItem).length) return

  guardandoItem.value = true
  try {
    const rubroId = await db.resolverRubroId(formItem.rubro)
    const costo = Number(formItem.costo) || 0
    const final = Number(formItem.valor)
    // presupuesto: lo cargado, o el final si no lo separaron (adicional = 0)
    const presupuesto = Number(formItem.presupuesto) || final
    await db.crearItem({
      obra_id: obraId,
      fecha: fechaHoy,
      rubro_id: rubroId,
      detalle: formItem.detalle.trim(),
      valor_proveedor: costo,
      valor_presupuesto: presupuesto,
      valor_final: final,
      notas: formItem.notas.trim() || null,
      moneda: 'ARS',
      moneda_proveedor: 'ARS',
    })
    Object.assign(formItem, { rubro: '', detalle: '', costo: '', presupuesto: '', valor: '', notas: '' })
    itemFormOpen.value = false
    await Promise.all([cargarItems(), cargarSaldos(), cargarConvergencia()])
  } catch (e) {
    errItem.valor = 'No se pudo guardar. Reintentá.'
    console.error(e)
  } finally {
    guardandoItem.value = false
  }
}

// ─── Retiros: convergencia 50/50 ───────────────────────────────────────────
const cvg = computed(() => ({
  ganancia_cobrada_ars: Number(convergencia.value?.ganancia_cobrada_ars ?? 0),
  disponible_retiro_ars: Number(convergencia.value?.disponible_para_retirar_ars ?? 0),
  total_retiros_nancy_ars: Number(convergencia.value?.total_retiros_nancy_ars ?? 0),
  total_retiros_sol_ars: Number(convergencia.value?.total_retiros_sol_ars ?? 0),
  target_nancy_ars: Number(convergencia.value?.target_nancy_ars ?? 0),
  target_sol_ars: Number(convergencia.value?.target_sol_ars ?? 0),
}))
const nancyWidth = computed(() => {
  const t = cvg.value.target_nancy_ars
  return (t > 0 ? Math.min(100, (cvg.value.total_retiros_nancy_ars / t) * 100) : 0) + '%'
})
const solWidth = computed(() => {
  const t = cvg.value.target_sol_ars
  return (t > 0 ? Math.min(100, (cvg.value.total_retiros_sol_ars / t) * 100) : 0) + '%'
})
const difSocias = computed(() => Math.abs(cvg.value.total_retiros_nancy_ars - cvg.value.total_retiros_sol_ars))
const socioAtras = computed(() =>
  cvg.value.total_retiros_nancy_ars >= cvg.value.total_retiros_sol_ars ? 'Solana' : 'Nancy',
)

const retiroFormOpen = ref(false)
const guardandoRetiro = ref(false)
// Total a retirar + reparto 50/50 editable: al tipear el total, prellena mitad y mitad.
const formRetiro = reactive({ total: '', nancy: '', sol: '', fecha: fechaHoy })
function repartir5050() {
  const t = Number(formRetiro.total) || 0
  const mitad = Math.round((t / 2) * 100) / 100
  formRetiro.nancy = t ? String(mitad) : ''
  formRetiro.sol = t ? String(t - mitad) : ''
  delete errRetiro.monto
}
const errRetiro = reactive({})
async function registrarRetiro() {
  Object.keys(errRetiro).forEach((k) => delete errRetiro[k])
  const totalNancy = Number(formRetiro.nancy) || 0
  const totalSol = Number(formRetiro.sol) || 0
  if (totalNancy <= 0 && totalSol <= 0) errRetiro.monto = 'Ingresá un retiro para Nancy o para Solana.'
  if (!formRetiro.fecha) errRetiro.fecha = 'Elegí la fecha.'
  if (Object.keys(errRetiro).length) return

  guardandoRetiro.value = true
  try {
    await db.crearRetiro({
      obra_id: obraId,
      fecha: formRetiro.fecha,
      monto_nancy: totalNancy,
      monto_sol: totalSol,
      moneda: 'ARS',
      tipo_cambio: 1,
    })
    Object.assign(formRetiro, { total: '', nancy: '', sol: '', fecha: fechaHoy })
    retiroFormOpen.value = false
    await Promise.all([cargarRetiros(), cargarConvergencia(), cargarSaldos(), cargarMovimientos()])
  } catch (e) {
    errRetiro.monto = 'No se pudo guardar. Reintentá.'
    console.error(e)
  } finally {
    guardandoRetiro.value = false
  }
}

// Exportar presupuesto: arma el documento (oculto) y dispara el diálogo de guardar PDF
// del navegador directo, sin pantalla intermedia. SOLO columnas F–K (nunca costo/ganancia).
const itemsExport = ref([])
const exportando = ref(false)
async function exportar() {
  if (exportando.value) return
  exportando.value = true
  try {
    itemsExport.value = await db.getPresupuestoCliente(obraId)
    await nextTick()
    window.print()
  } catch (e) {
    console.error(e)
  } finally {
    exportando.value = false
  }
}

// Al cambiar de tab: conservar lo escrito, pero limpiar errores y cerrar forms abiertos
function cambiarTab(id) {
  tab.value = id
  Object.keys(errMov).forEach((k) => delete errMov[k])
  Object.keys(errItem).forEach((k) => delete errItem[k])
  Object.keys(errRetiro).forEach((k) => delete errRetiro[k])
  cajaFormOpen.value = false
  itemFormOpen.value = false
  retiroFormOpen.value = false
}
</script>

<template>
  <div class="shell">
    <header class="page-header page-header--plain">
      <NuxtLink to="/" class="back">
        <svg width="14" height="14" viewBox="0 0 14 14" fill="none">
          <path d="M9 2L4 7l5 5" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round" />
        </svg>
        Obras
      </NuxtLink>
      <div class="page-header__row">
        <div class="page-header__titles">
          <template v-if="cargando">
            <Skeleton width="240px" height="28px" />
            <Skeleton width="140px" height="15px" radius="4px" />
          </template>
          <template v-else>
            <h1 class="title">{{ obra.nombre_direccion }}</h1>
            <p class="obra-meta">
              {{ obra.cliente?.nombre }}
              <span class="dot" :class="'dot--' + obra.estado"></span>
              {{ obra.estado }}
            </p>
          </template>
        </div>
        <div class="page-header__actions">
          <NuxtLink :to="'/obras/' + obra.id + '/configuracion'" class="btn btn--secondary">Configuración</NuxtLink>
          <button type="button" class="btn btn--primary" @click="exportar">Exportar</button>
        </div>
      </div>
    </header>

    <div class="saldos">
      <div class="saldo">
        <span class="saldo__label">A cobrar del cliente</span>
        <Skeleton v-if="cargando" width="80%" height="25px" />
        <span v-else class="saldo__value monto">{{ fmt(saldos.aCobrar) }}</span>
      </div>
      <div class="saldo">
        <span class="saldo__label">Deuda a proveedores</span>
        <Skeleton v-if="cargando" width="80%" height="25px" />
        <span v-else class="saldo__value monto monto--neg">{{ fmt(saldos.deudaProveedores) }}</span>
      </div>
      <div class="saldo">
        <span class="saldo__label">Saldo en caja</span>
        <Skeleton v-if="cargando" width="80%" height="25px" />
        <span v-else class="saldo__value monto" :class="esPositivo(saldos.saldoCaja) ? 'monto--pos' : 'monto--neg'">{{ fmt(saldos.saldoCaja) }}</span>
      </div>
      <div class="saldo saldo--accent">
        <span class="saldo__label">Honorarios a retirar</span>
        <Skeleton v-if="cargando" width="80%" height="25px" />
        <span v-else class="saldo__value monto monto--accent">{{ fmt(saldos.honorariosRetirar) }}</span>
      </div>
    </div>

    <div class="tabs" role="tablist">
      <button v-for="t in tabs" :key="t.id" type="button" class="tab" :class="{ 'tab--active': tab === t.id }" @click="cambiarTab(t.id)">{{ t.label }}</button>
    </div>

    <div v-if="tab === 'caja'" class="tabpanel">
      <section class="panel">
        <div class="panel__head split">
          <span class="eyebrow">Movimientos</span>
          <button class="btn btn--primary btn--sm" @click="cajaFormOpen = !cajaFormOpen">
            <svg width="13" height="13" viewBox="0 0 14 14" fill="none">
              <path v-if="cajaFormOpen" d="M1 7h12" stroke="currentColor" stroke-width="2" stroke-linecap="round" />
              <path v-else d="M7 1v12M1 7h12" stroke="currentColor" stroke-width="2" stroke-linecap="round" />
            </svg>
            Registrar movimiento
          </button>
        </div>

        <form v-if="cajaFormOpen" class="mov-form" @submit.prevent="agregarMovimiento">
          <div class="field-group col-tipo">
            <label class="label">Tipo</label>
            <select v-model="formMov.tipo" class="field" :class="{ 'field--error': errMov.tipo }" @change="delete errMov.tipo">
              <option value="" disabled>Seleccioná tipo</option>
              <option value="cobro_cliente">Cobro del cliente</option>
              <option value="pago_proveedor">Pago a proveedor</option>
            </select>
            <span v-if="errMov.tipo" class="field-error">{{ errMov.tipo }}</span>
          </div>
          <div v-if="esPago" class="field-group col-prov">
            <label class="label">Proveedor</label>
            <select v-model="formMov.proveedorId" class="field" :class="{ 'field--error': errMov.proveedor }" @change="delete errMov.proveedor">
              <option value="" disabled>Seleccioná proveedor</option>
              <option v-for="p in proveedores" :key="p.id" :value="p.id">{{ p.nombre }}</option>
            </select>
            <span v-if="errMov.proveedor" class="field-error">{{ errMov.proveedor }}</span>
          </div>
          <div class="field-group col-monto">
            <label class="label">Monto</label>
            <div class="monto-input">
              <input v-model="formMov.monto" type="number" class="field field--num" :class="{ 'field--error': errMov.monto }" placeholder="0" @input="delete errMov.monto" />
              <button type="button" class="moneda-toggle" :class="{ 'moneda-toggle--on': enDolares }" @click="enDolares = !enDolares">
                {{ enDolares ? 'US$' : '$' }}
              </button>
            </div>
            <span v-if="errMov.monto" class="field-error">{{ errMov.monto }}</span>
          </div>
          <div class="field-group col-fecha">
            <label class="label">Fecha</label>
            <input v-model="formMov.fecha" type="date" class="field" :class="{ 'field--error': errMov.fecha }" @input="delete errMov.fecha" />
            <span v-if="errMov.fecha" class="field-error">{{ errMov.fecha }}</span>
          </div>
          <div class="field-group col-medio">
            <label class="label">Medio de pago</label>
            <select v-model="formMov.medio" class="field" :class="{ 'field--error': errMov.medio }" @change="delete errMov.medio">
              <option value="" disabled>Seleccioná medio</option>
              <option value="transferencia">Transferencia</option>
              <option value="efectivo">Efectivo</option>
            </select>
            <span v-if="errMov.medio" class="field-error">{{ errMov.medio }}</span>
          </div>
          <div class="field-group col-submit">
            <button type="submit" class="btn btn--primary" :disabled="guardandoMov">{{ guardandoMov ? 'Guardando…' : 'Agregar movimiento' }}</button>
          </div>
        </form>

        <p v-if="!movimientos.length" class="estado-msg">Todavía no hay movimientos en esta obra.</p>
        <table v-else class="table">
          <thead>
            <tr>
              <th style="width: 92px">Fecha</th>
              <th>Detalle</th>
              <th style="width: 100px">Tipo</th>
              <th class="num" style="width: 150px">Monto</th>
              <th class="num" style="width: 150px">Saldo</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="m in movimientos" :key="m.id">
              <td class="cell-date">{{ fmtFecha(m.fecha) }}</td>
              <td class="cell-muted">{{ descMov(m) }}</td>
              <td><span class="badge" :class="tipoMeta[m.tipo].badge">{{ tipoMeta[m.tipo].label }}</span></td>
              <td class="num monto" :class="esPositivo(montoFirmado(m)) ? 'monto--pos' : 'monto--neg'">{{ esPositivo(montoFirmado(m)) ? '+' : '' }}{{ fmt(montoFirmado(m)) }}</td>
              <td class="num monto cell-saldo">{{ fmt(m.saldo_acumulado_ars) }}</td>
            </tr>
          </tbody>
        </table>
      </section>
    </div>

    <div v-else-if="tab === 'presupuesto'" class="tabpanel">
      <section class="panel">
        <div class="panel__head split">
          <span class="eyebrow">Ítems del presupuesto</span>
          <button class="btn btn--primary btn--sm" @click="itemFormOpen = !itemFormOpen">
            <svg width="13" height="13" viewBox="0 0 14 14" fill="none">
              <path v-if="itemFormOpen" d="M1 7h12" stroke="currentColor" stroke-width="2" stroke-linecap="round" />
              <path v-else d="M7 1v12M1 7h12" stroke="currentColor" stroke-width="2" stroke-linecap="round" />
            </svg>
            Agregar ítem
          </button>
        </div>

        <form v-if="itemFormOpen" class="mov-form" @submit.prevent="agregarItem">
          <div class="field-group">
            <label class="label">Rubro</label>
            <RubroCombo v-model="formItem.rubro" placeholder="Ej: Albañilería" :invalid="!!errItem.rubro" @update:model-value="delete errItem.rubro" />
            <span v-if="errItem.rubro" class="field-error">{{ errItem.rubro }}</span>
          </div>
          <div class="field-group">
            <label class="label">Detalle</label>
            <input v-model="formItem.detalle" type="text" class="field" :class="{ 'field--error': errItem.detalle }" placeholder="Ej: Demolición y contrapiso" @input="delete errItem.detalle" />
            <span v-if="errItem.detalle" class="field-error">{{ errItem.detalle }}</span>
          </div>
          <div class="field-group">
            <label class="label">Costo del proveedor</label>
            <input v-model="formItem.costo" type="number" class="field field--num" placeholder="0" @blur="sugerirPresupuesto" />
            <span class="hint">Interno. Nunca sale en el presupuesto del cliente.</span>
          </div>
          <div class="field-group">
            <label class="label">Valor presupuesto</label>
            <input v-model="formItem.presupuesto" type="number" class="field field--num" placeholder="0" @blur="sugerirFinal" />
            <span class="hint">Precio de lista al cliente. Sugerido: costo × 1,21.</span>
          </div>
          <div class="field-group">
            <label class="label">Valor final</label>
            <input v-model="formItem.valor" type="number" class="field field--num" :class="{ 'field--error': errItem.valor }" placeholder="0" @input="delete errItem.valor" />
            <span v-if="errItem.valor" class="field-error">{{ errItem.valor }}</span>
            <span v-else class="hint">Lo que paga el cliente. Por defecto = presupuesto.</span>
          </div>
          <div class="field-group field-group--full">
            <label class="label">Notas</label>
            <input v-model="formItem.notas" type="text" class="field" placeholder="Opcional, interno" />
          </div>
          <div class="field-group col-submit">
            <button type="submit" class="btn btn--primary" :disabled="guardandoItem">{{ guardandoItem ? 'Guardando…' : 'Agregar ítem' }}</button>
          </div>
        </form>

        <p v-if="!items.length" class="estado-msg">Todavía no hay ítems en el presupuesto.</p>
        <table v-else class="table">
          <thead>
            <tr>
              <th style="width: 160px">Rubro</th>
              <th>Detalle</th>
              <th class="num" style="width: 150px">Valor final</th>
              <th class="num" style="width: 150px">Honorario</th>
              <th class="num" style="width: 160px">Total</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="it in items" :key="it.id">
              <td class="cell-strong">{{ it.rubro?.nombre || '—' }}</td>
              <td class="cell-muted">{{ it.detalle }}</td>
              <td class="num monto">{{ fmt(it.valor_final_ars) }}</td>
              <td class="num monto monto--accent">{{ fmt(it.honorario_ars) }}</td>
              <td class="num monto cell-saldo">{{ fmt(it.total_ars) }}</td>
            </tr>
          </tbody>
          <tfoot>
            <tr>
              <td colspan="3" class="cell-total-label">Total presupuesto</td>
              <td class="num monto monto--accent">{{ fmt(totalHonorarios) }}</td>
              <td class="num monto cell-total">{{ fmt(totalPresupuesto) }}</td>
            </tr>
          </tfoot>
        </table>
      </section>
    </div>

    <div v-else class="tabpanel">
      <section class="panel reparto">
        <div class="reparto__top">
          <span class="eyebrow">Reparto entre socias</span>
          <div class="reparto__stats">
            <span class="reparto__stat">Disponible <strong class="monto" :class="esPositivo(cvg.disponible_retiro_ars) ? 'monto--pos' : 'monto--neg'">{{ fmt(cvg.disponible_retiro_ars) }}</strong></span>
            <span class="reparto__stat">Ganancia cobrada <strong class="monto">{{ fmt(cvg.ganancia_cobrada_ars) }}</strong></span>
          </div>
        </div>

        <div class="reparto__bars">
          <div class="progress">
            <div class="progress__head">
              <span class="progress__name">Nancy</span>
              <span class="progress__val monto">{{ fmt(cvg.total_retiros_nancy_ars) }} <span class="progress__target">/ {{ fmt(cvg.target_nancy_ars) }}</span></span>
            </div>
            <div class="progress__track"><div class="progress__fill progress__fill--nancy" :style="{ width: nancyWidth }"></div></div>
          </div>
          <div class="progress">
            <div class="progress__head">
              <span class="progress__name">Solana</span>
              <span class="progress__val monto">{{ fmt(cvg.total_retiros_sol_ars) }} <span class="progress__target">/ {{ fmt(cvg.target_sol_ars) }}</span></span>
            </div>
            <div class="progress__track"><div class="progress__fill progress__fill--sol" :style="{ width: solWidth }"></div></div>
          </div>
        </div>

        <p v-if="difSocias" class="reparto__note">
          Para emparejar, <strong>{{ socioAtras }}</strong> debería retirar {{ fmt(difSocias) }} más.
        </p>
        <p v-else class="reparto__note reparto__note--ok">Los retiros están emparejados al 50/50.</p>
      </section>

      <section class="panel">
        <div class="panel__head split">
          <span class="eyebrow">Retiros</span>
          <button class="btn btn--primary btn--sm" @click="retiroFormOpen = !retiroFormOpen">
            <svg width="13" height="13" viewBox="0 0 14 14" fill="none">
              <path v-if="retiroFormOpen" d="M1 7h12" stroke="currentColor" stroke-width="2" stroke-linecap="round" />
              <path v-else d="M7 1v12M1 7h12" stroke="currentColor" stroke-width="2" stroke-linecap="round" />
            </svg>
            Registrar retiro
          </button>
        </div>

        <form v-if="retiroFormOpen" class="mov-form" @submit.prevent="registrarRetiro">
          <div class="field-group">
            <label class="label">Total a retirar</label>
            <input v-model="formRetiro.total" type="number" class="field field--num" placeholder="0" @input="repartir5050" />
            <span class="hint">Prellena 50/50. Podés ajustar cada monto abajo.</span>
          </div>
          <div class="field-group">
            <label class="label">Fecha</label>
            <input v-model="formRetiro.fecha" type="date" class="field" :class="{ 'field--error': errRetiro.fecha }" @input="delete errRetiro.fecha" />
            <span v-if="errRetiro.fecha" class="field-error">{{ errRetiro.fecha }}</span>
          </div>
          <div class="field-group">
            <label class="label">Nancy</label>
            <input v-model="formRetiro.nancy" type="number" class="field field--num" :class="{ 'field--error': errRetiro.monto }" placeholder="0" @input="delete errRetiro.monto" />
          </div>
          <div class="field-group">
            <label class="label">Solana</label>
            <input v-model="formRetiro.sol" type="number" class="field field--num" :class="{ 'field--error': errRetiro.monto }" placeholder="0" @input="delete errRetiro.monto" />
          </div>
          <span v-if="errRetiro.monto" class="field-error field-error--full">{{ errRetiro.monto }}</span>
          <div class="field-group col-submit">
            <button type="submit" class="btn btn--primary" :disabled="guardandoRetiro">{{ guardandoRetiro ? 'Guardando…' : 'Registrar retiro' }}</button>
          </div>
        </form>

        <p v-if="!retiros.length" class="estado-msg">Todavía no hay retiros en esta obra.</p>
        <table v-else class="table">
          <thead>
            <tr>
              <th style="width: 92px">Fecha</th>
              <th class="num">Nancy</th>
              <th class="num">Solana</th>
              <th class="num" style="width: 150px">Total</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="r in retiros" :key="r.id">
              <td class="cell-date">{{ fmtFecha(r.fecha) }}</td>
              <td class="num monto">{{ fmt(Number(r.monto_nancy) * Number(r.tipo_cambio)) }}</td>
              <td class="num monto">{{ fmt(Number(r.monto_sol) * Number(r.tipo_cambio)) }}</td>
              <td class="num monto cell-saldo">{{ fmt((Number(r.monto_nancy) + Number(r.monto_sol)) * Number(r.tipo_cambio)) }}</td>
            </tr>
          </tbody>
        </table>
      </section>
    </div>

    <!-- Documento del presupuesto: oculto en pantalla, solo aparece al imprimir (Exportar) -->
    <div class="solo-print">
      <DocumentoPresupuesto :obra="obra" :items="itemsExport" />
    </div>
  </div>
</template>

<style scoped>
/* Documento del presupuesto: oculto en pantalla, el @media print global lo muestra */
.solo-print { display: none; }

.saldos {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 1px;
  margin: 0 0 28px;
  background: var(--border);
  border: 1px solid var(--border);
  border-radius: var(--radius-lg);
  overflow: hidden;
}
.saldo { display: flex; flex-direction: column; gap: 12px; padding: 20px 22px; background: var(--surface); }
.saldo--accent { background: var(--accent-subtle); }
.saldo__label { font-size: 12px; font-weight: 600; text-transform: uppercase; letter-spacing: 0.05em; color: var(--ink-muted); }
.saldo__value { font-size: 25px; letter-spacing: -0.4px; }

.tabs { display: flex; gap: 4px; border-bottom: 1px solid var(--border); margin-bottom: 24px; }
.tab {
  position: relative;
  padding: 14px 22px 16px;
  background: transparent;
  border: none;
  font-family: inherit;
  font-size: 16px;
  font-weight: 600;
  color: var(--ink-muted);
  cursor: pointer;
  transition: color 150ms var(--ease-out);
}
.tab::after {
  content: ''; position: absolute; left: 22px; right: 22px; bottom: -1px; height: 2px;
  background: var(--accent); border-radius: 2px; transform: scaleX(0);
  transition: transform 200ms var(--ease-out);
}
.tab:hover { color: var(--ink); }
.tab--active { color: var(--accent); }
.tab--active::after { transform: scaleX(1); }

.tabpanel { display: flex; flex-direction: column; gap: 16px; }

.reparto { padding: 20px 22px; display: flex; flex-direction: column; gap: 18px; }
.reparto__top { display: flex; align-items: baseline; justify-content: space-between; gap: 20px; flex-wrap: wrap; }
.reparto__stats { display: flex; gap: 24px; }
.reparto__stat { font-size: 13px; color: var(--ink-muted); }
.reparto__stat strong { margin-left: 6px; font-size: 16px; font-weight: 500; color: var(--ink); }
.reparto__bars { display: flex; flex-direction: column; gap: 16px; }
.reparto__bars .progress { padding: 0; }
.reparto__bars .progress + .progress { border-top: none; }
.progress__target { color: var(--ink-faint); }
.reparto__note {
  padding: 11px 14px;
  background: var(--warning-bg);
  border-radius: var(--radius-sm);
  font-size: 14px;
  color: var(--warning);
}
.reparto__note strong { font-weight: 600; }
.reparto__note--ok { background: var(--positive-bg); color: var(--positive); }

.panel__head.split { display: flex; align-items: center; justify-content: space-between; }
.btn--sm { height: 36px; padding: 0 14px; font-size: 14px; }

.mov-form {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 16px 20px;
  padding: 18px;
  border-bottom: 1px solid var(--border-subtle);
}
.col-submit { grid-column: 1 / -1; display: flex; align-items: flex-end; justify-content: flex-end; }
.field-group--full { grid-column: 1 / -1; }
.field-error--full { grid-column: 1 / -1; margin-top: -8px; }

/* Monto con toggle de moneda integrado */
.monto-input { position: relative; display: flex; }
.monto-input .field { width: 100%; padding-right: 52px; }
.moneda-toggle {
  position: absolute;
  top: 50%;
  right: 5px;
  transform: translateY(-50%);
  min-width: 42px;
  height: 30px;
  background: var(--surface-raised);
  border: 1px solid var(--border);
  border-radius: var(--radius-sm);
  font-family: var(--font-mono);
  font-size: 14px;
  font-weight: 500;
  color: var(--ink-muted);
  cursor: pointer;
  transition: background 120ms var(--ease-out), color 120ms var(--ease-out);
}
.moneda-toggle--on { background: var(--accent); border-color: var(--accent); color: var(--surface); }

.cell-strong { font-weight: 600; color: var(--ink); }
.cell-muted { color: var(--ink-muted); }
.table tfoot td { padding: 15px 18px; border-top: 1px solid var(--border); background: var(--surface-raised); }
.cell-total-label { font-size: 12px; font-weight: 600; text-transform: uppercase; letter-spacing: 0.05em; color: var(--ink-muted); }
.cell-total { font-weight: 600; font-size: 16px; color: var(--ink); }

@media (max-width: 760px) {
  .saldos { grid-template-columns: repeat(2, 1fr); }
}
@media (max-width: 560px) {
  .mov-form { grid-template-columns: 1fr; }
}
</style>
