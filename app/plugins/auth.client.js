// Hidrata la sesión de Supabase al arrancar la app (SPA, solo cliente).
// Mantiene useAuth().session sincronizado con los cambios de auth.

export default defineNuxtPlugin(async () => {
  const { session, sincronizar } = useAuth()
  const sb = useSupabase()

  // Sesión inicial desde el storage de supabase-js
  await sincronizar()

  // Escuchar cambios (login, logout, refresh de token)
  sb.auth.onAuthStateChange((_event, newSession) => {
    session.value = newSession
  })
})
