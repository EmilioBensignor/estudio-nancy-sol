# Estudio Nancy Sol — App de gestión de obras

App interna para dos socias arquitectas (**Nancy Bensignor** y **Solana Rutenberg**) que
reemplaza un Excel de gestión de obras. Ver `OBJETIVOS.md` (objetivos derivados del Excel),
`PLAN.md` (modelo de datos y reglas de negocio), `PRODUCT.md` y `DESIGN.md`.

## Stack

- **Nuxt 4** + Vue 3 (`<script setup>`, **JS no TS** en componentes) + Tailwind v4 + Supabase
- **SPA** (`ssr: false`) — Supabase es client-side
- **pnpm** (no npm). `pnpm dev`, `pnpm build`, `pnpm install`
- Fonts: **@nuxt/fonts** (DM Sans + DM Mono, self-hosted, sin pegar a Google)
- Estado actual: **prototipo con mock data**, pre-Supabase. Mocks en `app/composables/useMockData.ts`

## Comandos

- `pnpm dev` → corre en **localhost:3002**. El script ya fuerza `TMPDIR=/tmp` (ver gotcha abajo)
- `pnpm build` → producción
- El **usuario levanta el server**, no lo levanta Claude

## Rutas (Nuxt file-based)

```
/                          app/pages/index.vue            lista de obras + balance hero
/obras/nueva               app/pages/obras/nueva.vue      alta de obra
/obras/[id]                app/pages/obras/[id]/index.vue detalle con tabs (Caja/Presupuesto/Retiros)
/obras/[id]/configuracion  config de obra (honorario, TC, split)
/obras/[id]/exportar       documento de presupuesto imprimible para cliente
/clientes                  app/pages/clientes/index.vue   lista (link a obra)
/clientes/nuevo            alta de cliente
/proveedores               app/pages/proveedores/index.vue lista (columna rubro, sin divisores)
/proveedores/nuevo         alta (rubro = combobox texto libre con sugerencias)
```

Navegación interna: **siempre `<NuxtLink>`**, nunca `<a href>` (en SPA no rutea bien).
Cuando un archivo `x.vue` necesita rutas hijas `x/nuevo`, mover a `x/index.vue` (sino la ruta hija
renderiza la lista).

## Sistema de diseño (todo en `app/assets/css/main.css`)

Fuente única de verdad. Las pages usan clases compartidas + `<style scoped>` mínimo.

- **Layout global** (`app/layouts/default.vue`): masthead con nombres centrados arriba + tabs
  (Obras/Clientes/Proveedores) abajo. Aplica a TODAS las pantallas (ninguna usa `layout: false`)
- **Ancho único**: `.shell` = max-width **1250px**. Forms internos a 720 con `.form-narrow`
- **Page header unificado**: `.page-header` (back arriba → fila título + acciones). Igual en todas
- **Tipografía mínima 16px** en desktop (body 16, tabla 16, inputs 16, tabs 16, botones 15, labels 13)
- **Paleta**: crema (`--bg`) + ink + terracota (`--accent`). Semánticos positive/negative/warning
- **Montos**: clase `.monto` (DM Mono, tabular-nums, `white-space: nowrap` para no partirse).
  `fmt()` conserva el signo siempre (nunca `Math.abs` sin signo)
- Sin sombras en reposo, sin gradientes, sin glassmorphism (ver DESIGN.md)

## Gotchas conocidos (importantes)

1. **`<` y `>` sueltos en `<script setup>` rompen el parser SFC de Vue/Nuxt** con error engañoso
   "Element is missing end tag" apuntando al `<style>`. Pasó con `a < b ? x : y`. **Evitar
   operadores de comparación sueltos en el script**: usar `Math.min/max/abs` o una función helper
   (ej. `esPositivo(n)` en `[id]/index.vue`). En el template los `>=`/`<` en expresiones están ok.

2. **HMR de Vite se queda pegado** tras varios errores de parsing seguidos: aunque arregles el
   archivo, sigue mostrando el error viejo. Solución: reiniciar `pnpm dev` (Ctrl+C y de nuevo).

3. **Comentarios `<!-- -->` entre ramas `v-if`/`v-else-if`/`v-else`** rompen la cadena. Poner los
   comentarios dentro de cada div, no entre ellos.

4. **Socket de vite-node en macOS**: Nuxt 4.4.7 crea un Unix socket cuyo path no puede pasar 104
   chars. Con la ruta larga de este proyecto + `/var/folders` daba ENOENT. Fix aplicado: script
   `dev` usa `TMPDIR=/tmp` (path corto). No cambiar.

5. **typecheck**: `npx nuxt typecheck` a veces tira un `TS5083` fantasma (busca un tsconfig.json
   inexistente en app/pages) cuando el dev server está escribiendo `.nuxt` en paralelo. No es error
   real. Verificar con `pnpm build` si hay duda.

## Pendiente (no hecho)

- Conectar Supabase: el proyecto **no está** en el mapa de orgs del CLAUDE.md global. Hay que
  crear/elegir uno antes de migraciones. Ver PLAN.md secciones 3-5
- Cerrar decisiones D1 (atribución cobro→ganancia) y D2 (rubro FK vs texto) del PLAN.md
- Todos los botones "Crear/Agregar/Guardar/Registrar" son mock (no persisten) hasta tener backend
- Confirmar con el cliente las 3 dudas abiertas en OBJETIVOS.md

## Convenciones

- UI en español, código en inglés, comentarios en español
- Orden de clases Tailwind del CLAUDE.md global (no usar prettier-plugin-tailwindcss)
- Git: nunca comandos de escritura sin confirmación explícita
