<script setup>
// Lista de clientes (hoja Data del Excel) + sus obras asociadas.
const { getClientes } = useDb()

const clientes = ref([])
const cargando = ref(true)
const error = ref('')

onMounted(async () => {
  try {
    clientes.value = await getClientes()
  } catch (e) {
    error.value = 'No se pudieron cargar los clientes.'
    console.error(e)
  } finally {
    cargando.value = false
  }
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
            <th>Nombre</th>
            <th>Teléfono</th>
            <th>Email</th>
            <th>CUIT</th>
            <th>Obras</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="c in clientes" :key="c.id">
            <td class="cell-strong">{{ c.nombre }}</td>
            <td class="cell-muted">{{ c.telefono || '—' }}</td>
            <td class="cell-muted">{{ c.email || '—' }}</td>
            <td class="cell-muted">{{ c.cuit || '—' }}</td>
            <td>
              <span v-if="!c.obras?.length" class="cell-muted">—</span>
              <span v-else class="obra-links">
                <NuxtLink v-for="o in c.obras" :key="o.id" :to="`/obras/${o.id}`" class="obra-link">
                  {{ o.nombre_direccion }}
                  <svg width="11" height="11" viewBox="0 0 12 12" fill="none">
                    <path d="M3 9l6-6M9 3H4M9 3v5" stroke="currentColor" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round" />
                  </svg>
                </NuxtLink>
              </span>
            </td>
          </tr>
        </tbody>
      </table>
    </section>
  </div>
</template>

<style scoped>
.cell-strong { font-weight: 600; color: var(--ink); }
.cell-muted { color: var(--ink-muted); }
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
