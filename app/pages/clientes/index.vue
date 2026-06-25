<script setup>
// Lista de clientes (hoja Data del Excel) + sus obras asociadas.
const { getClientes } = useDb()

const lista = ref([])
const cargando = ref(true)
const error = ref('')

onMounted(async () => {
  try {
    lista.value = await getClientes()
  } catch (e) {
    error.value = 'No se pudieron cargar los clientes.'
    console.error(e)
  } finally {
    cargando.value = false
  }
})

const busqueda = ref('')
const ordenCol = ref('nombre')
const ordenDir = ref('asc')

function ordenarPor(col) {
  if (ordenCol.value === col) {
    ordenDir.value = ordenDir.value === 'asc' ? 'desc' : 'asc'
  } else {
    ordenCol.value = col
    ordenDir.value = 'asc'
  }
}

const clientes = computed(() => {
  const q = busqueda.value.trim().toLowerCase()
  const filtrados = q
    ? lista.value.filter((c) =>
        [c.nombre, c.telefono, c.email, c.cuit].some((v) => (v || '').toLowerCase().includes(q)),
      )
    : [...lista.value]
  const dir = ordenDir.value === 'asc' ? 1 : -1
  return filtrados.sort((a, b) => {
    const cmp = (a[ordenCol.value] || '').localeCompare(b[ordenCol.value] || '')
    return (cmp || a.nombre.localeCompare(b.nombre)) * dir
  })
})
</script>

<template>
  <div class="shell">
    <header class="page-header">
      <div class="page-header__row">
        <div class="page-header__titles">
          <h1 class="title">Clientes</h1>
          <p class="subtitle">{{ clientes.length }} clientes registrados</p>
        </div>
        <div class="page-header__actions">
          <input v-model="busqueda" type="search" class="field prov-search" placeholder="Buscar…" />
          <button class="btn btn--primary" @click="navigateTo('/clientes/nuevo')">
            <svg width="14" height="14" viewBox="0 0 14 14" fill="none">
              <path d="M7 1v12M1 7h12" stroke="currentColor" stroke-width="2" stroke-linecap="round" />
            </svg>
            Nuevo cliente
          </button>
        </div>
      </div>
    </header>

    <section v-if="cargando" class="panel">
      <table class="table">
        <thead>
          <tr><th>Nombre</th><th>Teléfono</th><th>Email</th><th>CUIT</th><th>Obras</th></tr>
        </thead>
        <tbody>
          <tr v-for="n in 4" :key="n">
            <td><Skeleton width="55%" /></td>
            <td><Skeleton width="65%" /></td>
            <td><Skeleton width="70%" /></td>
            <td><Skeleton width="50%" /></td>
            <td><Skeleton width="45%" /></td>
          </tr>
        </tbody>
      </table>
    </section>
    <p v-else-if="error" class="estado-msg estado-msg--error">{{ error }}</p>
    <p v-else-if="!clientes.length" class="estado-msg">Todavía no hay clientes. Agregá el primero.</p>

    <section v-else class="panel">
      <table class="table">
        <thead>
          <tr>
            <th class="th-sort" @click="ordenarPor('nombre')">Nombre <span class="sort-arrow" :class="{ 'sort-arrow--active': ordenCol === 'nombre' }">{{ ordenCol === 'nombre' && ordenDir === 'desc' ? '↓' : '↑' }}</span></th>
            <th class="th-sort" @click="ordenarPor('telefono')">Teléfono <span class="sort-arrow" :class="{ 'sort-arrow--active': ordenCol === 'telefono' }">{{ ordenCol === 'telefono' && ordenDir === 'desc' ? '↓' : '↑' }}</span></th>
            <th class="th-sort" @click="ordenarPor('email')">Email <span class="sort-arrow" :class="{ 'sort-arrow--active': ordenCol === 'email' }">{{ ordenCol === 'email' && ordenDir === 'desc' ? '↓' : '↑' }}</span></th>
            <th class="th-sort" @click="ordenarPor('cuit')">CUIT <span class="sort-arrow" :class="{ 'sort-arrow--active': ordenCol === 'cuit' }">{{ ordenCol === 'cuit' && ordenDir === 'desc' ? '↓' : '↑' }}</span></th>
            <th>Obras</th>
            <th class="col-accion"><span class="sr-only">Acciones</span></th>
          </tr>
        </thead>
        <tbody>
          <tr v-if="!clientes.length"><td colspan="6" class="cell-muted">Sin resultados para “{{ busqueda }}”.</td></tr>
          <tr v-for="c in clientes" :key="c.id">
            <td class="cell-strong">{{ c.nombre }}</td>
            <td class="cell-muted">{{ c.telefono || '—' }}</td>
            <td class="cell-muted">{{ c.email || '—' }}</td>
            <td class="cell-muted">{{ c.cuit || '—' }}</td>
            <td>
              <span v-if="!c.obras?.length" class="cell-muted">—</span>
              <span v-else class="obra-links">
                <NuxtLink v-for="o in c.obras" :key="o.id" :to="`/obras/${o.slug || o.id}`" class="obra-link">
                  {{ o.nombre_direccion }}
                  <svg width="11" height="11" viewBox="0 0 12 12" fill="none">
                    <path d="M3 9l6-6M9 3H4M9 3v5" stroke="currentColor" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round" />
                  </svg>
                </NuxtLink>
              </span>
            </td>
            <td class="col-accion">
              <NuxtLink :to="`/clientes/${c.id}/editar`" class="btn-icon" aria-label="Editar cliente">
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
.cell-strong { font-weight: 600; color: var(--ink); }
.cell-muted { color: var(--ink-muted); }
.col-accion { width: 50px; text-align: right; }
.obra-links { display: inline-flex; flex-wrap: wrap; gap: 4px 14px; }
.obra-link {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  font-size: 16px;
  font-weight: 500;
  color: var(--accent);
  text-decoration: none;
  transition: color 150ms var(--ease-out);
}
.obra-link:hover { color: var(--accent-hover); }
</style>
