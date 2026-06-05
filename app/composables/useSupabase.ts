import { createClient } from '@supabase/supabase-js'
// SSR-safe: solo se crea en el cliente
let _client: ReturnType<typeof createClient> | null = null

export const useSupabase = () => {
  if (import.meta.server) {
    throw new Error('useSupabase() solo disponible en el cliente')
  }

  if (!_client) {
    const config = useRuntimeConfig()
    const url = config.public.supabaseUrl
    const key = config.public.supabaseAnonKey

    if (!url || !key) {
      throw new Error('Faltan NUXT_PUBLIC_SUPABASE_URL o NUXT_PUBLIC_SUPABASE_ANON_KEY')
    }

    _client = createClient(url, key)
  }

  return _client
}