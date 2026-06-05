<script setup>
import { fmtArs as fmt } from '~/composables/useFormato'

const { getObras } = useDb()

const obras = ref([])
const cargando = ref(true)
const error = ref('')

onMounted(async () => {
  try {
    obras.value = await getObras()
  } catch (e) {
    error.value = 'No se pudieron cargar las obras.'
    console.error(e)
  } finally {
    cargando.value = false
  }
})

// Total a cobrar de obras activas: lidera con el número que más importa
const activas = computed(() => obras.value.filter((o) => o.estado === 'activa'))
const totalACobrar = computed(() => activas.value.reduce((acc, o) => acc + Number(o.saldo_a_cobrar_ars || 0), 0))
const totalEnCaja = computed(() => obras.value.reduce((acc, o) => acc + Number(o.saldo_caja_ars || 0), 0))
</script>

<template>
  <div class="shell">
    <!-- Encabezado del balance: el número lidera la pantalla -->
    <section class="balance">
      <div class="balance__hero">
        <span class="balance__label">Total a cobrar</span>
        <span class="balance__value">{{ fmt(totalACobrar) }}</span>
        <span class="balance__note">{{ activas.length }} obras en curso</span>
      </div>
      <div class="balance__aside">
        <span class="balance__aside-label">En caja, todas las obras</span>
        <span class="balance__aside-value monto" :class="totalEnCaja < 0 ? 'monto--neg' : 'monto--pos'">{{ fmt(totalEnCaja) }}</span>
      </div>
    </section>

    <main>
      <div class="section-head">
        <div class="section-head__title">
          <span class="eyebrow">Obras</span>
          <span class="count">{{ obras.length }}</span>
        </div>
        <button class="btn btn--primary" @click="navigateTo('/obras/nueva')">
          <svg width="14" height="14" viewBox="0 0 14 14" fill="none">
            <path d="M7 1v12M1 7h12" stroke="currentColor" stroke-width="2" stroke-linecap="round" />
          </svg>
          Nueva obra
        </button>
      </div>

      <div v-if="cargando" class="obra-grid">
        <article v-for="n in 3" :key="n" class="obra-card obra-card--skeleton">
          <div class="obra-card__head">
            <div class="obra-card__id">
              <Skeleton width="60%" height="19px" />
              <Skeleton width="40%" height="15px" radius="4px" />
            </div>
          </div>
          <div class="obra-card__figure">
            <Skeleton width="50%" height="12px" radius="4px" />
            <Skeleton width="70%" height="28px" />
          </div>
        </article>
      </div>
      <p v-else-if="error" class="estado-msg estado-msg--error">{{ error }}</p>
      <p v-else-if="!obras.length" class="estado-msg">Todavía no hay obras. Creá la primera.</p>

      <div v-else class="obra-grid">
        <article
          v-for="obra in obras"
          :key="obra.id"
          class="obra-card"
          :class="{ 'obra-card--done': obra.estado === 'finalizada' }"
          tabindex="0"
          role="button"
          @click="navigateTo(`/obras/${obra.id}`)"
          @keydown.enter="navigateTo(`/obras/${obra.id}`)"
        >
          <div class="obra-card__head">
            <div class="obra-card__id">
              <h2 class="obra-card__name">{{ obra.nombre_direccion }}</h2>
              <p class="obra-card__client">{{ obra.cliente_nombre }}</p>
            </div>
            <span v-if="obra.estado === 'finalizada'" class="estado estado--finalizada">finalizada</span>
          </div>

          <div class="obra-card__figure">
            <span class="obra-card__figure-label">A cobrar</span>
            <span class="obra-card__figure-value monto" :class="{ 'monto--faint': Number(obra.saldo_a_cobrar_ars) === 0 }">
              {{ Number(obra.saldo_a_cobrar_ars) === 0 ? 'Saldada' : fmt(obra.saldo_a_cobrar_ars) }}
            </span>
          </div>
        </article>
      </div>
    </main>
  </div>
</template>

<style scoped>
/* ===== Balance hero ===== */
.balance {
  display: grid;
  grid-template-columns: 1fr auto;
  align-items: end;
  gap: 32px;
  padding: 0 4px 30px;
  border-bottom: 1px solid var(--border);
  margin-bottom: 32px;
}
.balance__hero { display: flex; flex-direction: column; gap: 8px; }
.balance__label {
  font-size: 13px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.1em;
  color: var(--ink-muted);
}
.balance__value {
  font-family: var(--font-mono);
  font-variant-numeric: tabular-nums;
  font-size: clamp(40px, 7vw, 56px);
  font-weight: 500;
  line-height: 1;
  letter-spacing: -1.5px;
  color: var(--ink);
}
.balance__note { font-size: 16px; color: var(--ink-muted); }
.balance__aside { display: flex; flex-direction: column; align-items: flex-end; gap: 7px; text-align: right; }
.balance__aside-label {
  font-size: 13px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.06em;
  color: var(--ink-muted);
}
.balance__aside-value { font-size: 23px; }

/* ===== Grid de obras ===== */
.obra-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(310px, 1fr));
  gap: 16px;
}

.obra-card {
  display: flex;
  flex-direction: column;
  gap: 18px;
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: var(--radius-lg);
  padding: 22px;
  text-align: left;
  cursor: pointer;
  transition: border-color 200ms var(--ease-out), box-shadow 200ms var(--ease-out),
              transform 150ms var(--ease-out);
}
.obra-card--skeleton { cursor: default; pointer-events: none; }
.obra-card--skeleton .obra-card__id { display: flex; flex-direction: column; gap: 8px; }
.obra-card:not(.obra-card--skeleton):hover { border-color: var(--accent); box-shadow: var(--shadow); transform: translateY(-2px); }
.obra-card:focus-visible { outline: none; border-color: var(--accent); box-shadow: 0 0 0 3px var(--accent-ring); }
.obra-card:active { transform: translateY(0); }
.obra-card--done { background: var(--surface-raised); }
.obra-card--done .obra-card__name { color: var(--ink-muted); }
.obra-card--done .obra-card__figure-value { color: var(--ink-muted); }

.obra-card__head { display: flex; align-items: flex-start; justify-content: space-between; gap: 12px; }
.obra-card__id { min-width: 0; }
.obra-card__name { font-size: 19px; font-weight: 600; letter-spacing: -0.2px; color: var(--ink); line-height: 1.25; }
.obra-card__client { font-size: 15px; color: var(--ink-muted); margin-top: 4px; }
.obra-card__head .estado { flex-shrink: 0; }

/* La cifra protagonista de la card */
.obra-card__figure { display: flex; flex-direction: column; gap: 5px; margin-top: auto; }
.obra-card__figure-label {
  font-size: 12px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.07em;
  color: var(--ink-muted);
}
.obra-card__figure-value {
  font-size: 28px;
  font-weight: 500;
  letter-spacing: -0.6px;
  line-height: 1;
}

@media (max-width: 560px) {
  .balance { grid-template-columns: 1fr; align-items: start; gap: 18px; }
  .balance__aside { align-items: flex-start; text-align: left; }
}
</style>
