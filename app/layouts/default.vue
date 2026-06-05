<script setup>
const nav = [
  { to: '/', label: 'Obras', match: (p) => p === '/' || p.startsWith('/obras') },
  { to: '/clientes', label: 'Clientes', match: (p) => p.startsWith('/clientes') },
  { to: '/proveedores', label: 'Proveedores', match: (p) => p.startsWith('/proveedores') },
]
const route = useRoute()

const { logout } = useAuth()
const confirmarSalir = ref(false)
const saliendo = ref(false)

async function salir() {
  saliendo.value = true
  await logout()
  navigateTo('/login')
}
</script>

<template>
  <div class="app">
    <header class="masthead">
      <div class="masthead__inner">
        <div class="masthead__names">
          <span class="masthead__name">Nancy Bensignor</span>
          <span class="masthead__sep">·</span>
          <span class="masthead__name masthead__name--muted">Solana Rutenberg</span>
        </div>
        <button type="button" class="masthead__logout" @click="confirmarSalir = true">Salir</button>
      </div>
      <nav class="nav">
        <div class="nav__inner">
          <NuxtLink
            v-for="item in nav"
            :key="item.to"
            :to="item.to"
            class="nav__link"
            :class="{ 'nav__link--active': item.match(route.path) }"
          >
            {{ item.label }}
          </NuxtLink>
        </div>
      </nav>
    </header>

    <main class="app__body">
      <slot />
    </main>

    <!-- Modal de confirmación para salir -->
    <Transition name="modal">
      <div v-if="confirmarSalir" class="modal-overlay" @click.self="confirmarSalir = false">
        <div class="modal" role="dialog" aria-modal="true">
          <h2 class="modal__title">¿Cerrar sesión?</h2>
          <p class="modal__text">Vas a salir de la app. Podés volver a entrar cuando quieras.</p>
          <div class="modal__actions">
            <button type="button" class="btn btn--ghost" :disabled="saliendo" @click="confirmarSalir = false">Cancelar</button>
            <button type="button" class="btn btn--primary" :disabled="saliendo" @click="salir">{{ saliendo ? 'Saliendo…' : 'Salir' }}</button>
          </div>
        </div>
      </div>
    </Transition>
  </div>
</template>

<style scoped>
.app { min-height: 100dvh; }

/* ===== Masthead: membrete del estudio ===== */
.masthead {
  border-bottom: 1px solid var(--border);
  background: var(--surface);
}
.masthead__inner {
  position: relative;
  max-width: 1250px;
  margin: 0 auto;
  padding: 22px 32px 18px;
  display: flex;
  justify-content: center;
}
.masthead__logout {
  position: absolute;
  top: 50%;
  right: 32px;
  transform: translateY(-50%);
  background: transparent;
  border: none;
  font-family: inherit;
  font-size: 14px;
  font-weight: 500;
  color: var(--ink-muted);
  cursor: pointer;
  transition: color 150ms var(--ease-out);
}
.masthead__logout:hover { color: var(--accent); }
.masthead__names { display: flex; align-items: baseline; gap: 12px; }
.masthead__name {
  font-size: 20px;
  font-weight: 600;
  letter-spacing: 0.01em;
  color: var(--ink);
}
.masthead__name--muted { color: var(--ink-muted); font-weight: 500; }
.masthead__sep { color: var(--ink-faint); font-size: 18px; }

/* ===== Nav: tabs grandes, centradas ===== */
.nav { display: flex; justify-content: center; }
.nav__inner {
  display: flex;
  gap: 6px;
  max-width: 1250px;
  width: 100%;
  padding: 0 32px;
  justify-content: center;
}
.nav__link {
  position: relative;
  padding: 15px 22px 17px;
  font-size: 16px;
  font-weight: 600;
  letter-spacing: 0.01em;
  color: var(--ink-muted);
  text-decoration: none;
  transition: color 150ms var(--ease-out);
}
.nav__link::after {
  content: '';
  position: absolute;
  left: 22px;
  right: 22px;
  bottom: -1px;
  height: 2px;
  background: var(--accent);
  border-radius: 2px;
  transform: scaleX(0);
  transition: transform 220ms var(--ease-out);
}
.nav__link:hover { color: var(--ink); }
.nav__link--active { color: var(--accent); }
.nav__link--active::after { transform: scaleX(1); }

@media (max-width: 560px) {
  .masthead__names { flex-direction: column; align-items: center; gap: 0; }
  .masthead__sep { display: none; }
  .nav__inner { gap: 0; }
  .nav__link { padding: 14px 14px 16px; font-size: 15px; }
}

/* ===== Modal de confirmación ===== */
.modal-overlay {
  position: fixed;
  inset: 0;
  z-index: 50;
  display: flex;
  justify-content: center;
  align-items: center;
  padding: 24px;
  background: rgba(28, 26, 23, 0.4);
  backdrop-filter: blur(2px);
}
.modal {
  width: 100%;
  max-width: 380px;
  display: flex;
  flex-direction: column;
  gap: 10px;
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: var(--radius-lg);
  box-shadow: var(--shadow);
  padding: 26px 26px 22px;
}
.modal__title { font-size: 19px; font-weight: 600; letter-spacing: -0.2px; color: var(--ink); }
.modal__text { font-size: 15px; color: var(--ink-muted); line-height: 1.5; }
.modal__actions { display: flex; justify-content: flex-end; gap: 10px; margin-top: 14px; }

/* Transición del modal */
.modal-enter-active, .modal-leave-active { transition: opacity 180ms var(--ease-out); }
.modal-enter-from, .modal-leave-to { opacity: 0; }
.modal-enter-active .modal, .modal-leave-active .modal { transition: transform 180ms var(--ease-out); }
.modal-enter-from .modal, .modal-leave-to .modal { transform: scale(0.96); }

@media print {
  .modal-overlay { display: none !important; }
}
</style>
