<script setup>
const route = useRoute()
const id = route.params.id
const { getCliente, actualizarCliente, contarObrasDeCliente, eliminarCliente } = useDb()

const form = reactive({
  nombre: '',
  sobrenombre: '',
  telefono: '',
  email: '',
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
    const obras = await contarObrasDeCliente(id)
    if (obras > 0) {
      bloqueo.value = `No se puede eliminar: el cliente tiene ${obras} obra${obras === 1 ? '' : 's'} asociada${obras === 1 ? '' : 's'}.`
    }
  } catch (e) {
    bloqueo.value = 'No se pudo verificar si tiene obras asociadas.'
    console.error(e)
  }
}

onMounted(async () => {
  try {
    const c = await getCliente(id)
    form.nombre = c.nombre || ''
    form.sobrenombre = c.sobrenombre || ''
    form.telefono = c.telefono || ''
    form.email = c.email || ''
    form.cuit = c.cuit || ''
  } catch (e) {
    errorCarga.value = 'No se pudo cargar el cliente.'
    console.error(e)
  } finally {
    cargando.value = false
  }
})

async function guardar() {
  Object.keys(errors).forEach((k) => delete errors[k])
  if (!form.nombre.trim()) errors.nombre = 'Ingresá el nombre del cliente.'
  if (!form.telefono.trim()) errors.telefono = 'Ingresá un teléfono de contacto.'
  if (Object.keys(errors).length) return

  guardando.value = true
  errorGuardar.value = ''
  try {
    await actualizarCliente(id, {
      nombre: form.nombre.trim(),
      sobrenombre: form.sobrenombre.trim() || null,
      telefono: form.telefono.trim() || null,
      email: form.email.trim() || null,
      cuit: form.cuit.trim() || null,
    })
    navigateTo('/clientes')
  } catch (e) {
    errorGuardar.value = 'No se pudo guardar el cliente. Reintentá.'
    console.error(e)
    guardando.value = false
  }
}

async function eliminar() {
  if (bloqueo.value) return
  eliminando.value = true
  errorEliminar.value = ''
  try {
    await eliminarCliente(id)
    navigateTo('/clientes')
  } catch (e) {
    errorEliminar.value = 'No se pudo eliminar el cliente. Reintentá.'
    console.error(e)
    eliminando.value = false
    modalAbierto.value = false
  }
}
</script>

<template>
  <div class="shell">
    <header class="page-header">
      <NuxtLink to="/clientes" class="back">
        <svg width="14" height="14" viewBox="0 0 14 14" fill="none">
          <path d="M9 2L4 7l5 5" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round" />
        </svg>
        Clientes
      </NuxtLink>
      <div class="page-header__row">
        <div class="page-header__titles">
          <h1 class="title">Editar cliente</h1>
          <p class="subtitle">Datos de contacto</p>
        </div>
      </div>
    </header>

    <p v-if="cargando" class="estado-msg">Cargando…</p>
    <p v-else-if="errorCarga" class="estado-msg estado-msg--error">{{ errorCarga }}</p>

    <form v-else class="card form-card" @submit.prevent="guardar">
      <div class="fields">
        <div class="field-group">
          <label class="label">Nombre completo</label>
          <input v-model="form.nombre" type="text" class="field" :class="{ 'field--error': errors.nombre }" placeholder="Ej: Eli Ramsay" @input="delete errors.nombre" />
          <span v-if="errors.nombre" class="field-error">{{ errors.nombre }}</span>
        </div>
        <div class="field-group">
          <label class="label">Sobrenombre</label>
          <input v-model="form.sobrenombre" type="text" class="field" placeholder="Opcional" />
        </div>

        <div class="field-group">
          <label class="label">Teléfono</label>
          <input v-model="form.telefono" type="tel" class="field" :class="{ 'field--error': errors.telefono }" placeholder="11 5512 8890" @input="delete errors.telefono" />
          <span v-if="errors.telefono" class="field-error">{{ errors.telefono }}</span>
        </div>
        <div class="field-group">
          <label class="label">Email</label>
          <input v-model="form.email" type="email" class="field" placeholder="cliente@email.com" />
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
          <NuxtLink to="/clientes" class="btn btn--ghost">Cancelar</NuxtLink>
          <button type="submit" class="btn btn--primary" :disabled="guardando">{{ guardando ? 'Guardando…' : 'Guardar cambios' }}</button>
        </div>
      </div>
      <span v-if="errorEliminar" class="field-error">{{ errorEliminar }}</span>
    </form>

    <ConfirmDialog
      :open="modalAbierto"
      titulo="Eliminar cliente"
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
