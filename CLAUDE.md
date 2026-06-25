# Estudio Nancy Sol — App de gestión de obras

App interna para dos socias arquitectas (**Nancy Bensignor** y **Solana Rutenberg**) que
reemplaza un Excel de gestión de obras. Ver `OBJETIVOS.md` (objetivos derivados del Excel),
`PLAN.md` (modelo de datos y reglas de negocio), `PRODUCT.md` y `DESIGN.md`.

## Stack

- **Nuxt 4** + Vue 3 (`<script setup>`, **JS no TS** en componentes) + Tailwind v4 + Supabase
- **SPA** (`ssr: false`) — Supabase es client-side
- **pnpm** (no npm). `pnpm dev`, `pnpm build`, `pnpm install`
- Fonts: **@nuxt/fonts** (DM Sans + DM Mono, self-hosted, sin pegar a Google)
- Estado actual: **conectado a Supabase** (org Bensignor, ref `zhnudiedkqlhslebproh`, MCP
  `supabase-bensignor`). Acceso a datos en `app/composables/useDb.js`. Cálculos contables en vistas
  SQL (`v_presupuesto_items`, `v_saldos_obra`, `v_control_obra`, `v_retiros_convergencia`)
- Auth real (login + middleware global). Ver `useAuth.js`, `app/middleware/auth.global.js`
- Dato cargado: una obra real (**Ramsay 1945**) seedeada desde `MODELO PRESUPUESTO.xlsx`
  (`supabase/seed_ramsay.sql`). Ver `TESTING.md`

## Comandos

- `pnpm dev` → corre en **localhost:3002**. El script ya fuerza `TMPDIR=/tmp` (ver gotcha abajo)
- `pnpm build` → producción
- El **usuario levanta el server**, no lo levanta Claude

## Rutas (Nuxt file-based)

```
/                          app/pages/index.vue            lista de obras + balance hero
/obras/nueva               app/pages/obras/nueva.vue      alta de obra
/obras/[id]                app/pages/obras/[id]/index.vue detalle, tabs (Caja/Presupuesto/Proveedores/Retiros)
/obras/[id]/configuracion  config de obra (honorario, split, estado) + eliminar obra
/clientes                  app/pages/clientes/index.vue   lista (búsqueda + orden, link a obra)
/clientes/nuevo            alta de cliente
/clientes/[id]/editar      editar + eliminar (guarda: sin obras)
/proveedores               app/pages/proveedores/index.vue lista (búsqueda + orden)
/proveedores/nuevo         alta (rubro = combobox texto libre con sugerencias)
/proveedores/[id]/editar   editar + eliminar (guarda: sin items/movimientos)
```

**Rutas de obra por slug**: la URL usa `obras/ramsay-1945` (no el UUID). Columna `obras.slug`
única; `crearObra` la genera del nombre con sufijo -2/-3 si se repite. `getObra(idOrSlug)` acepta
ambos. En `[id]/index.vue` el `obraId` se resuelve al UUID real tras cargar (las queries filtran
por id real). El PDF exportado se llama como el slug (vía `document.title`).

Navegación interna: **siempre `<NuxtLink>`**, nunca `<a href>` (en SPA no rutea bien).
Cuando un archivo `x.vue` necesita rutas hijas `x/nuevo`, mover a `x/index.vue` (sino la ruta hija
renderiza la lista).

## Componentes de formulario (reusables, en `app/components/`)

- **`SelectField.vue`**: select custom (dropdown propio, no nativo). API `v-model` + `options`
  (array de strings o `{value, label}`). Usar SIEMPRE en vez de `<select>` nativo.
- **`DateField.vue`**: datepicker custom. Guarda ISO `YYYY-MM-DD`, muestra `DD/MM/AAAA`. Usar en
  vez de `<input type="date">`.
- **`RubroCombo.vue`**: combobox de rubro (texto libre + sugerencias; crea al vuelo).
- **`ConfirmDialog.vue`**: modal `<dialog>` nativo para confirmar borrados, con prop `bloqueo`
  (si tiene texto, deshabilita el botón y explica por qué no se puede eliminar).
- **Campos opcionales**: marcar SIEMPRE con `<span class="label-opt">(opcional)</span>` en el label
  (no con placeholder "Opcional"). Clase en main.css.

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

## Hecho (resuelto)

- Supabase conectado, auth real, todo persiste (clientes/proveedores/obras/items/caja/retiros)
- CRUD completo con edición + borrado guardado (cliente sin obras; proveedor sin items/movimientos;
  obra vacía). Items, movimientos de caja y retiros: editar/borrar inline en `[id]/index.vue`
- D2 resuelto: rubro = FK a `rubros`, con creación al vuelo (`resolverRubroId` en useDb)
- TC por transacción (sin "valor dólar por obra"): el dólar se carga al cobrar/mover en USD.
  USD = siempre efectivo (oculta el medio de pago)
- Listas con búsqueda + orden por columna
- **Control alineado al Excel, cierra en 0** (migrations 014-018). Reglas contables clave:
  - `saldo_caja` = SUMA de movimientos (no "último acumulado"; evita bug de empate de fechas)
  - **honorarios a retirar = solo el 15%**, NO incluye adicional
  - **adicional = reserva** (cubre IVA de proveedores grandes), resta en el Control, no es ganancia
  - Identidad: `saldo_a_cobrar + saldo_caja − deuda − honorarios_15 − adicional = 0`
- Tab **Proveedores** en la obra: deuda por proveedor (presupuestado − pagado). Debo negativo
  (se pagó de más → pedirle al cliente) va resaltado en rojo
- Presupuesto: total de Valor final en footer; toggle "Proveedor en PDF" (UI siempre muestra
  proveedor; el switch solo controla si sale en el PDF exportado)
- URLs de obra por slug + PDF nombrado por slug (ver arriba)

## Pendiente (no hecho)

- D1 (atribución cobro→ganancia para base caja de retiros) del PLAN.md — sigue abierto
- Exportar PDF: hoy `DocumentoPresupuesto.vue` imprime; a futuro vía Edge Function
  (`supabase/functions/exportar-presupuesto`), no html2pdf
- Confirmar con el cliente las dudas abiertas en OBJETIVOS.md
- Limpieza opcional: columna `obras.tipo_cambio_fallback` quedó sin uso en UI pero la usa
  `v_presupuesto_items` como fallback de TC USD; sacarla implica recrear esa vista

## Convenciones

- UI en español, código en inglés, comentarios en español
- Orden de clases Tailwind del CLAUDE.md global (no usar prettier-plugin-tailwindcss)
- Git: nunca comandos de escritura sin confirmación explícita
