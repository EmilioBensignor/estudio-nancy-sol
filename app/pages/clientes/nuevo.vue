<script setup>
const { crearCliente } = useDb()

const form = reactive({
  nombre: '',
  sobrenombre: '',
  telefono: '',
  email: '',
  cuit: '',
})

const errors = reactive({})
const guardando = ref(false)
const errorGuardar = ref('')

async function crear() {
  Object.keys(errors).forEach((k) => delete errors[k])
  if (!form.nombre.trim()) errors.nombre = 'Ingresá el nombre del cliente.'
  if (!form.telefono.trim()) errors.telefono = 'Ingresá un teléfono de contacto.'
  if (Object.keys(errors).length) return

  guardando.value = true
  errorGuardar.value = ''
  try {
    await crearCliente({
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
          <h1 class="title">Nuevo cliente</h1>
          <p class="subtitle">Datos de contacto</p>
        </div>
      </div>
    </header>

    <form class="card form-card" @submit.prevent="crear">
      <div class="fields">
        <div class="field-group">
          <label class="label">Nombre completo</label>
          <input v-model="form.nombre" type="text" class="field" :class="{ 'field--error': errors.nombre }" placeholder="Ej: Eli Ramsay" @input="delete errors.nombre" />
          <span v-if="errors.nombre" class="field-error">{{ errors.nombre }}</span>
        </div>
        <div class="field-group">
          <label class="label">Sobrenombre <span class="label-opt">(opcional)</span></label>
          <input v-model="form.sobrenombre" type="text" class="field" placeholder="Cómo lo tienen anotado" />
        </div>

        <div class="field-group">
          <label class="label">Teléfono</label>
          <input v-model="form.telefono" type="tel" class="field" :class="{ 'field--error': errors.telefono }" placeholder="11 5512 8890" @input="delete errors.telefono" />
          <span v-if="errors.telefono" class="field-error">{{ errors.telefono }}</span>
        </div>
        <div class="field-group">
          <label class="label">Email <span class="label-opt">(opcional)</span></label>
          <input v-model="form.email" type="email" class="field" placeholder="cliente@email.com" />
        </div>

        <div class="field-group">
          <label class="label">CUIT <span class="label-opt">(opcional)</span></label>
          <input v-model="form.cuit" type="text" class="field" placeholder="20-12345678-9" />
        </div>
      </div>

      <span v-if="errorGuardar" class="field-error">{{ errorGuardar }}</span>

      <div class="form-actions">
        <NuxtLink to="/clientes" class="btn btn--ghost">Cancelar</NuxtLink>
        <button type="submit" class="btn btn--primary" :disabled="guardando">{{ guardando ? 'Guardando…' : 'Crear cliente' }}</button>
      </div>
    </form>
  </div>
</template>

<style scoped>
.form-card { padding: 26px 28px; display: flex; flex-direction: column; gap: 24px; }
.fields { display: grid; grid-template-columns: 1fr 1fr; gap: 18px 20px; }
.field--num { text-align: left; }
.form-actions { display: flex; align-items: center; justify-content: flex-end; gap: 10px; }
@media (max-width: 600px) { .fields { grid-template-columns: 1fr; } }
</style>
