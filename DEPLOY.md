# Deploy — Estudio Nancy Sol (Vercel + Supabase)

> App = SPA Nuxt 4 (`ssr: false`) + Supabase. Vercel es el caso ideal. Esta guía es el paso a
> paso para publicarla. Backend (Supabase) ya está en producción — solo falta el frontend.

## Estado de readiness (verificado)

- [x] Es repo git (`git` inicializado).
- [x] `.gitignore` ya protege `.env`, `.env.*`, `.output`, `.nuxt`, `node_modules`, `dist`.
      → **el `.env` NO se sube** (bien, tiene las keys).
- [x] Supabase en producción (`zhnudiedkqlhslebproh`, org Bensignor). Tablas, RLS y views OK.
- [ ] **Falta**: subir a GitHub + conectar Vercel + cargar env vars (este doc).
- [ ] **Falta**: usuario real del estudio en Supabase Auth (ver BACKEND.md §6).

## Variables de entorno (las únicas 2)

En `.env` local hay:

```
NUXT_PUBLIC_SUPABASE_URL=https://zhnudiedkqlhslebproh.supabase.co
NUXT_PUBLIC_SUPABASE_ANON_KEY=<la anon key>
```

Ambas son **públicas por diseño** (prefijo `NUXT_PUBLIC_`, viajan al cliente en una SPA).
La seguridad real la da **RLS en Supabase**, no el secreto de la anon key. Aun así, NO subir el
`.env` al repo — las env vars se cargan en Vercel (abajo).

> Antes de deployar conviene crear un `.env.example` (sin valores) para que el repo documente
> qué env vars necesita:
> ```
> NUXT_PUBLIC_SUPABASE_URL=
> NUXT_PUBLIC_SUPABASE_ANON_KEY=
> ```

## Pasos

### 1. Subir a GitHub
```bash
# (anunciar y confirmar antes de cualquier git de escritura — regla del CLAUDE.md)
git add -A
git commit -m "App lista para deploy"
# crear repo en GitHub (privado, es app interna confidencial) y:
git remote add origin git@github.com:<usuario>/nancy.git
git push -u origin main
```
> Repo **PRIVADO** — es una app interna con datos confidenciales del estudio.

### 2. Conectar Vercel
1. vercel.com → New Project → importar el repo de GitHub.
2. Vercel **detecta Nuxt solo**. Framework Preset: Nuxt.js. Build command y output quedan auto.
3. **Environment Variables**: cargar las 2 (`NUXT_PUBLIC_SUPABASE_URL`,
   `NUXT_PUBLIC_SUPABASE_ANON_KEY`) con los valores del `.env` local. Para los 3 entornos
   (Production / Preview / Development).
4. Deploy.

### 3. Apuntar Supabase al dominio de Vercel
En Supabase → Authentication → URL Configuration:
- **Site URL**: la URL de Vercel (ej. `https://nancy.vercel.app`).
- **Redirect URLs**: agregar esa URL.
> Si no, el login puede fallar por CORS / redirect no permitido.

### 4. Verificar en prod
- [ ] Entra el login con el usuario real.
- [ ] Carga la lista de obras (lee de Supabase).
- [ ] Crear una obra/cliente de prueba persiste.
- [ ] Exportar (imprimir) abre el documento.

## Notas

- **SPA (`ssr: false`)**: Vercel la sirve como estático + funciones. Sin SSR, sin servidor Node
  propio. Simple y barato (probablemente free tier).
- **Build local de prueba** antes de pushear: `pnpm build` (ya pasa limpio).
- **pnpm**: Vercel lo detecta por el `pnpm-lock.yaml`. No forzar npm.
- **Dominio propio** (opcional): si el estudio quiere `app.estudionancysol.com`, se agrega en
  Vercel → Domains y se actualiza el Site URL de Supabase.
