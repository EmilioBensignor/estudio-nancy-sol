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

const busqueda = ref('')
const ordenCol = ref('rubro')
const ordenDir = ref('asc')

function ordenarPor(col) {
  if (ordenCol.value === col) {
    ordenDir.value = ordenDir.value === 'asc' ? 'desc' : 'asc'
  } else {
    ordenCol.value = col
    ordenDir.value = 'asc'
  }
}

function valor(p, col) {
  if (col === 'rubro') return p.rubro?.nombre || ''
  return p[col] || ''
}

const proveedores = computed(() => {
  const q = busqueda.value.trim().toLowerCase()
  const filtrados = q
    ? lista.value.filter((p) =>
        [p.nombre, p.rubro?.nombre, p.telefono, p.cuit].some((v) => (v || '').toLowerCase().includes(q)),
      )
    : [...lista.value]
  const dir = ordenDir.value === 'asc' ? 1 : -1
  return filtrados.sort((a, b) => {
    const cmp = valor(a, ordenCol.value).localeCompare(valor(b, ordenCol.value))
    return (cmp || a.nombre.localeCompare(b.nombre)) * dir
  })
})
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
          <input v-model="busqueda" type="search" class="field prov-search" placeholder="Buscar…" />
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
            <th class="th-sort" @click="ordenarPor('nombre')">Proveedor <span class="sort-arrow" :class="{ 'sort-arrow--active': ordenCol === 'nombre' }">{{ ordenCol === 'nombre' && ordenDir === 'desc' ? '↓' : '↑' }}</span></th>
            <th class="th-sort" @click="ordenarPor('rubro')">Rubro <span class="sort-arrow" :class="{ 'sort-arrow--active': ordenCol === 'rubro' }">{{ ordenCol === 'rubro' && ordenDir === 'desc' ? '↓' : '↑' }}</span></th>
            <th class="th-sort" @click="ordenarPor('telefono')">Teléfono <span class="sort-arrow" :class="{ 'sort-arrow--active': ordenCol === 'telefono' }">{{ ordenCol === 'telefono' && ordenDir === 'desc' ? '↓' : '↑' }}</span></th>
            <th class="th-sort" @click="ordenarPor('cuit')">CUIT <span class="sort-arrow" :class="{ 'sort-arrow--active': ordenCol === 'cuit' }">{{ ordenCol === 'cuit' && ordenDir === 'desc' ? '↓' : '↑' }}</span></th>
            <th class="col-accion"><span class="sr-only">Acciones</span></th>
          </tr>
        </thead>
        <tbody>
          <tr v-if="!proveedores.length"><td colspan="5" class="cell-muted">Sin resultados para “{{ busqueda }}”.</td></tr>
          <tr v-for="p in proveedores" :key="p.id">
            <td class="cell-strong">{{ p.nombre }}</td>
            <td><span v-if="p.rubro" class="rubro-tag">{{ p.rubro.nombre }}</span><span v-else class="cell-muted">—</span></td>
            <td class="cell-muted">{{ p.telefono || '—' }}</td>
            <td class="cell-muted">{{ p.cuit || '—' }}</td>
            <td class="col-accion">
              <NuxtLink :to="`/proveedores/${p.id}/editar`" class="btn-icon" aria-label="Editar proveedor">
                <svg width="15" height="15" viewBox="0 0 16 16" fill="none">
                  <path d="M11.5 2.5l2 2L6 12l-2.5.5L4 10l7.5-7.5z" stroke="currentColor" stroke-width="1.3" stroke-linejoin="round" />
                </svg>
              </NuxtLink>
            </td>
          </tr>
        </tbody>
      </table>
    </section>
  </div>
</template>

<style scoped>
.table--prov { table-layout: fixed; }
.table--prov th:nth-child(1), .table--prov td:nth-child(1) { width: 32%; }
.table--prov th:nth-child(2), .table--prov td:nth-child(2) { width: 24%; }
.table--prov th:nth-child(3), .table--prov td:nth-child(3) { width: 20%; }
.table--prov th:nth-child(4), .table--prov td:nth-child(4) { width: 16%; }
.table--prov th:nth-child(5), .table--prov td:nth-child(5) { width: 8%; }
.col-accion { text-align: right; }

.prov-search {
  width: 240px;
  background-image: url("data:image/svg+xml,%3Csvg width='15' height='15' viewBox='0 0 15 15' fill='none' xmlns='http://www.w3.org/2000/svg'%3E%3Ccircle cx='6.5' cy='6.5' r='5' stroke='%23A8A59D' stroke-width='1.5'/%3E%3Cpath d='M13.5 13.5l-3-3' stroke='%23A8A59D' stroke-width='1.5' stroke-linecap='round'/%3E%3C/svg%3E");
  background-repeat: no-repeat;
  background-position: left 13px center;
  padding-left: 36px;
}
.prov-search::-webkit-search-cancel-button { -webkit-appearance: none; }
.th-sort { cursor: pointer; user-select: none; }
.sort-arrow { color: var(--ink-faint); font-size: 13px; }
.sort-arrow--active { color: var(--accent); }
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
