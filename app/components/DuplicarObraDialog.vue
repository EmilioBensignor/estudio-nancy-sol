<template>
  <dialog ref="dlg" class="dup" @cancel.prevent="cerrar" @click="onBackdrop">
    <form class="dup__box" @submit.prevent="confirmar">
      <h2 class="dup__title">Duplicar obra</h2>
      <p class="dup__msg">
        Se copia el presupuesto de <strong>{{ obra?.nombre_direccion }}</strong> con su cliente y
        configuración. La caja y los retiros arrancan vacíos.
      </p>

      <div class="field-group">
        <label class="label" for="dup-nombre">Nombre de la copia</label>
        <input
          id="dup-nombre"
          ref="inputRef"
          v-model="nombre"
          class="field"
          type="text"
          autocomplete="off"
        />
      </div>

      <span v-if="error" class="field-error">{{ error }}</span>

      <div class="dup__actions">
        <button type="button" class="btn btn--ghost" @click="cerrar">Cancelar</button>
        <button type="submit" class="btn btn--primary" :disabled="procesando">
          {{ procesando ? 'Duplicando…' : 'Duplicar' }}
        </button>
      </div>
    </form>
  </dialog>
</template>

<script setup>
const props = defineProps({
  open: { type: Boolean, default: false },
  obra: { type: Object, default: null },
  procesando: { type: Boolean, default: false },
  error: { type: String, default: '' },
})
const emit = defineEmits(['confirmar', 'cerrar'])

const dlg = ref(null)
const inputRef = ref(null)
const nombre = ref('')

watch(
  () => props.open,
  async (v) => {
    if (!dlg.value) return
    if (v && !dlg.value.open) {
      nombre.value = `${props.obra?.nombre_direccion || ''} B`
      dlg.value.showModal()
      await nextTick()
      inputRef.value?.select()
    } else if (!v && dlg.value.open) {
      dlg.value.close()
    }
  },
)

function cerrar() {
  emit('cerrar')
}

function confirmar() {
  const limpio = nombre.value.trim()
  if (!limpio) return
  emit('confirmar', limpio)
}

function onBackdrop(e) {
  if (e.target === dlg.value) cerrar()
}
</script>

<style scoped>
.dup {
  width: min(420px, calc(100vw - 32px));
  border: 1px solid var(--border);
  border-radius: var(--radius-lg);
  background: var(--surface);
  padding: 0;
  color: var(--ink);
}
.dup::backdrop { background: rgba(28, 27, 25, 0.4); }
.dup__box { display: flex; flex-direction: column; gap: 16px; padding: 24px; }
.dup__title { font-size: 18px; font-weight: 600; letter-spacing: -0.2px; }
.dup__msg { font-size: 15px; color: var(--ink-muted); line-height: 1.45; }
.dup__msg strong { color: var(--ink); font-weight: 600; }
.dup__actions { display: flex; justify-content: flex-end; gap: 10px; margin-top: 4px; }
</style>
