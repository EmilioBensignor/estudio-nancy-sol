<script setup>
// Combobox de rubro reusable: input libre + sugerencias propias.
// Si el rubro no está en la lista, se puede escribir uno nuevo igual.
const props = defineProps({
  modelValue: { type: String, default: '' },
  placeholder: { type: String, default: 'Ej: Albañilería (o escribí uno nuevo)' },
  invalid: { type: Boolean, default: false },
  // Sugerencias: los rubros reales de la DB (nombres). Si no se pasan, carga solo.
  rubros: { type: Array, default: null },
})
const emit = defineEmits(['update:modelValue'])

// Rubros para sugerencias: usa los que llegan por prop, o los trae de la DB.
const rubrosCargados = ref([])
const rubrosExistentes = computed(() =>
  (props.rubros ?? rubrosCargados.value).map((r) => (typeof r === 'string' ? r : r.nombre)),
)

const valor = computed({
  get: () => props.modelValue,
  set: (v) => emit('update:modelValue', v),
})

const open = ref(false)
const box = ref(null)
const filtrados = computed(() => {
  const q = valor.value.trim().toLowerCase()
  if (!q) return rubrosExistentes.value
  return rubrosExistentes.value.filter((r) => r.toLowerCase().includes(q))
})
// ¿lo que escribió es un rubro nuevo (no está en la lista)?
const esNuevo = computed(() => {
  const q = valor.value.trim().toLowerCase()
  return q.length > 0 && !rubrosExistentes.value.some((r) => r.toLowerCase() === q)
})

function elegir(r) {
  valor.value = r
  open.value = false
}

onMounted(async () => {
  // Cargar rubros de la DB para sugerencias (salvo que lleguen por prop)
  if (!props.rubros) {
    try {
      const { getRubros } = useDb()
      rubrosCargados.value = await getRubros()
    } catch (e) {
      console.error('No se pudieron cargar los rubros', e)
    }
  }

  // Cerrar al hacer click afuera
  const handler = (e) => {
    if (box.value && !box.value.contains(e.target)) open.value = false
  }
  document.addEventListener('click', handler)
  onUnmounted(() => document.removeEventListener('click', handler))
})
</script>

<template>
  <div ref="box" class="combo">
    <input
      v-model="valor"
      type="text"
      class="field combo__input"
      :class="{ 'field--error': invalid }"
      :placeholder="placeholder"
      autocomplete="off"
      @focus="open = true"
      @input="open = true"
    />
    <svg class="combo__caret" width="11" height="7" viewBox="0 0 11 7" fill="none">
      <path d="M1 1l4.5 4L10 1" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round" />
    </svg>

    <div v-if="open" class="combo__menu">
      <button
        v-for="r in filtrados"
        :key="r"
        type="button"
        class="combo__option"
        :class="{ 'combo__option--sel': r === valor }"
        @click="elegir(r)"
      >
        {{ r }}
      </button>
      <div v-if="esNuevo" class="combo__new">
        <svg width="13" height="13" viewBox="0 0 14 14" fill="none"><path d="M7 1v12M1 7h12" stroke="currentColor" stroke-width="2" stroke-linecap="round" /></svg>
        Crear rubro nuevo: <strong>{{ valor.trim() }}</strong>
      </div>
      <div v-else-if="!filtrados.length" class="combo__empty">Sin coincidencias</div>
    </div>
  </div>
</template>

<style scoped>
.combo { position: relative; }
.combo__input { width: 100%; padding-right: 38px; }
.combo__caret {
  position: absolute;
  top: 50%;
  right: 14px;
  transform: translateY(-50%);
  color: var(--ink-muted);
  pointer-events: none;
}
.combo__menu {
  position: absolute;
  top: calc(100% + 6px);
  left: 0;
  right: 0;
  z-index: 20;
  max-height: 280px;
  overflow-y: auto;
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: var(--radius);
  box-shadow: var(--shadow);
  padding: 6px;
}
.combo__option {
  display: block;
  width: 100%;
  text-align: left;
  padding: 9px 12px;
  border: none;
  border-radius: var(--radius-sm);
  background: transparent;
  font-family: inherit;
  font-size: 16px;
  color: var(--ink);
  cursor: pointer;
  transition: background 100ms var(--ease-out);
}
.combo__option:hover { background: var(--surface-raised); }
.combo__option--sel { background: var(--accent-subtle); color: var(--accent-hover); font-weight: 500; }
.combo__new {
  display: flex;
  align-items: center;
  gap: 7px;
  margin-top: 4px;
  padding: 10px 12px;
  border-top: 1px solid var(--border-subtle);
  font-size: 15px;
  color: var(--ink-muted);
}
.combo__new svg { color: var(--accent); flex-shrink: 0; }
.combo__new strong { color: var(--ink); font-weight: 600; }
.combo__empty { padding: 12px; font-size: 15px; color: var(--ink-faint); text-align: center; }
</style>
