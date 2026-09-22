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
          <SelectField v-model="form.clienteId" :options="opcionesCliente" placeholder="Seleccionar cliente" :invalid="!!errors.clienteId" @change="delete errors.clienteId" />
          <span v-if="errors.clienteId" class="field-error">{{ errors.clienteId }}</span>
        </div>

        <div class="field-group">
          <label class="label">Nombre / dirección de la obra</label>
          <input v-model="form.nombre" type="text" class="field" :class="{ 'field--error': errors.nombre }" placeholder="Ej: López 1234, Pilar" @input="delete errors.nombre" />
          <span v-if="errors.nombre" class="field-error">{{ errors.nombre }}</span>
        </div>

        <div class="field-group">
          <label class="label">Fecha de inicio <span class="label-opt">(opcional)</span></label>
          <DateField v-model="form.fecha" />
        </div>

        <div class="field-group field-group--full">
          <label class="label">Quién retira</label>
          <div class="socias">
            <div v-for="s in SOCIAS" :key="s.key" class="socia">
              <span>{{ s.nombre }}</span>
              <button type="button" class="switch" :class="{ 'switch--on': form.retira[s.key] }" role="switch" :aria-checked="form.retira[s.key]" @click="form.retira[s.key] = !form.retira[s.key]; delete errors.retira">
                <span class="switch__knob"></span>
              </button>
            </div>
          </div>
          <span v-if="errors.retira" class="field-error">{{ errors.retira }}</span>
          <span v-else class="hint">El reparto arranca parejo entre las que retiran. Se ajusta en Configuración.</span>
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

<script setup>
import { SOCIAS, repartoParejo } from '~/composables/useSocias'

const { getClientes, crearObra } = useDb()

const clientes = ref([])
const opcionesCliente = computed(() => clientes.value.map((c) => ({ value: c.id, label: c.nombre })))

const form = reactive({
  clienteId: '',
  nombre: '',
  fecha: '',
  retira: { nancy: true, sol: true, jessica: false },
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
  const activas = SOCIAS.filter((s) => form.retira[s.key]).map((s) => s.key)
  if (!activas.length) errors.retira = 'Tiene que retirar al menos una persona.'
  if (Object.keys(errors).length) return

  guardando.value = true
  errorGuardar.value = ''
  try {
    const reparto = repartoParejo(activas)
    const socias = Object.fromEntries(
      SOCIAS.flatMap((s) => [
        [`retira_${s.key}`, form.retira[s.key]],
        [`split_${s.key}_override`, Number(reparto[s.key] || 0) / 100],
      ]),
    )
    await crearObra({
      cliente_id: form.clienteId,
      nombre_direccion: form.nombre.trim(),
      fecha_inicio: form.fecha || null,
      ...socias,
    })
    navigateTo('/')
  } catch (e) {
    errorGuardar.value = 'No se pudo crear la obra. Reintentá.'
    console.error(e)
    guardando.value = false
  }
}
</script>

<style scoped>
.form-card { padding: 26px 28px; display: flex; flex-direction: column; gap: 24px; }
.fields { display: grid; grid-template-columns: 1fr 1fr; gap: 18px 20px; }
.field-group--full { grid-column: 1 / -1; }
.socias { display: flex; flex-wrap: wrap; gap: 12px 28px; margin-bottom: 6px; }
.socia { display: flex; align-items: center; gap: 10px; font-size: 16px; color: var(--ink); }
.form-actions { display: flex; align-items: center; justify-content: flex-end; gap: 10px; }
@media (max-width: 600px) { .fields { grid-template-columns: 1fr; } }
</style>
