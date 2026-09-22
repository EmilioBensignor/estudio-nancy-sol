# Deploy

| Pieza | Dónde |
|---|---|
| Repo | GitHub `EmilioBensignor/estudio-nancy-sol` (privado), rama `main` |
| Front | Vercel, proyecto `estudio-nancy-sol`. Deploy automático en cada push a `main` |
| Base + Auth | Supabase `zhnudiedkqlhslebproh` (proyecto "Nancy"), MCP `supabase-nancy` |

La app es una SPA (`ssr: false`): Vercel la sirve como estático, sin servidor Node propio.
Vercel detecta pnpm por el `pnpm-lock.yaml`.

## Variables de entorno

Las únicas dos, cargadas en Vercel para Production, Preview y Development (y en `.env` local, que
no se sube; plantilla en `.env.example`):

```
NUXT_PUBLIC_SUPABASE_URL=https://zhnudiedkqlhslebproh.supabase.co
NUXT_PUBLIC_SUPABASE_ANON_KEY=<anon key>
```

Son públicas por diseño (viajan al cliente). La seguridad la da RLS, no el secreto de la key.

## Orden al cambiar schema

1. Escribir la migración en `supabase/migrations/<version>_<nombre>.sql`.
2. Aplicarla con el MCP (`apply_migration`). Supabase le asigna su propia versión con la hora de
   aplicación: **renombrar el archivo local a esa versión** (`list_migrations`) para que repo y
   base no se desfasen.
3. Recién después pushear el front que usa las columnas nuevas. Al revés, producción rompe hasta
   que la migración esté aplicada.

## Supabase Auth

En Authentication → URL Configuration, el Site URL y los Redirect URLs tienen que apuntar al
dominio de Vercel. Si cambia el dominio, actualizarlos o el login falla.

Usuarios: se crean por SQL o desde el dashboard. Al crear por SQL, los campos `*_token` de
`auth.users` van en `''`, no `NULL`, o GoTrue rompe el login.

## Verificar después de un deploy

- Entra el login.
- Carga la lista de obras.
- En una obra, el Control da 0 y el tab Retiros muestra a las socias correctas.
