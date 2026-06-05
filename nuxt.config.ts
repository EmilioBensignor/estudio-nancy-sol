// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
  compatibilityDate: '2025-07-15',
  devtools: { enabled: true },

  // Módulos
  modules: ['@nuxt/fonts'],

  // Fonts: self-hosted, sin requests a Google (app interna confidencial)
  fonts: {
    families: [
      { name: 'DM Sans', provider: 'google', weights: [400, 500, 600, 700] },
      { name: 'DM Mono', provider: 'google', weights: [400, 500] },
    ],
  },

  // CSS
  css: ['~/assets/css/main.css'],

  // PostCSS para Tailwind v4
  postcss: {
    plugins: {
      '@tailwindcss/postcss': {},
    },
  },

  // Runtime config: expuesta al cliente
  runtimeConfig: {
    public: {
      supabaseUrl: process.env.NUXT_PUBLIC_SUPABASE_URL,
      supabaseAnonKey: process.env.NUXT_PUBLIC_SUPABASE_ANON_KEY,
    },
  },

  // SSR-safe: runtime env solo en cliente para supabase-js
  ssr: false,
})