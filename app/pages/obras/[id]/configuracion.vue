<script setup>
const route = useRoute()
const { getObra, actualizarObra, getSettings, contarUsosDeObra, eliminarObra } = useDb()

const obraId = route.params.id
const obra = ref({ id: obraId, nombre_direccion: '' })
const cargando = ref(true)

const form = reactive({
  nombre: '',
  estado: 'activa',
  honorario: '15',
  splitNancy: '50',
  splitSol: '50',
})

const opcionesEstado = [
  { value: 'activa', label: 'Activa' },
  { value: 'finalizada', label: 'Finalizada' },
]

const errors = reactive({})
const guardando = ref(false)
const errorGuardar = ref('')

// Convierte fracción (0.15) a porcentaje visible (15). Null = usa el default.
function aPct(frac, def) {
  if (frac == null) return def
  return String(Math.round(Number(frac) * 100))
}

onMounted(async () => {
  try {
    const [o, settings] = await Promise.all([getObra(obraId), getSettings()])
    obra.value = o
    form.nombre = o.nombre_direccion
    form.estado = o.estado
    // Si la obra tiene override usa ese, sino muestra el default de settings
    form.honorario = aPct(o.honorario_override, aPct(settings?.honorario_default, '15'))
    form.splitNancy = aPct(o.split_nancy_override, aPct(settings?.target_reparto_nancy, '50'))
    form.splitSol = aPct(o.split_sol_override, aPct(settings?.target_reparto_sol, '50'))
  } catch (e) {
    console.error(e)
  } finally {
    cargando.value = false
  }
})

const modalAbierto = ref(false)
const eliminando = ref(false)
const bloqueo = ref('')
const errorEliminar = ref('')

async function abrirModal() {
  errorEliminar.value = ''
  bloqueo.value = ''
  modalAbierto.value = true
  try {
    const usos = await contarUsosDeObra(obra.value.id)
    if (usos > 0) {
      bloqueo.value = `No se puede eliminar: la obra tiene ${usos} registro${usos === 1 ? '' : 's'} cargado${usos === 1 ? '' : 's'} (caja, presupuesto o retiros).`
    }
  } catch (e) {
    bloqueo.value = 'No se pudo verificar si la obra tiene movimientos.'
    console.error(e)
  }
}

async function eliminar() {
  if (bloqueo.value) return
  eliminando.value = true
  errorEliminar.value = ''
  try {
    await eliminarObra(obra.value.id)
    navigateTo('/')
  } catch (e) {
    errorEliminar.value = 'No se pudo eliminar la obra. Reintentá.'
    console.error(e)
    eliminando.value = false
    modalAbierto.value = false
  }
}

async function guardar() {
  Object.keys(errors).forEach((k) => delete errors[k])
  if (!form.nombre.trim()) errors.nombre = 'Ingresá el nombre de la obra.'
  const suma = Number(form.splitNancy) + Number(form.splitSol)
  if (suma !== 100) errors.split = 'El reparto entre Nancy y Solana debe sumar 100%.'
  if (Object.keys(errors).length) return

  guardando.value = true
  errorGuardar.value = ''
  try {
    await actualizarObra(obra.value.id, {
      nombre_direccion: form.nombre.trim(),
      estado: form.estado,
      honorario_override: form.honorario ? Number(form.honorario) / 100 : null,
      split_nancy_override: form.splitNancy ? Number(form.splitNancy) / 100 : null,
      split_sol_override: form.splitSol ? Number(form.splitSol) / 100 : null,
    })
    navigateTo(`/obras/${obra.value.slug || obra.value.id}`)
  } catch (e) {
    errorGuardar.value = 'No se pudieron guardar los cambios. Reintentá.'
    console.error(e)
    guardando.value = false
  }
}
</script>

<template>
  <div class="shell">
    <header class="page-header">
      <NuxtLink :to="`/obras/${obra.slug || obra.id}`" class="back">
        <svg width="14" height="14" viewBox="0 0 14 14" fill="none">
          <path d="M9 2L4 7l5 5" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round" />
        </svg>
        {{ obra.nombre_direccion }}
      </NuxtLink>
      <div class="page-header__row">
        <div class="page-header__titles">
          <h1 class="title">Configuración de la obra</h1>
          <p class="subtitle">Parámetros de cálculo y estado</p>
        </div>
      </div>
    </header>

    <form class="card form-card" @submit.prevent="guardar">
      <!-- Datos -->
      <section class="group">
        <div class="group__head">
          <h2 class="group__title">Datos de la obra</h2>
          <p class="group__sub">Nombre y estado actual</p>
        </div>
        <div class="fields">
          <div class="field-group">
            <label class="label">Nombre de la obra</label>
            <input v-model="form.nombre" type="text" class="field" :class="{ 'field--error': errors.nombre }" @input="delete errors.nombre" />
            <span v-if="errors.nombre" class="field-error">{{ errors.nombre }}</span>
          </div>
          <div class="field-group">
            <label class="label">Estado</label>
            <SelectField v-model="form.estado" :options="opcionesEstado" />
          </div>
        </div>
      </section>

      <div class="divider"></div>

      <!-- Cálculo -->
      <section class="group">
        <div class="group__head">
          <h2 class="group__title">Cálculo</h2>
          <p class="group__sub">Honorario de esta obra</p>
        </div>
        <div class="fields">
          <div class="field-group">
            <label class="label">Honorario (%)</label>
            <input v-model="form.honorario" type="number" step="1" class="field field--num" />
            <span class="hint">Por defecto 15%. Aplica a toda la obra.</span>
          </div>
        </div>
      </section>

      <div class="divider"></div>

      <!-- Reparto -->
      <section class="group">
        <div class="group__head">
          <h2 class="group__title">Reparto entre socias</h2>
          <p class="group__sub">El acumulado de retiros converge a este reparto</p>
        </div>
        <div class="fields">
          <div class="field-group">
            <label class="label">Nancy (%)</label>
            <input v-model="form.splitNancy" type="number" step="1" class="field field--num" :class="{ 'field--error': errors.split }" @input="delete errors.split" />
          </div>
          <div class="field-group">
            <label class="label">Solana (%)</label>
            <input v-model="form.splitSol" type="number" step="1" class="field field--num" :class="{ 'field--error': errors.split }" @input="delete errors.split" />
          </div>
          <span v-if="errors.split" class="field-error field-error--full">{{ errors.split }}</span>
        </div>
      </section>

      <span v-if="errorGuardar" class="field-error field-error--full">{{ errorGuardar }}</span>

      <div class="form-actions">
        <button type="button" class="btn btn--danger-ghost" @click="abrirModal">Eliminar obra</button>
        <div class="form-actions__right">
          <NuxtLink :to="`/obras/${obra.slug || obra.id}`" class="btn btn--ghost">Cancelar</NuxtLink>
          <button type="submit" class="btn btn--primary" :disabled="guardando">{{ guardando ? 'Guardando…' : 'Guardar cambios' }}</button>
        </div>
      </div>
      <span v-if="errorEliminar" class="field-error field-error--full">{{ errorEliminar }}</span>
    </form>

    <ConfirmDialog
      :open="modalAbierto"
      titulo="Eliminar obra"
      :mensaje="`¿Seguro que querés eliminar “${form.nombre}”? Esta acción no se puede deshacer.`"
      :bloqueo="bloqueo"
      :procesando="eliminando"
      @confirmar="eliminar"
      @cerrar="modalAbierto = false"
    />
  </div>
</template>

<style scoped>
.form-card { padding: 26px 28px; display: flex; flex-direction: column; gap: 24px; }
.group__head { margin-bottom: 16px; }
.group__title { font-size: 17px; font-weight: 600; letter-spacing: -0.2px; color: var(--ink); }
.group__sub { font-size: 14px; color: var(--ink-muted); margin-top: 3px; }
.fields { display: grid; grid-template-columns: 1fr 1fr; gap: 18px 20px; align-items: start; }
.field-error--full { grid-column: 1 / -1; margin-top: -8px; }
.form-actions { display: flex; align-items: center; justify-content: space-between; gap: 10px; }
.form-actions__right { display: flex; align-items: center; gap: 10px; }
@media (max-width: 600px) { .fields { grid-template-columns: 1fr; } }
</style>
