<script setup>
import { fmtArs as fmt } from '~/composables/useFormato'

const route = useRoute()
const id = route.params.id
const { getProveedor, getDeudaProveedorPorObra } = useDb()

const proveedor = ref(null)
const obras = ref([])
const cargando = ref(true)
const errorCarga = ref('')

const totalPresupuestado = computed(() => obras.value.reduce((a, o) => a + o.presupuestado, 0))
const totalPagado = computed(() => obras.value.reduce((a, o) => a + o.pagado, 0))
const totalDebo = computed(() => totalPresupuestado.value - totalPagado.value)

onMounted(async () => {
  try {
    const [p, deuda] = await Promise.all([getProveedor(id), getDeudaProveedorPorObra(id)])
    proveedor.value = p
    obras.value = deuda
  } catch (e) {
    errorCarga.value = 'No se pudo cargar el proveedor.'
    console.error(e)
  } finally {
    cargando.value = false
  }
})
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
          <h1 class="title">{{ proveedor?.nombre || 'Proveedor' }}</h1>
          <p v-if="proveedor?.rubro" class="subtitle">{{ proveedor.rubro.nombre }}</p>
        </div>
        <div class="page-header__actions">
          <NuxtLink :to="`/proveedores/${id}/editar`" class="btn btn--secondary">Editar</NuxtLink>
        </div>
      </div>
    </header>

    <p v-if="cargando" class="estado-msg">Cargando…</p>
    <p v-else-if="errorCarga" class="estado-msg estado-msg--error">{{ errorCarga }}</p>

    <section v-else class="card">
      <div class="card__head">
        <span class="eyebrow">Deuda por obra</span>
        <span class="card__resumen">
          Debo total <strong class="monto monto--neg">{{ fmt(totalDebo) }}</strong>
        </span>
      </div>

      <p v-if="!obras.length" class="estado-msg">Este proveedor no participa en ninguna obra todavía.</p>
      <table v-else class="table">
        <thead>
          <tr>
            <th>Obra</th>
            <th class="num">Presupuestado</th>
            <th class="num">Pagado</th>
            <th class="num">Debo</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="o in obras" :key="o.obraId">
            <td class="cell-strong">
              <NuxtLink :to="`/obras/${o.obra?.slug || o.obraId}`" class="link-obra">{{ o.obra?.nombre_direccion || '—' }}</NuxtLink>
            </td>
            <td class="num monto">{{ fmt(o.presupuestado) }}</td>
            <td class="num monto monto--pos">{{ fmt(o.pagado) }}</td>
            <td class="num monto" :class="{ 'debo-exceso': o.debo < 0 }">{{ fmt(o.debo) }}</td>
          </tr>
        </tbody>
        <tfoot>
          <tr>
            <td class="cell-total-label">Total</td>
            <td class="num monto">{{ fmt(totalPresupuestado) }}</td>
            <td class="num monto monto--pos">{{ fmt(totalPagado) }}</td>
            <td class="num monto cell-total">{{ fmt(totalDebo) }}</td>
          </tr>
        </tfoot>
      </table>
    </section>
  </div>
</template>

<style scoped>
.card__head { display: flex; align-items: center; justify-content: space-between; gap: 16px; padding: 20px 22px 14px; }
.card__resumen { font-size: 15px; color: var(--ink-muted); }
.card__resumen .monto { margin-left: 6px; }
.link-obra { color: var(--ink); text-decoration: none; }
.link-obra:hover { color: var(--accent); text-decoration: underline; }
.cell-total-label { font-size: 12px; font-weight: 600; text-transform: uppercase; letter-spacing: 0.05em; color: var(--ink-muted); }
.cell-total { font-weight: 600; color: var(--ink); }
/* Debo negativo = se pagó de más, hay que pedirle al cliente. */
.debo-exceso { color: var(--negative); }
</style>
