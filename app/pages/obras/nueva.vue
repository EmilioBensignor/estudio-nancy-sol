<script setup>
const { getClientes, crearObra } = useDb()

const clientes = ref([])

const form = reactive({
  clienteId: '',
  nombre: '',
  fecha: '',
  tcFallback: '',
})

const guardando = ref(false)
const errors = reactive({})
const errorGuardar = ref('')

onMounted(async () => {
  try {
    clientes.value = await getClientes()
  } catch (e) {
    console.error(e)
  }
})

async function crear() {
  Object.keys(errors).forEach((k) => delete errors[k])
  if (!form.clienteId) errors.clienteId = 'Elegí un cliente.'
  if (!form.nombre.trim()) errors.nombre = 'Ingresá el nombre de la obra.'
  if (Object.keys(errors).length) return

  guardando.value = true
  errorGuardar.value = ''
  try {
    await crearObra({
      cliente_id: form.clienteId,
      nombre_direccion: form.nombre.trim(),
      fecha_inicio: form.fecha || null,
      tipo_cambio_fallback: form.tcFallback ? Number(form.tcFallback) : null,
    })
    navigateTo('/')
  } catch (e) {
    errorGuardar.value = 'No se pudo crear la obra. Reintentá.'
    console.error(e)
    guardando.value = false
  }
}
</script>

<template>
  <div class="shell">
    <header class="page-header">
      <NuxtLink to="/" class="back">
        <svg width="14" height="14" viewBox="0 0 14 14" fill="none">
          <path d="M9 2L4 7l5 5" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round" />
        </svg>
        Obras
      </NuxtLink>
      <div class="page-header__row">
        <div class="page-header__titles">
          <h1 class="title">Nueva obra</h1>
          <p class="subtitle">Datos de la obra y el cliente</p>
        </div>
      </div>
    </header>

    <form class="card form-card" @submit.prevent="crear">
      <div class="fields">
        <div class="field-group">
          <label class="label">Cliente</label>
          <select v-model="form.clienteId" class="field" :class="{ 'field--error': errors.clienteId }" @change="delete errors.clienteId">
            <option value="" disabled>Seleccionar cliente</option>
            <option v-for="c in clientes" :key="c.id" :value="c.id">{{ c.nombre }}</option>
          </select>
          <span v-if="errors.clienteId" class="field-error">{{ errors.clienteId }}</span>
        </div>

        <div class="field-group">
          <label class="label">Nombre / dirección de la obra</label>
          <input v-model="form.nombre" type="text" class="field" :class="{ 'field--error': errors.nombre }" placeholder="Ej: López 1234, Pilar" @input="delete errors.nombre" />
          <span v-if="errors.nombre" class="field-error">{{ errors.nombre }}</span>
        </div>

        <div class="field-group">
          <label class="label">Fecha de inicio</label>
          <input v-model="form.fecha" type="date" class="field" />
        </div>

        <div class="field-group">
          <label class="label">Valor del dólar</label>
          <input v-model="form.tcFallback" type="number" step="1" min="0" class="field field--num field--tc" placeholder="1200" />
          <span class="hint">Opcional, se puede cambiar después.</span>
        </div>
      </div>

      <span v-if="errorGuardar" class="field-error">{{ errorGuardar }}</span>

      <div class="form-actions">
        <NuxtLink to="/" class="btn btn--ghost">Cancelar</NuxtLink>
        <button type="submit" class="btn btn--primary" :disabled="guardando">{{ guardando ? 'Creando…' : 'Crear obra' }}</button>
      </div>
    </form>
  </div>
</template>

<style scoped>
.form-card { padding: 26px 28px; display: flex; flex-direction: column; gap: 24px; }
.fields { display: grid; grid-template-columns: 1fr 1fr; gap: 18px 20px; }
.field-group--full { grid-column: 1 / -1; }
.field--tc { text-align: left; }
.form-actions { display: flex; align-items: center; justify-content: flex-end; gap: 10px; }
@media (max-width: 600px) { .fields { grid-template-columns: 1fr; } }
</style>
