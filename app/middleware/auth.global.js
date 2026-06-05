// Protege toda la app: sin sesión → redirige a /login.
// La página /login es la única pública.

export default defineNuxtRouteMiddleware((to) => {
  // En SSR no hay sesión (la app es SPA); el guard corre en cliente.
  if (import.meta.server) return

  const { estaLogueado } = useAuth()

  if (to.path === '/login') {
    // Si ya está logueado y va al login, mandarlo al inicio
    if (estaLogueado.value) return navigateTo('/')
    return
  }

  if (!estaLogueado.value) {
    return navigateTo('/login')
  }
})
