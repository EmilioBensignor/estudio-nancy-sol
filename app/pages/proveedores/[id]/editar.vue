<script setup>
const route = useRoute()
const id = route.params.id
const { getProveedor, actualizarProveedor, resolverRubroId, contarUsosDeProveedor, eliminarProveedor } = useDb()

const form = reactive({
  nombre: '',
  sobrenombre: '',
  rubro: '',
  telefono: '',
  cuit: '',
})

const cargando = ref(true)
const errorCarga = ref('')
const errors = reactive({})
const guardando = ref(false)
const errorGuardar = ref('')

const modalAbierto = ref(false)
const eliminando = ref(false)
const bloqueo = ref('')
const errorEliminar = ref('')

async function abrirModal() {
  errorEliminar.value = ''
  bloqueo.value = ''
  modalAbierto.value = true
  try {
    const usos = await contarUsosDeProveedor(id)
    if (usos > 0) {
      bloqueo.value = `No se puede eliminar: el proveedor está usado en ${usos} registro${usos === 1 ? '' : 's'} (items o movimientos).`
    }
  } catch (e) {
    bloqueo.value = 'No se pudo verificar si está en uso.'
    console.error(e)
  }
}

onMounted(async () => {
  try {
    const p = await getProveedor(id)
    form.nombre = p.nombre || ''
    form.sobrenombre = p.sobrenombre || ''
    form.rubro = p.rubro?.nombre || ''
    form.telefono = p.telefono || ''
    form.cuit = p.cuit || ''
  } catch (e) {
    errorCarga.value = 'No se pudo cargar el proveedor.'
    console.error(e)
  } finally {
    cargando.value = false
  }
})

async function guardar() {
  Object.keys(errors).forEach((k) => delete errors[k])
  if (!form.nombre.trim()) errors.nombre = 'Ingresá el nombre del proveedor.'
  if (!form.rubro.trim()) errors.rubro = 'Elegí o escribí un rubro.'
  if (Object.keys(errors).length) return

  guardando.value = true
  errorGuardar.value = ''
  try {
    const rubroId = await resolverRubroId(form.rubro)
    await actualizarProveedor(id, {
      nombre: form.nombre.trim(),
      sobrenombre: form.sobrenombre.trim() || null,
      telefono: form.telefono.trim() || null,
      rubro_id: rubroId,
      cuit: form.cuit.trim() || null,
    })
    navigateTo('/proveedores')
  } catch (e) {
    errorGuardar.value = 'No se pudo guardar el proveedor. Reintentá.'
    console.error(e)
    guardando.value = false
  }
}

async function eliminar() {
  if (bloqueo.value) return
  eliminando.value = true
  errorEliminar.value = ''
  try {
    await eliminarProveedor(id)
    navigateTo('/proveedores')
  } catch (e) {
    errorEliminar.value = 'No se pudo eliminar el proveedor. Reintentá.'
    console.error(e)
    eliminando.value = false
    modalAbierto.value = false
  }
}
</script>

<template>
  <div class="shell">
    <header class="page-header">
      <NuxtLink to="/proveedores" class="back">
        <svg width="14" height="14" viewBox="0 0 14 14" fill="none">
          <path d="M9 2L4 7l5 5" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round" />
        </svg>
        Proveedores
      </NuxtLink>
      <div class="page-header__row">
        <div class="page-header__titles">
          <h1 class="title">Editar proveedor</h1>
          <p class="subtitle">Datos de contacto y rubro</p>
        </div>
      </div>
    </header>

    <p v-if="cargando" class="estado-msg">Cargando…</p>
    <p v-else-if="errorCarga" class="estado-msg estado-msg--error">{{ errorCarga }}</p>

    <form v-else class="card form-card" @submit.prevent="guardar">
      <div class="fields">
        <div class="field-group">
          <label class="label">Nombre</label>
          <input v-model="form.nombre" type="text" class="field" :class="{ 'field--error': errors.nombre }" placeholder="Ej: Corralón Loyola" @input="delete errors.nombre" />
          <span v-if="errors.nombre" class="field-error">{{ errors.nombre }}</span>
        </div>

        <div class="field-group">
          <label class="label">Sobrenombre</label>
          <input v-model="form.sobrenombre" type="text" class="field" placeholder="Opcional, cómo lo tienen anotado" />
        </div>

        <div class="field-group">
          <label class="label">Rubro</label>
          <RubroCombo v-model="form.rubro" :invalid="!!errors.rubro" @update:model-value="delete errors.rubro" />
          <span v-if="errors.rubro" class="field-error">{{ errors.rubro }}</span>
          <span v-else class="hint">Elegí de la lista o escribí un rubro nuevo si no existe.</span>
        </div>

        <div class="field-group">
          <label class="label">Teléfono</label>
          <input v-model="form.telefono" type="tel" class="field" placeholder="11 4456 2200" />
        </div>
        <div class="field-group">
          <label class="label">CUIT</label>
          <input v-model="form.cuit" type="text" class="field" placeholder="Opcional" />
        </div>
      </div>

      <span v-if="errorGuardar" class="field-error">{{ errorGuardar }}</span>

      <div class="form-actions">
        <div class="form-actions__left">
          <button type="button" class="btn btn--danger-ghost" @click="abrirModal">Eliminar</button>
        </div>
        <div class="form-actions__right">
          <NuxtLink to="/proveedores" class="btn btn--ghost">Cancelar</NuxtLink>
          <button type="submit" class="btn btn--primary" :disabled="guardando">{{ guardando ? 'Guardando…' : 'Guardar cambios' }}</button>
        </div>
      </div>
      <span v-if="errorEliminar" class="field-error">{{ errorEliminar }}</span>
    </form>

    <ConfirmDialog
      :open="modalAbierto"
      titulo="Eliminar proveedor"
      :mensaje="`¿Seguro que querés eliminar a ${form.nombre}? Esta acción no se puede deshacer.`"
      :bloqueo="bloqueo"
      :procesando="eliminando"
      @confirmar="eliminar"
      @cerrar="modalAbierto = false"
    />
  </div>
</template>

<style scoped>
.form-card { padding: 26px 28px; display: flex; flex-direction: column; gap: 24px; }
.fields { display: grid; grid-template-columns: 1fr 1fr; gap: 18px 20px; }
.form-actions { display: flex; align-items: center; justify-content: space-between; gap: 10px; }
.form-actions__left, .form-actions__right { display: flex; align-items: center; gap: 10px; }
@media (max-width: 600px) { .fields { grid-template-columns: 1fr; } }
</style>
