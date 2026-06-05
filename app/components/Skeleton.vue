<script setup>
// Bloque skeleton reutilizable. Ancho/alto configurables; animación de shimmer.
defineProps({
  width: { type: String, default: '100%' },
  height: { type: String, default: '16px' },
  radius: { type: String, default: 'var(--radius-sm)' },
})
</script>

<template>
  <span class="skeleton" :style="{ width, height, borderRadius: radius }" aria-hidden="true" />
</template>

<style scoped>
.skeleton {
  display: block;
  background: linear-gradient(
    100deg,
    var(--surface-raised) 30%,
    var(--border-subtle) 50%,
    var(--surface-raised) 70%
  );
  background-size: 200% 100%;
  animation: skeleton-shimmer 1.3s ease-in-out infinite;
}
@keyframes skeleton-shimmer {
  0% { background-position: 200% 0; }
  100% { background-position: -200% 0; }
}
@media (prefers-reduced-motion: reduce) {
  .skeleton { animation: none; }
}
</style>
