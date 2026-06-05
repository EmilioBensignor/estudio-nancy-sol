// Auth de la app: login compartido (un solo usuario para las dos socias).
// Estado de sesión reactivo y global vía useState (persiste entre páginas).

export function useAuth() {
  // Sesión actual (null = sin login). Se hidrata en el plugin auth.client.js
  const session = useState('auth_session', () => null)
  const user = computed(() => session.value?.user ?? null)
  const estaLogueado = computed(() => !!session.value)

  async function login(email, password) {
    const sb = useSupabase()
    const { data, error } = await sb.auth.signInWithPassword({ email, password })
    if (error) throw error
    session.value = data.session
    return data.session
  }

  async function logout() {
    const sb = useSupabase()
    await sb.auth.signOut()
    session.value = null
  }

  // Refresca la sesión desde el cliente (al iniciar la app)
  async function sincronizar() {
    const sb = useSupabase()
    const { data } = await sb.auth.getSession()
    session.value = data.session
  }

  return { session, user, estaLogueado, login, logout, sincronizar }
}
