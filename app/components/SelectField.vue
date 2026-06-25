<script setup>
// Select custom consistente con .field. Dropdown propio (no nativo) para que el
// menú abierto sea igual en todos los navegadores. API: v-model + options.
// options: array de strings, o { value, label }.
const props = defineProps({
  modelValue: { type: [String, Number], default: '' },
  options: { type: Array, default: () => [] },
  placeholder: { type: String, default: 'Seleccioná' },
  invalid: { type: Boolean, default: false },
  disabled: { type: Boolean, default: false },
})
const emit = defineEmits(['update:modelValue', 'change'])

const norm = computed(() =>
  props.options.map((o) => (typeof o === 'object' ? o : { value: o, label: String(o) })),
)
const seleccionado = computed(() => norm.value.find((o) => o.value === props.modelValue) || null)

const open = ref(false)
const box = ref(null)

function elegir(o) {
  emit('update:modelValue', o.value)
  emit('change', o.value)
  open.value = false
}
function toggle() {
  if (!props.disabled) open.value = !open.value
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
  <div ref="box" class="combo">
    <button
      type="button"
      class="field combo__input combo__trigger"
      :class="{ 'field--error': invalid, 'combo__trigger--open': open }"
      :disabled="disabled"
      @click="toggle"
    >
      <span :class="seleccionado ? '' : 'combo__placeholder'">{{ seleccionado ? seleccionado.label : placeholder }}</span>
    </button>
    <svg class="combo__caret" width="11" height="7" viewBox="0 0 11 7" fill="none">
      <path d="M1 1l4.5 4L10 1" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round" />
    </svg>

    <div v-if="open" class="combo__menu">
      <button
        v-for="o in norm"
        :key="o.value"
        type="button"
        class="combo__option"
        :class="{ 'combo__option--sel': o.value === modelValue }"
        @click="elegir(o)"
      >
        {{ o.label }}
      </button>
      <div v-if="!norm.length" class="combo__empty">Sin opciones</div>
    </div>
  </div>
</template>

<style scoped>
.combo { position: relative; }
.combo__input { width: 100%; padding-right: 38px; }
.combo__trigger {
  display: flex;
  align-items: center;
  text-align: left;
  cursor: pointer;
}
.combo__trigger:disabled { opacity: 0.5; cursor: not-allowed; }
.combo__trigger--open { border-color: var(--accent); box-shadow: 0 0 0 3px var(--accent-ring); }
.combo__placeholder { color: var(--ink-faint); }
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
.combo__empty { padding: 12px; font-size: 15px; color: var(--ink-faint); text-align: center; }
</style>
