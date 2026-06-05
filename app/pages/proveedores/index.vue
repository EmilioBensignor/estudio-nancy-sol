<script setup>
// Proveedores por rubro (hoja Data del Excel). Leídos de la DB.
const { getProveedores } = useDb()

const lista = ref([])
const cargando = ref(true)
const error = ref('')

onMounted(async () => {
  try {
    lista.value = await getProveedores()
  } catch (e) {
    error.value = 'No se pudieron cargar los proveedores.'
    console.error(e)
  } finally {
    cargando.value = false
  }
})

// Orden alfabético por rubro, después por nombre
const proveedores = computed(() =>
  [...lista.value].sort(
    (a, b) => (a.rubro?.nombre || '').localeCompare(b.rubro?.nombre || '') || a.nombre.localeCompare(b.nombre),
  ),
)
const rubrosCount = computed(() => new Set(lista.value.map((p) => p.rubro?.nombre).filter(Boolean)).size)
</script>

<template>
  <div class="shell">
    <header class="page-header">
      <div class="page-header__row">
        <div class="page-header__titles">
          <h1 class="title">Proveedores</h1>
          <p class="subtitle">{{ proveedores.length }} proveedores en {{ rubrosCount }} rubros</p>
        </div>
        <div class="page-header__actions">
          <button class="btn btn--primary" @click="navigateTo('/proveedores/nuevo')">
            <svg width="14" height="14" viewBox="0 0 14 14" fill="none">
              <path d="M7 1v12M1 7h12" stroke="currentColor" stroke-width="2" stroke-linecap="round" />
            </svg>
            Nuevo proveedor
          </button>
        </div>
      </div>
    </header>

    <section v-if="cargando" class="panel">
      <table class="table table--prov">
        <thead>
          <tr><th>Proveedor</th><th>Rubro</th><th>Teléfono</th><th>CUIT</th></tr>
        </thead>
        <tbody>
          <tr v-for="n in 5" :key="n">
            <td><Skeleton width="55%" /></td>
            <td><Skeleton width="50%" height="22px" radius="99px" /></td>
            <td><Skeleton width="60%" /></td>
            <td><Skeleton width="55%" /></td>
          </tr>
        </tbody>
      </table>
    </section>
    <p v-else-if="error" class="estado-msg estado-msg--error">{{ error }}</p>
    <p v-else-if="!proveedores.length" class="estado-msg">Todavía no hay proveedores. Agregá el primero.</p>

    <section v-else class="panel">
      <table class="table table--prov">
        <thead>
          <tr>
            <th>Proveedor</th>
            <th>Rubro</th>
            <th>Teléfono</th>
            <th>CUIT</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="p in proveedores" :key="p.id">
            <td class="cell-strong">{{ p.nombre }}</td>
            <td><span v-if="p.rubro" class="rubro-tag">{{ p.rubro.nombre }}</span><span v-else class="cell-muted">—</span></td>
            <td class="cell-muted">{{ p.telefono || '—' }}</td>
            <td class="cell-muted">{{ p.cuit || '—' }}</td>
          </tr>
        </tbody>
      </table>
    </section>
  </div>
</template>

<style scoped>
.table--prov { table-layout: fixed; }
.table--prov th:nth-child(1), .table--prov td:nth-child(1) { width: 34%; }
.table--prov th:nth-child(2), .table--prov td:nth-child(2) { width: 26%; }
.table--prov th:nth-child(3), .table--prov td:nth-child(3) { width: 22%; }
.table--prov th:nth-child(4), .table--prov td:nth-child(4) { width: 18%; }

.cell-strong { font-weight: 600; color: var(--ink); white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.cell-muted { color: var(--ink-muted); white-space: nowrap; }

/* Rubro como etiqueta neutra: identifica el sector sin gritar */
.rubro-tag {
  display: inline-flex;
  align-items: center;
  font-size: 14px;
  font-weight: 500;
  color: var(--ink-muted);
  background: var(--surface-raised);
  border: 1px solid var(--border-subtle);
  padding: 3px 11px;
  border-radius: 99px;
  white-space: nowrap;
}
</style>
