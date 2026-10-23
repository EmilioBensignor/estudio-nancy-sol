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
          <h1 class="title">Rubros</h1>
          <p class="subtitle">{{ lista.length }} rubros</p>
        </div>
        <div class="page-header__actions">
          <input v-model="busqueda" type="search" class="field" placeholder="Buscar…" />
        </div>
      </div>
    </header>

    <p v-if="cargando" class="estado-msg">Cargando…</p>
    <p v-else-if="error" class="estado-msg estado-msg--error">{{ error }}</p>

    <section v-else class="panel">
      <table class="table">
        <thead>
          <tr>
            <th>Rubro</th>
            <th class="num">Usos</th>
            <th class="col-accion"><span class="sr-only">Acciones</span></th>
          </tr>
        </thead>
        <tbody>
          <tr v-if="!rubros.length"><td colspan="3" class="cell-muted">Sin resultados para “{{ busqueda }}”.</td></tr>
          <tr v-for="r in rubros" :key="r.id">
            <td>
              <form v-if="editandoId === r.id" class="rubro-edit" @submit.prevent="guardar(r)">
                <input ref="editInput" v-model="nombreEdit" type="text" class="field" @keydown.esc="editandoId = null" />
                <button type="submit" class="btn btn--primary btn--sm" :disabled="guardando">{{ guardando ? 'Guardando…' : 'Guardar' }}</button>
                <button type="button" class="btn btn--ghost btn--sm" @click="editandoId = null">Cancelar</button>
              </form>
              <span v-else class="cell-strong">{{ r.nombre }}</span>
              <span v-if="editandoId === r.id && errorEdit" class="field-error">{{ errorEdit }}</span>
            </td>
            <td class="num cell-muted">{{ r.usos }}</td>
            <td class="col-accion">
              <div class="acciones">
                <button type="button" class="icon-btn" title="Editar" @click="editar(r)">
                  <svg width="15" height="15" viewBox="0 0 16 16" fill="none">
                    <path d="M11.5 2.5l2 2L6 12l-2.5.5L4 10l7.5-7.5z" stroke="currentColor" stroke-width="1.3" stroke-linejoin="round" />
                  </svg>
                </button>
                <button type="button" class="icon-btn icon-btn--danger" title="Borrar" @click="rubroABorrar = r">
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

    <ConfirmDialog
      :open="!!rubroABorrar"
      :titulo="`¿Borrar el rubro ${rubroABorrar?.nombre || ''}?`"
      mensaje="Esta acción no se puede deshacer."
      :bloqueo="rubroABorrar?.usos ? `Lo usan ${rubroABorrar.usos} proveedores o ítems. Cambiales el rubro antes de borrarlo, o editá el nombre.` : ''"
      confirmarTexto="Borrar"
      :procesando="borrando"
      @confirmar="borrar"
      @cerrar="rubroABorrar = null"
    />
  </div>
</template>

<script setup>
// Catálogo de rubros: renombrar y borrar los que no usa nadie.
const { getRubrosConUsos, actualizarRubro, eliminarRubro } = useDb()

const lista = ref([])
const cargando = ref(true)
const error = ref('')
const busqueda = ref('')

const editandoId = ref(null)
const nombreEdit = ref('')
const editInput = ref(null)
const guardando = ref(false)
const errorEdit = ref('')

const rubroABorrar = ref(null)
const borrando = ref(false)

const rubros = computed(() => {
  const q = busqueda.value.trim()
  return q ? lista.value.filter((r) => empiezaCon(r.nombre, q)) : lista.value
})

async function cargar() {
  try {
    lista.value = await getRubrosConUsos()
  } catch (e) {
    error.value = 'No se pudieron cargar los rubros.'
    console.error(e)
  } finally {
    cargando.value = false
  }
}

async function editar(r) {
  editandoId.value = r.id
  nombreEdit.value = r.nombre
  errorEdit.value = ''
  await nextTick()
  editInput.value?.[0]?.focus()
}

async function guardar(r) {
  const nombre = nombreEdit.value.trim()
  if (!nombre) {
    errorEdit.value = 'El nombre no puede quedar vacío.'
    return
  }
  guardando.value = true
  try {
    await actualizarRubro(r.id, nombre)
    r.nombre = nombre
    editandoId.value = null
  } catch (e) {
    // 23505: el nombre es único
    errorEdit.value = e?.code === '23505' ? 'Ya existe un rubro con ese nombre.' : 'No se pudo guardar.'
    console.error(e)
  } finally {
    guardando.value = false
  }
}

async function borrar() {
  borrando.value = true
  try {
    await eliminarRubro(rubroABorrar.value.id)
    lista.value = lista.value.filter((r) => r.id !== rubroABorrar.value.id)
    rubroABorrar.value = null
  } catch (e) {
    console.error(e)
  } finally {
    borrando.value = false
  }
}

onMounted(cargar)
</script>

<style scoped>
.col-accion { width: 90px; text-align: right; }
.acciones { display: flex; justify-content: flex-end; gap: 4px; }
.rubro-edit { display: flex; align-items: center; gap: 8px; }
.rubro-edit .field { max-width: 320px; height: 36px; }
.btn--sm { height: 36px; padding: 0 14px; font-size: 14px; }
.icon-btn {
  display: flex; align-items: center; justify-content: center;
  background: transparent; border: none; color: var(--ink-muted);
  cursor: pointer; padding: 4px 6px;
}
.icon-btn:hover { color: var(--ink); }
.icon-btn--danger:hover { color: var(--negative); }
.cell-strong { font-weight: 600; color: var(--ink); }
.cell-muted { color: var(--ink-muted); }
</style>
