<script setup>
import { fmtArs as fmt, fmtUsd, fmtFecha } from '~/composables/useFormato'

const route = useRoute()
const db = useDb()
// La URL puede traer slug o UUID. Tras cargar la obra, obraId pasa a ser el UUID real
// (todas las queries de caja/items/retiros filtran por obra_id real).
let obraId = route.params.id

// Tabs internos: Caja / Presupuesto / Retiros
const tab = ref('caja')
const tabs = [
  { id: 'caja', label: 'Caja' },
  { id: 'presupuesto', label: 'Presupuesto' },
  { id: 'deuda', label: 'Proveedores' },
  { id: 'retiros', label: 'Retiros' },
]

// ─── Estado cargado de la DB ───────────────────────────────────────────────
const obra = ref({ id: obraId, nombre_direccion: '', estado: 'activa', cliente: null })
const controlRaw = ref(null)
const movimientos = ref([])
const items = ref([])
const retiros = ref([])
const convergencia = ref(null)
const proveedores = ref([])
const cargando = ref(true)

async function cargarObra() {
  obra.value = await db.getObra(obraId)
  obraId = obra.value.id
}
async function cargarControl() {
  controlRaw.value = await db.getControl(obraId)
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
    await Promise.all([cargarControl(), cargarMovimientos(), cargarItems(), cargarRetiros(), cargarConvergencia()])
    proveedores.value = await db.getProveedores()
  } catch (e) {
    console.error(e)
  } finally {
    cargando.value = false
  }
})

// Bloque de control contable (Excel, hoja Caja filas 170-175). Control debe dar 0.
const control = computed(() => ({
  aCobrar: Number(controlRaw.value?.saldo_a_cobrar ?? 0),
  saldoCaja: Number(controlRaw.value?.saldo_caja ?? 0),
  deudaProveedores: Number(controlRaw.value?.deuda_proveedores ?? 0),
  adicionales: Number(controlRaw.value?.adicionales ?? 0),
  honorariosRetirar: Number(controlRaw.value?.honorarios_a_retirar ?? 0),
  total: Number(controlRaw.value?.control ?? 0),
}))
// Control redondeado: tolera centavos de redondeo (la flag salta solo si hay diferencia real)
const controlOk = computed(() => Math.abs(control.value.total) < 1)

// Monto firmado en ARS de un movimiento (cobro +, pago -), para la columna Monto
function montoFirmado(m) {
  const ars = Number(m.monto) * Number(m.tipo_cambio)
  return m.tipo === 'cobro_cliente' ? ars : -ars
}
// ¿El movimiento fue cargado en dólares?
function esUsd(m) {
  return m.moneda === 'USD'
}
// Monto firmado en la moneda original (USD), para mostrar como valor principal
function montoFirmadoOriginal(m) {
  const monto = Number(m.monto)
  return m.tipo === 'cobro_cliente' ? monto : -monto
}
// Detalle = acción + a quién. Cobro queda solo ("Cobro": el cliente es siempre el
// mismo en la obra); pago suma el proveedor ("Pago · Corralon Loyola").
function descMov(m) {
  if (m.tipo === 'pago_proveedor') return `Pago · ${m.proveedor?.nombre || 'Proveedor'}`
  if (m.tipo === 'cobro_cliente') return 'Cobro'
  return 'Retiro'
}

const fechaHoy = new Date().toISOString().split('T')[0]

// Options para los SelectField
const opcionesTipo = [
  { value: 'cobro_cliente', label: 'Cobro del cliente' },
  { value: 'pago_proveedor', label: 'Pago a proveedor' },
]
const opcionesMedio = [
  { value: 'transferencia', label: 'Transferencia' },
  { value: 'efectivo', label: 'Efectivo' },
]
const opcionesProveedor = computed(() => proveedores.value.map((p) => ({ value: p.id, label: p.nombre })))
const opcionesProveedorOpt = computed(() => [{ value: '', label: 'Sin asignar' }, ...opcionesProveedor.value])

const formMovVacio = () => ({ tipo: '', proveedorId: '', monto: '', moneda: 'ARS', tcManual: '', medio: '', fecha: fechaHoy })
const formMov = reactive(formMovVacio())
const esPago = computed(() => formMov.tipo === 'pago_proveedor')
const cajaFormOpen = ref(false)
const guardandoMov = ref(false)
// Id del movimiento en edición; null = alta nueva
const editandoId = ref(null)
const enDolares = computed({
  get: () => formMov.moneda === 'USD',
  set: (v) => {
    formMov.moneda = v ? 'USD' : 'ARS'
    // USD siempre es efectivo: fijar el medio y limpiar su error.
    if (v) { formMov.medio = 'efectivo'; delete errMov.medio }
  },
})

// TC efectivo del form: ARS=1; USD=valor del dólar ingresado para ese cobro.
// No hay fallback por obra: el dólar solo se carga al cobrar en USD, para pasarlo a pesos.
function tcFormMov() {
  if (formMov.moneda === 'ARS') return 1
  const manual = Number(formMov.tcManual)
  return manual > 0 ? manual : null
}
// Equivalente en pesos del monto del form, para previsualizar mientras se carga
const equivPesos = computed(() => {
  const tc = tcFormMov()
  const monto = Number(formMov.monto)
  if (formMov.moneda !== 'USD' || !tc || !(monto > 0)) return null
  return monto * tc
})

function abrirAltaMov() {
  editandoId.value = null
  Object.assign(formMov, formMovVacio())
  Object.keys(errMov).forEach((k) => delete errMov[k])
  cajaFormOpen.value = true
}
function editarMov(m) {
  editandoId.value = m.id
  Object.assign(formMov, {
    tipo: m.tipo,
    proveedorId: m.proveedor_id || '',
    monto: String(m.monto),
    moneda: m.moneda,
    tcManual: m.moneda === 'USD' ? String(m.tipo_cambio) : '',
    medio: m.medio_pago || '',
    fecha: m.fecha,
  })
  Object.keys(errMov).forEach((k) => delete errMov[k])
  cajaFormOpen.value = true
}
function cancelarMov() {
  editandoId.value = null
  Object.assign(formMov, formMovVacio())
  Object.keys(errMov).forEach((k) => delete errMov[k])
  cajaFormOpen.value = false
}

const errMov = reactive({})
async function agregarMovimiento() {
  Object.keys(errMov).forEach((k) => delete errMov[k])
  if (!formMov.tipo) errMov.tipo = 'Elegí el tipo.'
  if (esPago.value && !formMov.proveedorId) errMov.proveedor = 'Elegí el proveedor.'
  if (!formMov.monto || Number(formMov.monto) <= 0) errMov.monto = 'Ingresá un monto mayor a cero.'
  if (!formMov.fecha) errMov.fecha = 'Elegí la fecha.'
  if (!enDolares.value && !formMov.medio) errMov.medio = 'Elegí el medio de pago.'
  const tc = tcFormMov()
  if (tc == null) errMov.tcManual = 'Ingresá el valor del dólar.'
  if (Object.keys(errMov).length) return

  guardandoMov.value = true
  try {
    const payload = {
      obra_id: obraId,
      tipo: formMov.tipo,
      proveedor_id: esPago.value ? formMov.proveedorId : null,
      monto: Number(formMov.monto),
      moneda: formMov.moneda,
      tipo_cambio: tc,
      medio_pago: formMov.medio,
      fecha: formMov.fecha,
    }
    if (editandoId.value) {
      await db.actualizarMovimiento(editandoId.value, payload)
    } else {
      await db.crearMovimiento(payload)
    }
    editandoId.value = null
    Object.assign(formMov, formMovVacio())
    cajaFormOpen.value = false
    await Promise.all([cargarMovimientos(), cargarControl(), cargarConvergencia()])
  } catch (e) {
    errMov.monto = 'No se pudo guardar. Reintentá.'
    console.error(e)
  } finally {
    guardandoMov.value = false
  }
}

const borrandoId = ref(null)
async function borrarMov(m) {
  if (!confirm('¿Borrar este movimiento? No se puede deshacer.')) return
  borrandoId.value = m.id
  try {
    await db.eliminarMovimiento(m.id)
    if (editandoId.value === m.id) cancelarMov()
    await Promise.all([cargarMovimientos(), cargarControl(), cargarConvergencia()])
  } catch (e) {
    console.error(e)
  } finally {
    borrandoId.value = null
  }
}

function esPositivo(n) {
  return Number(n) >= 0
}

// Ordenado por rubro (después por detalle) para leer agrupado. No afecta los totales.
const itemsOrdenados = computed(() =>
  [...items.value].sort(
    (a, b) =>
      (a.rubro?.nombre || '').localeCompare(b.rubro?.nombre || '') ||
      (a.detalle || '').localeCompare(b.detalle || ''),
  ),
)

// Presupuesto: totales desde las columnas derivadas de la view
const totalPresupuesto = computed(() => items.value.reduce((a, i) => a + Number(i.total_ars || 0), 0))
const totalHonorarios = computed(() => items.value.reduce((a, i) => a + Number(i.honorario_ars || 0), 0))
const totalValorFinal = computed(() => items.value.reduce((a, i) => a + Number(i.valor_final_ars || 0), 0))

// Deuda por proveedor: presupuestado (costo de sus items) - pagado (movimientos a ese proveedor).
// Agrupa por nombre; muestra solo proveedores con presupuesto o pagos.
const deudaPorProveedor = computed(() => {
  const map = new Map()
  const get = (nombre) => {
    if (!map.has(nombre)) map.set(nombre, { nombre, presupuestado: 0, pagado: 0 })
    return map.get(nombre)
  }
  for (const it of items.value) {
    const nombre = it.proveedor?.nombre
    if (!nombre) continue
    get(nombre).presupuestado += Number(it.valor_proveedor_ars || 0)
  }
  for (const m of movimientos.value) {
    if (m.tipo !== 'pago_proveedor') continue
    const nombre = m.proveedor?.nombre
    if (!nombre) continue
    get(nombre).pagado += Number(m.monto) * Number(m.tipo_cambio)
  }
  return [...map.values()]
    .map((p) => ({ ...p, debo: p.presupuestado - p.pagado }))
    .sort((a, b) => b.debo - a.debo)
})
const deudaTotal = computed(() => deudaPorProveedor.value.reduce((a, p) => a + p.presupuestado, 0))
const pagadoTotal = computed(() => deudaPorProveedor.value.reduce((a, p) => a + p.pagado, 0))

const itemFormOpen = ref(false)
const editandoItemId = ref(null)
// Si el presupuesto exportado/visualizado muestra la columna proveedor.
const mostrarProveedor = ref(false)
// costo = valor proveedor [interno]; adicional = sobreprecio sobre el costo (switch);
// valor presupuesto = costo + adicional; valor final = lo que paga el cliente (default = presupuesto).
const formItemVacio = () => ({ proveedorId: '', rubro: '', detalle: '', costo: '', adicionalOn: false, adicional: '', valor: '', notas: '' })
const formItem = reactive(formItemVacio())
const guardandoItem = ref(false)
const errItem = reactive({})

// Valor presupuesto = costo + adicional (el adicional solo cuenta si el switch está activo).
const presupuestoItem = computed(() => {
  const costo = Number(formItem.costo) || 0
  const adicional = formItem.adicionalOn ? (Number(formItem.adicional) || 0) : 0
  return costo + adicional
})

// El valor final sigue al presupuesto (costo + adicional) hasta que el usuario lo
// edite a mano: ahí queda fijo (precio especial al cliente).
const valorEditado = ref(false)

function toggleAdicional() {
  formItem.adicionalOn = !formItem.adicionalOn
  if (!formItem.adicionalOn) formItem.adicional = ''
  sugerirFinal()
}
// Sugerir valor final = presupuesto, salvo que el usuario ya lo haya editado.
function sugerirFinal() {
  if (!valorEditado.value && presupuestoItem.value > 0) {
    formItem.valor = String(presupuestoItem.value)
  }
}
// Marca el valor final como editado manualmente (deja de auto-sugerirse).
function onValorInput() {
  valorEditado.value = true
  delete errItem.valor
}

// Al elegir proveedor, autocompletar el rubro si el proveedor tiene uno.
function onProveedorItem() {
  const p = proveedores.value.find((x) => x.id === formItem.proveedorId)
  if (p?.rubro?.nombre) {
    formItem.rubro = p.rubro.nombre
    delete errItem.rubro
  }
}

function abrirAltaItem() {
  editandoItemId.value = null
  Object.assign(formItem, formItemVacio())
  valorEditado.value = false
  Object.keys(errItem).forEach((k) => delete errItem[k])
  itemFormOpen.value = true
}
function editarItem(it) {
  editandoItemId.value = it.id
  const tieneAdicional = Number(it.valor_presupuesto) > Number(it.valor_proveedor)
  Object.assign(formItem, {
    proveedorId: it.proveedor_id || '',
    rubro: it.rubro?.nombre || '',
    detalle: it.detalle || '',
    costo: String(it.valor_proveedor ?? ''),
    adicionalOn: tieneAdicional,
    adicional: tieneAdicional ? String(Number(it.valor_presupuesto) - Number(it.valor_proveedor)) : '',
    valor: String(it.valor_final ?? ''),
    notas: it.notas || '',
  })
  valorEditado.value = true
  Object.keys(errItem).forEach((k) => delete errItem[k])
  itemFormOpen.value = true
}
function cancelarItem() {
  editandoItemId.value = null
  Object.assign(formItem, formItemVacio())
  valorEditado.value = false
  Object.keys(errItem).forEach((k) => delete errItem[k])
  itemFormOpen.value = false
}

async function agregarItem() {
  Object.keys(errItem).forEach((k) => delete errItem[k])
  if (!formItem.rubro.trim()) errItem.rubro = 'Elegí o escribí un rubro.'
  if (!formItem.valor || Number(formItem.valor) <= 0) errItem.valor = 'Ingresá un valor mayor a cero.'
  if (Object.keys(errItem).length) return

  guardandoItem.value = true
  try {
    const rubroId = await db.resolverRubroId(formItem.rubro)
    const costo = Number(formItem.costo) || 0
    const final = Number(formItem.valor)
    const presupuesto = presupuestoItem.value || final
    const payload = {
      rubro_id: rubroId,
      proveedor_id: formItem.proveedorId || null,
      detalle: formItem.detalle.trim() || null,
      valor_proveedor: costo,
      valor_presupuesto: presupuesto,
      valor_final: final,
      notas: formItem.notas.trim() || null,
      moneda: 'ARS',
      moneda_proveedor: 'ARS',
    }
    if (editandoItemId.value) {
      await db.actualizarItem(editandoItemId.value, payload)
    } else {
      await db.crearItem({ obra_id: obraId, fecha: fechaHoy, ...payload })
    }
    editandoItemId.value = null
    Object.assign(formItem, formItemVacio())
    valorEditado.value = false
    itemFormOpen.value = false
    await Promise.all([cargarItems(), cargarControl(), cargarConvergencia()])
  } catch (e) {
    errItem.valor = 'No se pudo guardar. Reintentá.'
    console.error(e)
  } finally {
    guardandoItem.value = false
  }
}

const borrandoItemId = ref(null)
async function borrarItem(it) {
  if (!confirm('¿Borrar este ítem? No se puede deshacer.')) return
  borrandoItemId.value = it.id
  try {
    await db.eliminarItem(it.id)
    if (editandoItemId.value === it.id) cancelarItem()
    await Promise.all([cargarItems(), cargarControl(), cargarConvergencia()])
  } catch (e) {
    console.error(e)
  } finally {
    borrandoItemId.value = null
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
const editandoRetiroId = ref(null)
// Total a retirar + reparto 50/50 editable: al tipear el total, prellena mitad y mitad.
const formRetiroVacio = () => ({ total: '', nancy: '', sol: '', fecha: fechaHoy })
const formRetiro = reactive(formRetiroVacio())
function repartir5050() {
  const t = Number(formRetiro.total) || 0
  const mitad = Math.round((t / 2) * 100) / 100
  formRetiro.nancy = t ? String(mitad) : ''
  formRetiro.sol = t ? String(t - mitad) : ''
  delete errRetiro.monto
}
const errRetiro = reactive({})

function abrirAltaRetiro() {
  editandoRetiroId.value = null
  Object.assign(formRetiro, formRetiroVacio())
  Object.keys(errRetiro).forEach((k) => delete errRetiro[k])
  retiroFormOpen.value = true
}
function editarRetiro(r) {
  editandoRetiroId.value = r.id
  const nancy = Number(r.monto_nancy) || 0
  const sol = Number(r.monto_sol) || 0
  Object.assign(formRetiro, {
    total: String(nancy + sol),
    nancy: String(nancy),
    sol: String(sol),
    fecha: r.fecha,
  })
  Object.keys(errRetiro).forEach((k) => delete errRetiro[k])
  retiroFormOpen.value = true
}
function cancelarRetiro() {
  editandoRetiroId.value = null
  Object.assign(formRetiro, formRetiroVacio())
  Object.keys(errRetiro).forEach((k) => delete errRetiro[k])
  retiroFormOpen.value = false
}

async function registrarRetiro() {
  Object.keys(errRetiro).forEach((k) => delete errRetiro[k])
  const totalNancy = Number(formRetiro.nancy) || 0
  const totalSol = Number(formRetiro.sol) || 0
  if (totalNancy <= 0 && totalSol <= 0) errRetiro.monto = 'Ingresá un retiro para Nancy o para Solana.'
  if (!formRetiro.fecha) errRetiro.fecha = 'Elegí la fecha.'
  if (Object.keys(errRetiro).length) return

  guardandoRetiro.value = true
  try {
    const payload = {
      fecha: formRetiro.fecha,
      monto_nancy: totalNancy,
      monto_sol: totalSol,
      moneda: 'ARS',
      tipo_cambio: 1,
    }
    if (editandoRetiroId.value) {
      await db.actualizarRetiro(editandoRetiroId.value, payload)
    } else {
      await db.crearRetiro({ obra_id: obraId, ...payload })
    }
    editandoRetiroId.value = null
    Object.assign(formRetiro, formRetiroVacio())
    retiroFormOpen.value = false
    await Promise.all([cargarRetiros(), cargarConvergencia(), cargarControl(), cargarMovimientos()])
  } catch (e) {
    errRetiro.monto = 'No se pudo guardar. Reintentá.'
    console.error(e)
  } finally {
    guardandoRetiro.value = false
  }
}

const borrandoRetiroId = ref(null)
async function borrarRetiro(r) {
  if (!confirm('¿Borrar este retiro? No se puede deshacer.')) return
  borrandoRetiroId.value = r.id
  try {
    await db.eliminarRetiro(r.id)
    if (editandoRetiroId.value === r.id) cancelarRetiro()
    await Promise.all([cargarRetiros(), cargarConvergencia(), cargarControl(), cargarMovimientos()])
  } catch (e) {
    console.error(e)
  } finally {
    borrandoRetiroId.value = null
  }
}

// Exportar presupuesto: arma el documento (oculto) y dispara el diálogo de guardar PDF
// del navegador directo, sin pantalla intermedia. SOLO columnas F–K (nunca costo/ganancia).
const itemsExport = ref([])
const exportando = ref(false)
async function exportar() {
  if (exportando.value) return
  exportando.value = true
  // El navegador usa document.title como nombre sugerido del PDF. Lo seteo al slug
  // de la obra (Ramsay-1945) y lo restauro al volver de imprimir.
  const tituloOriginal = document.title
  try {
    itemsExport.value = await db.getPresupuestoCliente(obraId)
    document.title = obra.value.slug || obra.value.nombre_direccion || 'presupuesto'
    await nextTick()
    window.print()
  } catch (e) {
    console.error(e)
  } finally {
    document.title = tituloOriginal
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
          <NuxtLink :to="'/obras/' + (obra.slug || obra.id) + '/configuracion'" class="btn btn--secondary">Configuración</NuxtLink>
          <button type="button" class="btn btn--primary" @click="exportar">Exportar</button>
        </div>
      </div>
    </header>

    <!-- Bloque de control contable (Excel, hoja Caja). Las 5 líneas deben sumar 0. -->
    <div class="control">
      <div class="control__rows">
        <div class="control__row">
          <span class="control__label">Saldo a cobrar del cliente</span>
          <Skeleton v-if="cargando" width="120px" height="20px" />
          <span v-else class="control__value monto">{{ fmt(control.aCobrar) }}</span>
        </div>
        <div class="control__row">
          <span class="control__label">Saldo en caja</span>
          <Skeleton v-if="cargando" width="120px" height="20px" />
          <span v-else class="control__value monto">{{ fmt(control.saldoCaja) }}</span>
        </div>
        <div class="control__row">
          <span class="control__label">Deuda a proveedores</span>
          <Skeleton v-if="cargando" width="120px" height="20px" />
          <span v-else class="control__value monto">{{ fmt(control.deudaProveedores) }}</span>
        </div>
        <div class="control__row">
          <span class="control__label">Adicionales</span>
          <Skeleton v-if="cargando" width="120px" height="20px" />
          <span v-else class="control__value monto">{{ fmt(control.adicionales) }}</span>
        </div>
        <div class="control__row">
          <span class="control__label">Saldo de honorarios a retirar</span>
          <Skeleton v-if="cargando" width="120px" height="20px" />
          <span v-else class="control__value monto">{{ fmt(control.honorariosRetirar) }}</span>
        </div>
      </div>
      <div class="control__total" :class="cargando ? '' : (controlOk ? 'control__total--ok' : 'control__total--error')">
        <span class="control__label">
          Control
          <span v-if="!cargando && !controlOk" class="control__flag">SI NO ES 0 HAY ERROR</span>
        </span>
        <Skeleton v-if="cargando" width="120px" height="20px" />
        <span v-else class="control__value monto">{{ fmt(control.total) }}</span>
      </div>
    </div>

    <div class="tabs" role="tablist">
      <button v-for="t in tabs" :key="t.id" type="button" class="tab" :class="{ 'tab--active': tab === t.id }" @click="cambiarTab(t.id)">{{ t.label }}</button>
    </div>

    <div v-if="tab === 'caja'" class="tabpanel">
      <section class="panel">
        <div class="panel__head split">
          <span class="eyebrow">Movimientos</span>
          <button class="btn btn--primary btn--sm" @click="cajaFormOpen ? cancelarMov() : abrirAltaMov()">
            <svg width="13" height="13" viewBox="0 0 14 14" fill="none">
              <path v-if="cajaFormOpen" d="M1 7h12" stroke="currentColor" stroke-width="2" stroke-linecap="round" />
              <path v-else d="M7 1v12M1 7h12" stroke="currentColor" stroke-width="2" stroke-linecap="round" />
            </svg>
            {{ cajaFormOpen ? 'Cerrar' : 'Registrar movimiento' }}
          </button>
        </div>

        <form v-if="cajaFormOpen" class="mov-form" @submit.prevent="agregarMovimiento">
          <div class="field-group col-tipo">
            <label class="label">Tipo</label>
            <SelectField v-model="formMov.tipo" :options="opcionesTipo" placeholder="Seleccioná tipo" :invalid="!!errMov.tipo" @change="delete errMov.tipo" />
            <span v-if="errMov.tipo" class="field-error">{{ errMov.tipo }}</span>
          </div>
          <div v-if="esPago" class="field-group col-prov">
            <label class="label">Proveedor</label>
            <SelectField v-model="formMov.proveedorId" :options="opcionesProveedor" placeholder="Seleccioná proveedor" :invalid="!!errMov.proveedor" @change="delete errMov.proveedor" />
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
            <DateField v-model="formMov.fecha" :invalid="!!errMov.fecha" @update:model-value="delete errMov.fecha" />
            <span v-if="errMov.fecha" class="field-error">{{ errMov.fecha }}</span>
          </div>
          <div v-if="enDolares" class="field-group col-medio">
            <label class="label">Valor dólar</label>
            <input v-model="formMov.tcManual" type="number" class="field field--num" :class="{ 'field--error': errMov.tcManual }" placeholder="Ej: 1200" @input="delete errMov.tcManual" />
            <span v-if="errMov.tcManual" class="field-error">{{ errMov.tcManual }}</span>
            <span v-else-if="equivPesos != null" class="field-hint">= {{ fmt(equivPesos) }}</span>
          </div>
          <div v-else class="field-group col-medio">
            <label class="label">Medio de pago</label>
            <SelectField v-model="formMov.medio" :options="opcionesMedio" placeholder="Seleccioná medio" :invalid="!!errMov.medio" @change="delete errMov.medio" />
            <span v-if="errMov.medio" class="field-error">{{ errMov.medio }}</span>
          </div>
          <div class="field-group col-submit">
            <button type="submit" class="btn btn--primary" :disabled="guardandoMov">{{ guardandoMov ? 'Guardando…' : (editandoId ? 'Guardar cambios' : 'Agregar movimiento') }}</button>
          </div>
        </form>

        <p v-if="!movimientos.length" class="estado-msg">Todavía no hay movimientos en esta obra.</p>
        <table v-else class="table table--caja">
          <thead>
            <tr>
              <th>Fecha</th>
              <th>Detalle</th>
              <th class="num">Monto</th>
              <th class="num">Saldo</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="m in movimientos" :key="m.id" :class="{ 'row--editando': editandoId === m.id }">
              <td class="cell-date">{{ fmtFecha(m.fecha) }}</td>
              <td>
                <span class="cell-strong">{{ descMov(m) }}</span>
                <span v-if="m.medio_pago" class="cell-medio">{{ m.medio_pago }}</span>
              </td>
              <td class="num monto" :class="esPositivo(montoFirmado(m)) ? 'monto--pos' : 'monto--neg'">
                <template v-if="esUsd(m)">
                  {{ esPositivo(montoFirmado(m)) ? '+' : '' }}{{ fmtUsd(montoFirmadoOriginal(m)) }}
                  <span class="monto-equiv">{{ fmt(montoFirmado(m)) }}</span>
                </template>
                <template v-else>{{ esPositivo(montoFirmado(m)) ? '+' : '' }}{{ fmt(montoFirmado(m)) }}</template>
              </td>
              <td class="num monto cell-saldo">{{ fmt(m.saldo_acumulado_ars) }}</td>
              <td class="cell-acciones">
                <div class="cell-acciones__inner">
                <button type="button" class="icon-btn" title="Editar" @click="editarMov(m)">
                  <svg width="15" height="15" viewBox="0 0 16 16" fill="none">
                    <path d="M11.5 2.5l2 2L6 12l-2.5.5L4 10l7.5-7.5z" stroke="currentColor" stroke-width="1.3" stroke-linejoin="round" />
                  </svg>
                </button>
                <button type="button" class="icon-btn icon-btn--danger" title="Borrar" :disabled="borrandoId === m.id" @click="borrarMov(m)">
                  <svg width="15" height="15" viewBox="0 0 16 16" fill="none">
                    <path d="M3 4h10M6.5 4V3h3v1M5 4l.5 9h5L11 4" stroke="currentColor" stroke-width="1.3" stroke-linecap="round" stroke-linejoin="round" />
                  </svg>
                </button>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </section>
    </div>

    <div v-else-if="tab === 'presupuesto'" class="tabpanel">
      <section class="panel">
        <div class="panel__head split">
          <span class="eyebrow">Ítems del presupuesto</span>
          <div class="panel__head-actions">
            <div class="toggle-prov">
              <span>Proveedor en PDF</span>
              <button type="button" class="switch" :class="{ 'switch--on': mostrarProveedor }" role="switch" :aria-checked="mostrarProveedor" @click="mostrarProveedor = !mostrarProveedor">
                <span class="switch__knob"></span>
              </button>
            </div>
            <button class="btn btn--primary btn--sm" @click="itemFormOpen ? cancelarItem() : abrirAltaItem()">
              <svg width="13" height="13" viewBox="0 0 14 14" fill="none">
                <path v-if="itemFormOpen" d="M1 7h12" stroke="currentColor" stroke-width="2" stroke-linecap="round" />
                <path v-else d="M7 1v12M1 7h12" stroke="currentColor" stroke-width="2" stroke-linecap="round" />
              </svg>
              {{ itemFormOpen ? 'Cerrar' : 'Agregar ítem' }}
            </button>
          </div>
        </div>

        <form v-if="itemFormOpen" class="item-form" @submit.prevent="agregarItem">
          <!-- Proveedor (autocompleta rubro) + rubro -->
          <div class="item-form__row item-form__row--2">
            <div class="field-group">
              <label class="label">Proveedor <span class="label-opt">(opcional)</span></label>
              <SelectField v-model="formItem.proveedorId" :options="opcionesProveedorOpt" placeholder="Sin asignar" @change="onProveedorItem" />
            </div>
            <div class="field-group">
              <label class="label">Rubro</label>
              <RubroCombo v-model="formItem.rubro" placeholder="Ej: Albañilería" :invalid="!!errItem.rubro" @update:model-value="delete errItem.rubro" />
              <span v-if="errItem.rubro" class="field-error">{{ errItem.rubro }}</span>
            </div>
          </div>

          <!-- Números: la cuenta costo + adicional → valor final -->
          <fieldset class="item-form__money">
            <div class="money-row">
              <div class="field-group">
                <label class="label">Costo del proveedor</label>
                <input v-model="formItem.costo" type="number" class="field field--num" placeholder="0" @input="sugerirFinal" />
              </div>

              <span class="money-op">+</span>

              <div class="field-group">
                <div class="label-row">
                  <label class="label">Adicional</label>
                  <button type="button" class="switch" :class="{ 'switch--on': formItem.adicionalOn }" role="switch" :aria-checked="formItem.adicionalOn" @click="toggleAdicional">
                    <span class="switch__knob"></span>
                  </button>
                </div>
                <input v-model="formItem.adicional" type="number" class="field field--num" :class="{ 'field--off': !formItem.adicionalOn }" placeholder="0" :disabled="!formItem.adicionalOn" @input="sugerirFinal" />
              </div>

              <span class="money-op">=</span>

              <div class="field-group">
                <label class="label">Valor final</label>
                <input v-model="formItem.valor" type="number" class="field field--num" :class="{ 'field--error': errItem.valor }" placeholder="0" @input="onValorInput" />
                <span v-if="errItem.valor" class="field-error">{{ errItem.valor }}</span>
              </div>
            </div>

            <p class="money-note">
              <span><strong>Costo</strong> y <strong>adicional</strong> son internos, nunca salen en el presupuesto del cliente.</span>
              <span>El <strong>valor final</strong> es lo que paga el cliente. Por defecto = costo + adicional ({{ fmt(presupuestoItem) }}).</span>
            </p>
          </fieldset>

          <!-- Detalle + notas -->
          <div class="item-form__row item-form__row--2">
            <div class="field-group">
              <label class="label">Detalle <span class="label-opt">(opcional)</span></label>
              <input v-model="formItem.detalle" type="text" class="field" placeholder="Ej: Demolición y contrapiso" />
            </div>
            <div class="field-group">
              <label class="label">Notas <span class="label-opt">(opcional, interno)</span></label>
              <input v-model="formItem.notas" type="text" class="field" placeholder="Interno" />
            </div>
          </div>

          <div class="item-form__actions">
            <button type="submit" class="btn btn--primary" :disabled="guardandoItem">{{ guardandoItem ? 'Guardando…' : (editandoItemId ? 'Guardar cambios' : 'Agregar ítem') }}</button>
          </div>
        </form>

        <p v-if="!items.length" class="estado-msg">Todavía no hay ítems en el presupuesto.</p>
        <table v-else class="table">
          <thead>
            <tr>
              <th style="width: 150px">Rubro</th>
              <th style="width: 150px">Proveedor</th>
              <th>Detalle</th>
              <th class="num" style="width: 130px">Valor final</th>
              <th class="num" style="width: 140px; white-space: nowrap">Honorario 15%</th>
              <th class="num" style="width: 140px">Total</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="it in itemsOrdenados" :key="it.id" :class="{ 'row--editando': editandoItemId === it.id }">
              <td class="cell-strong">{{ it.rubro?.nombre || '—' }}</td>
              <td class="cell-muted">{{ it.proveedor?.nombre || '—' }}</td>
              <td class="cell-muted">{{ it.detalle || '—' }}</td>
              <td class="num monto">{{ fmt(it.valor_final_ars) }}</td>
              <td class="num monto monto--accent">{{ fmt(it.honorario_ars) }}</td>
              <td class="num monto cell-saldo">{{ fmt(it.total_ars) }}</td>
              <td class="cell-acciones">
                <div class="cell-acciones__inner">
                  <button type="button" class="icon-btn" title="Editar" @click="editarItem(it)">
                    <svg width="15" height="15" viewBox="0 0 16 16" fill="none">
                      <path d="M11.5 2.5l2 2L6 12l-2.5.5L4 10l7.5-7.5z" stroke="currentColor" stroke-width="1.3" stroke-linejoin="round" />
                    </svg>
                  </button>
                  <button type="button" class="icon-btn icon-btn--danger" title="Borrar" :disabled="borrandoItemId === it.id" @click="borrarItem(it)">
                    <svg width="15" height="15" viewBox="0 0 16 16" fill="none">
                      <path d="M3 4h10M6.5 4V3h3v1M5 4l.5 9h5L11 4" stroke="currentColor" stroke-width="1.3" stroke-linecap="round" stroke-linejoin="round" />
                    </svg>
                  </button>
                </div>
              </td>
            </tr>
          </tbody>
          <tfoot>
            <tr>
              <td colspan="3" class="cell-total-label">Total presupuesto</td>
              <td class="num monto cell-total">{{ fmt(totalValorFinal) }}</td>
              <td class="num monto monto--accent">{{ fmt(totalHonorarios) }}</td>
              <td class="num monto cell-total">{{ fmt(totalPresupuesto) }}</td>
              <td></td>
            </tr>
          </tfoot>
        </table>
      </section>
    </div>

    <div v-else-if="tab === 'deuda'" class="tabpanel">
      <section class="panel">
        <div class="panel__head split">
          <span class="eyebrow">Proveedores</span>
          <div class="reparto__stats">
            <span class="reparto__stat">Presupuestado <strong class="monto">{{ fmt(deudaTotal) }}</strong></span>
            <span class="reparto__stat">Pagado <strong class="monto monto--pos">{{ fmt(pagadoTotal) }}</strong></span>
            <span class="reparto__stat">Debo <strong class="monto monto--neg">{{ fmt(deudaTotal - pagadoTotal) }}</strong></span>
          </div>
        </div>

        <p v-if="!deudaPorProveedor.length" class="estado-msg">Todavía no hay proveedores con presupuesto o pagos.</p>
        <table v-else class="table table--deuda">
          <thead>
            <tr>
              <th>Proveedor</th>
              <th class="num">Presupuestado</th>
              <th class="num">Pagado</th>
              <th class="num">Debo</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="p in deudaPorProveedor" :key="p.nombre">
              <td class="cell-strong">{{ p.nombre }}</td>
              <td class="num monto">{{ fmt(p.presupuestado) }}</td>
              <td class="num monto monto--pos">{{ fmt(p.pagado) }}</td>
              <td class="num monto" :class="{ 'debo-exceso': p.debo < 0 }">{{ fmt(p.debo) }}</td>
            </tr>
          </tbody>
          <tfoot>
            <tr>
              <td class="cell-total-label">Total</td>
              <td class="num monto">{{ fmt(deudaTotal) }}</td>
              <td class="num monto monto--pos">{{ fmt(pagadoTotal) }}</td>
              <td class="num monto cell-total">{{ fmt(deudaTotal - pagadoTotal) }}</td>
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
          <button class="btn btn--primary btn--sm" @click="retiroFormOpen ? cancelarRetiro() : abrirAltaRetiro()">
            <svg width="13" height="13" viewBox="0 0 14 14" fill="none">
              <path v-if="retiroFormOpen" d="M1 7h12" stroke="currentColor" stroke-width="2" stroke-linecap="round" />
              <path v-else d="M7 1v12M1 7h12" stroke="currentColor" stroke-width="2" stroke-linecap="round" />
            </svg>
            {{ retiroFormOpen ? 'Cerrar' : 'Registrar retiro' }}
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
            <DateField v-model="formRetiro.fecha" :invalid="!!errRetiro.fecha" @update:model-value="delete errRetiro.fecha" />
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
            <button type="submit" class="btn btn--primary" :disabled="guardandoRetiro">{{ guardandoRetiro ? 'Guardando…' : (editandoRetiroId ? 'Guardar cambios' : 'Registrar retiro') }}</button>
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
              <th></th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="r in retiros" :key="r.id" :class="{ 'row--editando': editandoRetiroId === r.id }">
              <td class="cell-date">{{ fmtFecha(r.fecha) }}</td>
              <td class="num monto">{{ fmt(Number(r.monto_nancy) * Number(r.tipo_cambio)) }}</td>
              <td class="num monto">{{ fmt(Number(r.monto_sol) * Number(r.tipo_cambio)) }}</td>
              <td class="num monto cell-saldo">{{ fmt((Number(r.monto_nancy) + Number(r.monto_sol)) * Number(r.tipo_cambio)) }}</td>
              <td class="cell-acciones">
                <div class="cell-acciones__inner">
                  <button type="button" class="icon-btn" title="Editar" @click="editarRetiro(r)">
                    <svg width="15" height="15" viewBox="0 0 16 16" fill="none">
                      <path d="M11.5 2.5l2 2L6 12l-2.5.5L4 10l7.5-7.5z" stroke="currentColor" stroke-width="1.3" stroke-linejoin="round" />
                    </svg>
                  </button>
                  <button type="button" class="icon-btn icon-btn--danger" title="Borrar" :disabled="borrandoRetiroId === r.id" @click="borrarRetiro(r)">
                    <svg width="15" height="15" viewBox="0 0 16 16" fill="none">
                      <path d="M3 4h10M6.5 4V3h3v1M5 4l.5 9h5L11 4" stroke="currentColor" stroke-width="1.3" stroke-linecap="round" stroke-linejoin="round" />
                    </svg>
                  </button>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </section>
    </div>

    <!-- Documento del presupuesto: oculto en pantalla, solo aparece al imprimir (Exportar) -->
    <div class="solo-print">
      <DocumentoPresupuesto :obra="obra" :items="itemsExport" :mostrar-proveedor="mostrarProveedor" />
    </div>
  </div>
</template>

<style scoped>
/* Documento del presupuesto: oculto en pantalla, el @media print global lo muestra */
.solo-print { display: none; }

/* Bloque de control contable (réplica del Excel): 5 saldos + fila Control que cierra en 0 */
.control {
  margin: 0 0 28px;
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: var(--radius-lg);
  overflow: hidden;
}
.control__rows { display: flex; flex-direction: column; }
.control__row {
  display: flex; justify-content: space-between; align-items: center; gap: 16px;
  border-bottom: 1px solid var(--border-subtle);
  padding: 13px 22px;
}
.control__label { font-size: 15px; color: var(--ink); }
.control__value { font-size: 16px; }
.control__total {
  display: flex; justify-content: space-between; align-items: center; gap: 16px;
  background: var(--accent-subtle);
  padding: 15px 22px;
}
.control__total .control__label { font-weight: 700; text-transform: uppercase; letter-spacing: 0.03em; font-size: 14px; }
.control__total .control__value { font-size: 18px; font-weight: 600; }
.control__total--ok { background: var(--positive-bg); color: var(--positive); }
.control__total--ok .control__value { color: var(--positive); }
.control__total--error { background: var(--negative-bg); color: var(--negative); }
.control__total--error .control__value { color: var(--negative); }
.control__flag {
  margin-left: 10px; font-size: 12px; font-weight: 600; letter-spacing: 0;
  text-transform: none; color: var(--negative);
}

/* Equivalente en pesos debajo del monto en USD (columna Monto) */
.monto-equiv { display: block; font-size: 13px; color: var(--ink-muted); margin-top: 2px; }
/* Equivalente en pesos previsualizado bajo el campo Valor dólar */
.field-hint { font-size: 13px; color: var(--ink-muted); margin-top: 4px; }

/* Acciones por fila (editar / borrar) */
.cell-acciones { width: 1%; white-space: nowrap; text-align: right; }
.cell-acciones__inner { display: inline-flex; gap: 4px; }
.icon-btn {
  display: flex; align-items: center; justify-content: center;
  background: transparent; border: none; color: var(--ink-muted);
  cursor: pointer; transition: color 150ms var(--ease-out); padding: 6px;
}
.icon-btn:hover { color: var(--ink); }
.icon-btn--danger:hover { color: var(--negative); }
.icon-btn:disabled { opacity: 0.4; cursor: default; }
.row--editando { background: var(--accent-subtle); }

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
.panel__head-actions { display: flex; align-items: center; gap: 16px; }
.toggle-prov { display: flex; align-items: center; gap: 8px; font-size: 13px; color: var(--ink-muted); user-select: none; }
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

/* Switch de Adicional (label + toggle en la misma fila) */
.label-row { display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px; }
.label-row .label { margin-bottom: 0; }
.switch {
  width: 40px; height: 22px;
  display: flex; align-items: center;
  position: relative;
  background: var(--border); border: none; border-radius: 11px;
  cursor: pointer; transition: background 150ms var(--ease-out);
  padding: 0;
}
.switch--on { background: var(--accent); }
.switch__knob {
  width: 18px; height: 18px;
  background: var(--surface); border-radius: 50%;
  transition: transform 150ms var(--ease-out);
  transform: translateX(2px);
}
.switch--on .switch__knob { transform: translateX(20px); }

/* Form de ítem de presupuesto */
.item-form {
  display: flex;
  flex-direction: column;
  gap: 18px;
  padding: 18px;
  border-bottom: 1px solid var(--border-subtle);
}
.item-form__row { display: grid; grid-template-columns: 1fr; gap: 16px 20px; }
.item-form__row--2 { grid-template-columns: 1fr 1fr; }

/* Debo negativo = se pagó de más, hay que pedirle al cliente. Resaltado fuerte. */
.debo-exceso { color: var(--negative); font-weight: 700; }

/* La cuenta: costo + adicional = valor final, en una tira con operadores */
.item-form__money {
  display: flex;
  flex-direction: column;
  gap: 12px;
  background: var(--surface-raised);
  border: 1px solid var(--border-subtle);
  border-radius: var(--radius);
  padding: 16px;
  margin: 0;
}
.money-row {
  display: grid;
  grid-template-columns: 1fr auto 1fr auto 1fr;
  align-items: end;
  gap: 12px;
}
.money-op {
  font-family: var(--font-mono);
  font-size: 18px;
  color: var(--ink-faint);
  padding-bottom: 11px;
}
.field--off { color: var(--ink-faint); background: var(--surface-raised); }
.money-note {
  display: flex;
  flex-direction: column;
  gap: 3px;
  font-size: 13px;
  color: var(--ink-muted);
  line-height: 1.4;
}
.money-note strong { color: var(--ink); font-weight: 600; }
.item-form__actions { display: flex; justify-content: flex-end; }

.cell-strong { font-weight: 600; color: var(--ink); }
.cell-muted { color: var(--ink-muted); }
.cell-medio { display: block; font-size: 13px; color: var(--ink-faint); text-transform: capitalize; margin-top: 2px; }
.table tfoot td { padding: 15px 18px; border-top: 1px solid var(--border); background: var(--surface-raised); }
.cell-total-label { font-size: 12px; font-weight: 600; text-transform: uppercase; letter-spacing: 0.05em; color: var(--ink-muted); }
.cell-total { font-weight: 600; font-size: 16px; color: var(--ink); }

@media (max-width: 560px) {
  .mov-form { grid-template-columns: 1fr; }
  .item-form__row--2 { grid-template-columns: 1fr; }
  .money-row { grid-template-columns: 1fr; }
  .money-op { display: none; }
}
</style>
