<script setup>
// Datepicker custom consistente con .field. Guarda ISO (YYYY-MM-DD) como el date nativo,
// muestra DD/MM/YYYY. Popup propio: grilla de días + navegación mes/año.
const props = defineProps({
  modelValue: { type: String, default: '' },
  invalid: { type: Boolean, default: false },
  placeholder: { type: String, default: 'dd/mm/aaaa' },
})
const emit = defineEmits(['update:modelValue'])

const open = ref(false)
const box = ref(null)

const MESES = ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre']
const DIAS = ['L', 'M', 'M', 'J', 'V', 'S', 'D']

// Parseo ISO -> {y,m,d} sin pasar por Date (evita corrimientos de timezone)
function parseISO(iso) {
  const m = /^(\d{4})-(\d{2})-(\d{2})$/.exec(iso || '')
  if (!m) return null
  return { y: +m[1], mes: +m[2] - 1, d: +m[3] }
}
const fmtVisible = computed(() => {
  const p = parseISO(props.modelValue)
  return p ? `${String(p.d).padStart(2, '0')}/${String(p.mes + 1).padStart(2, '0')}/${p.y}` : ''
})

// Mes que muestra el calendario (arranca en el valor o en hoy)
const hoy = new Date()
const vistaMes = ref(hoy.getMonth())
const vistaAnio = ref(hoy.getFullYear())

function sincronizarVista() {
  const p = parseISO(props.modelValue)
  vistaMes.value = p ? p.mes : hoy.getMonth()
  vistaAnio.value = p ? p.y : hoy.getFullYear()
}

// Grilla del mes: huecos iniciales (lunes=0) + días
const celdas = computed(() => {
  const primero = new Date(vistaAnio.value, vistaMes.value, 1)
  const offset = (primero.getDay() + 6) % 7 // lunes primero
  const diasEnMes = new Date(vistaAnio.value, vistaMes.value + 1, 0).getDate()
  const out = []
  for (let i = 0; i < offset; i++) out.push(null)
  for (let d = 1; d <= diasEnMes; d++) out.push(d)
  return out
})

const sel = computed(() => parseISO(props.modelValue))
const esHoy = (d) => d === hoy.getDate() && vistaMes.value === hoy.getMonth() && vistaAnio.value === hoy.getFullYear()
const esSel = (d) => sel.value && d === sel.value.d && vistaMes.value === sel.value.mes && vistaAnio.value === sel.value.y

function elegir(d) {
  const iso = `${vistaAnio.value}-${String(vistaMes.value + 1).padStart(2, '0')}-${String(d).padStart(2, '0')}`
  emit('update:modelValue', iso)
  open.value = false
}
function mesAnterior() {
  if (vistaMes.value === 0) { vistaMes.value = 11; vistaAnio.value-- }
  else vistaMes.value--
}
function mesSiguiente() {
  if (vistaMes.value === 11) { vistaMes.value = 0; vistaAnio.value++ }
  else vistaMes.value++
}
function irHoy() {
  vistaMes.value = hoy.getMonth()
  vistaAnio.value = hoy.getFullYear()
  elegir(hoy.getDate())
}
function limpiar() {
  emit('update:modelValue', '')
  open.value = false
}

// Años para el select: ±5 alrededor de la vista (se expande si hace falta)
const anios = computed(() => {
  const base = vistaAnio.value
  const arr = []
  for (let y = base - 6; y <= base + 4; y++) arr.push(y)
  return arr
})

function toggle() {
  if (!open.value) sincronizarVista()
  open.value = !open.value
}

onMounted(() => {
  const handler = (e) => {
    if (box.value && !box.value.contains(e.target)) open.value = false
  }
  document.addEventListener('click', handler)
  onUnmounted(() => document.removeEventListener('click', handler))
})
</script>

<template>
  <div ref="box" class="dp">
    <button
      type="button"
      class="field dp__trigger"
      :class="{ 'field--error': invalid, 'dp__trigger--open': open }"
      @click="toggle"
    >
      <span :class="fmtVisible ? '' : 'dp__placeholder'">{{ fmtVisible || placeholder }}</span>
      <svg class="dp__icon" width="17" height="17" viewBox="0 0 18 18" fill="none">
        <rect x="2.5" y="3.5" width="13" height="12" rx="2" stroke="currentColor" stroke-width="1.4" />
        <path d="M2.5 7h13M6 2v3M12 2v3" stroke="currentColor" stroke-width="1.4" stroke-linecap="round" />
      </svg>
    </button>

    <div v-if="open" class="dp__pop">
      <div class="dp__head">
        <button type="button" class="dp__nav" aria-label="Mes anterior" @click="mesAnterior">
          <svg width="14" height="14" viewBox="0 0 14 14" fill="none"><path d="M9 2L4 7l5 5" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round" /></svg>
        </button>
        <div class="dp__selects">
          <select v-model.number="vistaMes" class="dp__select">
            <option v-for="(m, i) in MESES" :key="i" :value="i">{{ m }}</option>
          </select>
          <select v-model.number="vistaAnio" class="dp__select">
            <option v-for="y in anios" :key="y" :value="y">{{ y }}</option>
          </select>
        </div>
        <button type="button" class="dp__nav" aria-label="Mes siguiente" @click="mesSiguiente">
          <svg width="14" height="14" viewBox="0 0 14 14" fill="none"><path d="M5 2l5 5-5 5" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round" /></svg>
        </button>
      </div>

      <div class="dp__grid dp__grid--dow">
        <span v-for="(d, i) in DIAS" :key="i" class="dp__dow">{{ d }}</span>
      </div>
      <div class="dp__grid">
        <template v-for="(c, i) in celdas" :key="i">
          <span v-if="c === null" class="dp__empty"></span>
          <button
            v-else
            type="button"
            class="dp__day"
            :class="{ 'dp__day--hoy': esHoy(c), 'dp__day--sel': esSel(c) }"
            @click="elegir(c)"
          >{{ c }}</button>
        </template>
      </div>

      <div class="dp__foot">
        <button type="button" class="dp__link" @click="limpiar">Borrar</button>
        <button type="button" class="dp__link" @click="irHoy">Hoy</button>
      </div>
    </div>
  </div>
</template>

<style scoped>
.dp { position: relative; }
.dp__trigger {
  width: 100%;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 8px;
  text-align: left;
  cursor: pointer;
}
.dp__trigger--open { border-color: var(--accent); box-shadow: 0 0 0 3px var(--accent-ring); }
.dp__placeholder { color: var(--ink-faint); }
.dp__icon { color: var(--ink-muted); flex-shrink: 0; }

.dp__pop {
  position: absolute;
  top: calc(100% + 6px);
  left: 0;
  z-index: 30;
  width: 280px;
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: var(--radius);
  box-shadow: var(--shadow);
  padding: 14px;
}
.dp__head { display: flex; align-items: center; gap: 8px; margin-bottom: 12px; }
.dp__selects { flex: 1; display: flex; gap: 6px; }
.dp__select {
  flex: 1;
  height: 32px;
  padding: 0 6px;
  border: 1px solid var(--border);
  border-radius: var(--radius-sm);
  background: var(--surface);
  font-family: inherit;
  font-size: 14px;
  color: var(--ink);
  cursor: pointer;
}
.dp__select:focus { outline: none; border-color: var(--accent); }
.dp__nav {
  width: 30px; height: 30px;
  display: flex; align-items: center; justify-content: center;
  border: 1px solid var(--border);
  border-radius: var(--radius-sm);
  background: transparent;
  color: var(--ink-muted);
  cursor: pointer;
  transition: background 120ms var(--ease-out), color 120ms var(--ease-out);
}
.dp__nav:hover { background: var(--surface-raised); color: var(--ink); }

.dp__grid { display: grid; grid-template-columns: repeat(7, 1fr); gap: 2px; }
.dp__grid--dow { margin-bottom: 4px; }
.dp__dow { text-align: center; font-size: 11px; font-weight: 600; color: var(--ink-faint); padding: 4px 0; }
.dp__empty { aspect-ratio: 1; }
.dp__day {
  aspect-ratio: 1;
  display: flex; align-items: center; justify-content: center;
  border: none;
  border-radius: var(--radius-sm);
  background: transparent;
  font-family: inherit;
  font-size: 14px;
  color: var(--ink);
  cursor: pointer;
  transition: background 100ms var(--ease-out);
}
.dp__day:hover { background: var(--surface-raised); }
.dp__day--hoy { font-weight: 700; color: var(--accent); }
.dp__day--sel { background: var(--accent); color: #fff; font-weight: 600; }
.dp__day--sel:hover { background: var(--accent-hover); }

.dp__foot { display: flex; justify-content: space-between; margin-top: 10px; padding-top: 10px; border-top: 1px solid var(--border-subtle); }
.dp__link { background: none; border: none; font-family: inherit; font-size: 13px; color: var(--accent); cursor: pointer; padding: 2px 4px; }
.dp__link:hover { color: var(--accent-hover); }
</style>
