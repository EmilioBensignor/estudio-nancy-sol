<template>
  <input
    ref="inputRef"
    :value="mostrarResultado ? resultado : modelValue"
    type="text"
    inputmode="decimal"
    autocomplete="off"
    class="field field--num"
    :class="{ 'field--formula': mostrarResultado }"
    :title="formula ? `=${formula}` : null"
    @focus="enfocado = true"
    @blur="enfocado = false"
    @input="emit('update:modelValue', $event.target.value)"
  />
</template>

<script setup>
// Campo de monto que acepta fórmulas. Como una celda del Excel: con foco muestra la
// fórmula, sin foco el resultado (y la fórmula en el tooltip).
const props = defineProps({
  modelValue: { type: String, default: '' },
})
const emit = defineEmits(['update:modelValue'])

const inputRef = ref(null)
const enfocado = ref(false)

const formula = computed(() => formulaDe(props.modelValue))
const mostrarResultado = computed(() => !enfocado.value && !!formula.value)
const resultado = computed(() => {
  const v = evaluarFormula(props.modelValue)
  return Number.isNaN(v) ? props.modelValue : v.toLocaleString('es-AR', { maximumFractionDigits: 2 })
})

defineExpose({ focus: () => inputRef.value?.focus() })
</script>
