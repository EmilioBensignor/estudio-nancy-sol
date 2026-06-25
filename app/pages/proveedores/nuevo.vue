<script setup>
const { crearProveedor, resolverRubroId } = useDb()

const form = reactive({
  nombre: '',
  sobrenombre: '',
  rubro: '',
  telefono: '',
  cuit: '',
})

const errors = reactive({})
const guardando = ref(false)
const errorGuardar = ref('')

async function crear() {
  Object.keys(errors).forEach((k) => delete errors[k])
  if (!form.nombre.trim()) errors.nombre = 'Ingresá el nombre del proveedor.'
  if (!form.rubro.trim()) errors.rubro = 'Elegí o escribí un rubro.'
  if (Object.keys(errors).length) return

  guardando.value = true
  errorGuardar.value = ''
  try {
    // El rubro viene como texto; lo resolvemos a id (lo crea si no existe — D2 "al vuelo")
    const rubroId = await resolverRubroId(form.rubro)
    await crearProveedor({
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
          <h1 class="title">Nuevo proveedor</h1>
          <p class="subtitle">Datos de contacto y rubro</p>
        </div>
      </div>
    </header>

    <form class="card form-card" @submit.prevent="crear">
      <div class="fields">
        <div class="field-group">
          <label class="label">Nombre</label>
          <input v-model="form.nombre" type="text" class="field" :class="{ 'field--error': errors.nombre }" placeholder="Ej: Corralón Loyola" @input="delete errors.nombre" />
          <span v-if="errors.nombre" class="field-error">{{ errors.nombre }}</span>
        </div>

        <div class="field-group">
          <label class="label">Sobrenombre <span class="label-opt">(opcional)</span></label>
          <input v-model="form.sobrenombre" type="text" class="field" placeholder="Cómo lo tienen anotado" />
        </div>

        <div class="field-group">
          <label class="label">Rubro</label>
          <RubroCombo v-model="form.rubro" :invalid="!!errors.rubro" @update:model-value="delete errors.rubro" />
          <span v-if="errors.rubro" class="field-error">{{ errors.rubro }}</span>
          <span v-else class="hint">Elegí de la lista o escribí un rubro nuevo si no existe.</span>
        </div>

        <div class="field-group">
          <label class="label">Teléfono <span class="label-opt">(opcional)</span></label>
          <input v-model="form.telefono" type="tel" class="field" placeholder="11 4456 2200" />
        </div>
        <div class="field-group">
          <label class="label">CUIT <span class="label-opt">(opcional)</span></label>
          <input v-model="form.cuit" type="text" class="field" placeholder="20-12345678-9" />
        </div>
      </div>

      <span v-if="errorGuardar" class="field-error">{{ errorGuardar }}</span>

      <div class="form-actions">
        <NuxtLink to="/proveedores" class="btn btn--ghost">Cancelar</NuxtLink>
        <button type="submit" class="btn btn--primary" :disabled="guardando">{{ guardando ? 'Guardando…' : 'Crear proveedor' }}</button>
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
