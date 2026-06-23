<template>
  <dialog ref="dlg" class="confirm" @cancel.prevent="cerrar" @click="onBackdrop">
    <div class="confirm__box">
      <h2 class="confirm__title">{{ titulo }}</h2>
      <p class="confirm__msg">{{ mensaje }}</p>

      <p v-if="bloqueo" class="confirm__bloqueo">{{ bloqueo }}</p>

      <div class="confirm__actions">
        <button type="button" class="btn btn--ghost" @click="cerrar">Cancelar</button>
        <button
          type="button"
          class="btn btn--danger"
          :disabled="!!bloqueo || procesando"
          @click="$emit('confirmar')"
        >
          {{ procesando ? 'Eliminando…' : confirmarTexto }}
        </button>
      </div>
    </div>
  </dialog>
</template>

<script setup>
const props = defineProps({
  open: { type: Boolean, default: false },
  titulo: { type: String, default: '¿Eliminar?' },
  mensaje: { type: String, default: '' },
  // Si tiene texto, el borrado está bloqueado: explica por qué y deshabilita el botón.
  bloqueo: { type: String, default: '' },
  confirmarTexto: { type: String, default: 'Eliminar' },
  procesando: { type: Boolean, default: false },
})
const emit = defineEmits(['confirmar', 'cerrar'])

const dlg = ref(null)

watch(
  () => props.open,
  (v) => {
    if (!dlg.value) return
    if (v && !dlg.value.open) dlg.value.showModal()
    else if (!v && dlg.value.open) dlg.value.close()
  },
)

function cerrar() {
  emit('cerrar')
}

// Click en el backdrop (fuera del box) cierra.
function onBackdrop(e) {
  if (e.target === dlg.value) cerrar()
}
</script>

<style scoped>
.confirm {
  width: min(420px, calc(100vw - 32px));
  border: 1px solid var(--border);
  border-radius: var(--radius-lg);
  background: var(--surface);
  padding: 0;
  color: var(--ink);
}
.confirm::backdrop { background: rgba(28, 27, 25, 0.4); }
.confirm__box { display: flex; flex-direction: column; gap: 12px; padding: 24px; }
.confirm__title { font-size: 18px; font-weight: 600; letter-spacing: -0.2px; }
.confirm__msg { font-size: 15px; color: var(--ink-muted); line-height: 1.45; }
.confirm__bloqueo {
  font-size: 14px;
  color: var(--negative);
  background: var(--negative-bg);
  border-radius: var(--radius-sm);
  padding: 10px 12px;
}
.confirm__actions { display: flex; justify-content: flex-end; gap: 10px; margin-top: 8px; }
</style>
