<script setup>
import { fmtArs as fmt, fmtFecha } from '~/composables/useFormato'

const { getRetirosGlobales } = useDb()

const retiros = ref([])
const cargando = ref(true)
const errorCarga = ref('')

// Monto en ARS de cada socia (el retiro guarda montos en la moneda del TC del día).
function montoNancy(r) {
  return Number(r.monto_nancy) * Number(r.tipo_cambio)
}
function montoSol(r) {
  return Number(r.monto_sol) * Number(r.tipo_cambio)
}

const totalNancy = computed(() => retiros.value.reduce((a, r) => a + montoNancy(r), 0))
const totalSol = computed(() => retiros.value.reduce((a, r) => a + montoSol(r), 0))
const totalGeneral = computed(() => totalNancy.value + totalSol.value)

onMounted(async () => {
  try {
    retiros.value = await getRetirosGlobales()
  } catch (e) {
    errorCarga.value = 'No se pudieron cargar los retiros.'
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
          <h1 class="title">Retiros</h1>
          <p class="subtitle">Retiros de las socias en todas las obras</p>
        </div>
        <div class="reparto__stats">
          <span class="reparto__stat">Nancy <strong class="monto">{{ fmt(totalNancy) }}</strong></span>
          <span class="reparto__stat">Solana <strong class="monto">{{ fmt(totalSol) }}</strong></span>
          <span class="reparto__stat">Total <strong class="monto monto--accent">{{ fmt(totalGeneral) }}</strong></span>
        </div>
      </div>
    </header>

    <p v-if="cargando" class="estado-msg">Cargando…</p>
    <p v-else-if="errorCarga" class="estado-msg estado-msg--error">{{ errorCarga }}</p>

    <section v-else class="card">
      <p v-if="!retiros.length" class="estado-msg">Todavía no hay retiros registrados.</p>
      <table v-else class="table">
        <thead>
          <tr>
            <th style="width: 92px">Fecha</th>
            <th>Obra</th>
            <th class="num">Nancy</th>
            <th class="num">Solana</th>
            <th class="num" style="width: 150px">Total</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="r in retiros" :key="r.id">
            <td class="cell-date">{{ fmtFecha(r.fecha) }}</td>
            <td class="cell-strong">
              <NuxtLink :to="`/obras/${r.obra?.slug || r.obra_id}`" class="link-obra">{{ r.obra?.nombre_direccion || '—' }}</NuxtLink>
            </td>
            <td class="num monto">{{ fmt(montoNancy(r)) }}</td>
            <td class="num monto">{{ fmt(montoSol(r)) }}</td>
            <td class="num monto cell-saldo">{{ fmt(montoNancy(r) + montoSol(r)) }}</td>
          </tr>
        </tbody>
        <tfoot>
          <tr>
            <td colspan="2" class="cell-total-label">Total</td>
            <td class="num monto">{{ fmt(totalNancy) }}</td>
            <td class="num monto">{{ fmt(totalSol) }}</td>
            <td class="num monto cell-total">{{ fmt(totalGeneral) }}</td>
          </tr>
        </tfoot>
      </table>
    </section>
  </div>
</template>

<style scoped>
.reparto__stats { display: flex; gap: 24px; }
.reparto__stat { font-size: 13px; color: var(--ink-muted); }
.reparto__stat strong { margin-left: 6px; font-size: 16px; font-weight: 500; color: var(--ink); }
.cell-strong { font-weight: 600; color: var(--ink); }
.link-obra { color: var(--ink); text-decoration: none; }
.link-obra:hover { color: var(--accent); text-decoration: underline; }
.cell-total-label { font-size: 12px; font-weight: 600; text-transform: uppercase; letter-spacing: 0.05em; color: var(--ink-muted); }
.cell-total { font-weight: 600; color: var(--ink); }
@media (max-width: 600px) { .reparto__stats { gap: 16px; } }
</style>
