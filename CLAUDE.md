# CLAUDE.md — Estudio Nancy Sol

App interna de gestión de obras para el estudio de **Nancy Bensignor** y **Solana Rutenberg**
(arquitectas). Reemplaza el Excel `MODELO PRESUPUESTO.xlsx` (en la raíz, no versionado:
es dato confidencial). Desde septiembre 2026 **Jessica** también puede retirar en algunas obras.

> **Cómo está organizado este archivo (3 zonas):**
> - **ZONA 1 · REGLAS VIGENTES**: stack, comandos, convenciones y sistema de diseño. Siempre aplican.
> - **ZONA 2 · ARQUITECTURA Y ESTADO**: rutas, datos, reglas contables, gotchas y qué falta.
> - **ZONA 3 · RESTRICCIONES EXTERNAS**: Supabase, Vercel y el Excel. No se borran al refactorizar.
>
> Documentación: `docs/` (modelo de datos, objetivos, deploy, testing) · `docs/historial/`
> (plan y spec de junio, solo referencia) · `PRODUCT.md` y `DESIGN.md` (producto y diseño, en la
> raíz porque los lee `/impeccable`) · este archivo (reglas y arquitectura).

# ━━━━━━ ZONA 1 · REGLAS VIGENTES ━━━━━━

## Stack

| Tecnología | Versión | Uso |
|---|---|---|
| Nuxt | ^4.4 | SPA (`ssr: false`): Supabase es 100% client-side |
| Vue | ^3.5 | `<script setup>`, **JS no TS** en componentes |
| Tailwind CSS | ^4.3 | Vía `@tailwindcss/postcss`. Casi todo el estilo es CSS propio en `main.css` |
| @nuxt/fonts | ^0.14 | DM Sans + DM Mono self-hosted, sin requests a Google |
| Supabase | `@supabase/supabase-js` ^2.107 | Base, auth, cálculos en views |
| pnpm | 11.x | Gestor. Nunca npm (rompe `node_modules`) |
| Vercel | — | Deploy automático desde `main` |

## Comandos

- `pnpm dev` → **localhost:3002**. El script fuerza `TMPDIR=/tmp` (ver gotcha 4). El **usuario
  levanta el server**, no Claude.
- `pnpm build` → build de producción. Es la verificación de referencia (typecheck da falsos errores).

## Convenciones

- UI en español rioplatense, código en inglés, comentarios en español.
- `.vue`: orden `<template>` → `<script setup>` → `<style scoped>`. Varios archivos viejos todavía
  tienen el script arriba: se reordenan al tocarlos.
- Navegación interna: **siempre `<NuxtLink>`**, nunca `<a href>` (en SPA no rutea bien).
- Si `x.vue` necesita rutas hijas `x/nuevo`, moverlo a `x/index.vue` (si no, la ruta hija
  renderiza la lista).
- Acceso a datos solo por `app/composables/useDb.js`. Nada de queries sueltas en las páginas.
- Git: nunca comandos de escritura sin confirmación explícita. Commits en español.

## Componentes de formulario (`app/components/`)

| Componente | Uso |
|---|---|
| `SelectField.vue` | Select custom. `v-model` + `options` (strings o `{value, label}`). Siempre en vez de `<select>` |
| `DateField.vue` | Datepicker. Guarda ISO `YYYY-MM-DD`, muestra `DD/MM/AAAA`. En vez de `<input type="date">` |
| `RubroCombo.vue` | Rubro: texto libre + sugerencias, crea al vuelo |
| `ConfirmDialog.vue` | `<dialog>` nativo para borrados. Prop `bloqueo`: deshabilita y explica por qué no se puede |
| `DuplicarObraDialog.vue` | Duplica una obra con su presupuesto (sin caja ni retiros) |
| `DocumentoPresupuesto.vue` | PDF del presupuesto para el cliente (impresión del navegador) |
| `DocumentoReporte.vue` | PDF genérico de reportes (cobros, pagos, detalle de proveedor) |

Campos opcionales: `<span class="label-opt">(opcional)</span>` en el label, nunca placeholder.
Switch on/off: clases `.switch` / `.switch--on` / `.switch__knob` de `main.css`.

## Sistema de diseño (todo en `app/assets/css/main.css`)

Fuente única de verdad. Las páginas usan clases compartidas y un `<style scoped>` mínimo.

- **Layout global** (`app/layouts/default.vue`): nombres centrados arriba + tabs Obras / Clientes /
  Proveedores / Retiros. Aplica a todas las pantallas.
- **Ancho**: `.shell` max 1250px. Forms internos a 720 con `.form-narrow`.
- **Page header**: `.page-header` (back arriba, fila título + acciones). Igual en todas.
- **Tipografía mínima 16px** en desktop (tabla, inputs y tabs 16; botones 15; labels 13).
- **Paleta**: crema (`--bg`) + ink + terracota (`--accent`), más semánticos positive/negative/warning.
- **Montos**: clase `.monto` (DM Mono, tabular-nums, sin cortes de línea). `fmt()` conserva
  siempre el signo: nunca `Math.abs` sin signo.
- Sin sombras en reposo, sin gradientes, sin glassmorphism. Detalle en `DESIGN.md`.

# ━━━━━━ ZONA 2 · ARQUITECTURA Y ESTADO ━━━━━━

## Rutas

```
/                          pages/index.vue                 lista de obras + balance
/login                     pages/login.vue                 login compartido
/obras/nueva               pages/obras/nueva.vue           alta de obra + quién retira
/obras/[id]                pages/obras/[id]/index.vue      detalle: tabs Caja / Presupuesto / Proveedores / Retiros
/obras/[id]/configuracion  config: nombre, estado, honorario, quién retira y reparto, eliminar
/clientes                  lista (búsqueda + orden)
/clientes/nuevo            alta
/clientes/[id]/editar      editar + eliminar (solo si no tiene obras)
/proveedores               lista (búsqueda + orden)
/proveedores/nuevo         alta (rubro con RubroCombo)
/proveedores/[id]          deuda del proveedor en todas las obras
/proveedores/[id]/editar   editar + eliminar (solo sin ítems ni movimientos)
/retiros                   retiros de todas las obras, totales por socia
```

**Obras por slug**: la URL usa `obras/ramsay-1945`, no el UUID. `obras.slug` es único;
`crearObra` lo genera del nombre con sufijo -2/-3 si se repite. `getObra(idOrSlug)` acepta ambos.
En `[id]/index.vue` el `obraId` pasa al UUID real después de cargar (las queries filtran por id).
El PDF exportado se llama como el slug (vía `document.title`).

## Datos y cálculos

Detalle completo en [docs/modelo-de-datos.md](docs/modelo-de-datos.md). Lo esencial:

- Supabase `zhnudiedkqlhslebproh` (proyecto "Nancy"), MCP **`supabase-nancy`**.
- Auth real: login compartido, `useAuth.js` + `middleware/auth.global.js` + `plugins/auth.client.js`.
- Las cuentas viven en views: `v_presupuesto_items`, `v_obra_totales`, `v_caja_saldo`,
  `v_saldos_obra`, `v_retiros_convergencia`, `v_control_obra`, `v_pagos_por_proveedor`.
- **Control alineado al Excel, cierra en 0**:
  `saldo_a_cobrar + saldo_caja − deuda − honorarios_15 − adicional = 0`.
  - `saldo_caja` = suma de movimientos (no el último acumulado).
  - Honorarios a retirar = solo el 15%, sin adicional.
  - Adicional = reserva (cubre IVA de proveedores grandes). Resta en el Control, no es ganancia.
- **TC por transacción**: el dólar se carga al cobrar o mover en USD. USD = siempre efectivo.
  `obras.tipo_cambio_fallback` quedó sin UI pero la usa `v_presupuesto_items` como fallback.
- **Retiros**: pueden retirar Nancy, Solana y Jessica. Switch por obra (`obras.retira_<key>`) y
  reparto en `obras.split_<key>_override`; montos en `retiros.monto_<key>`. Las keys (`nancy`,
  `sol`, `jessica`) y los nombres salen de `app/composables/useSocias.js`. Techo = honorario 15%.
  Objetivos por socia y "para emparejar" se calculan en el front (`obras/[id]/index.vue`).

## Gotchas

1. **`<` y `>` sueltos en `<script setup>` rompen el parser SFC** con un error engañoso ("Element
   is missing end tag" apuntando al `<style>`). Pasó con `a < b ? x : y`. Usar `Math.min/max/sign`
   o un helper (`esPositivo(n)` en `[id]/index.vue`, que es `>= 0`). En el template están ok.
2. **HMR de Vite se queda pegado** después de varios errores de parsing: sigue mostrando el error
   viejo aunque el archivo esté bien. Reiniciar `pnpm dev`.
3. **Comentarios `<!-- -->` entre ramas `v-if`/`v-else-if`/`v-else`** rompen la cadena. Ponerlos
   dentro de cada rama.
4. **Socket de vite-node en macOS**: Nuxt 4.4.7 crea un Unix socket cuyo path no puede pasar 104
   caracteres; con la ruta larga del proyecto daba ENOENT. Por eso `dev` usa `TMPDIR=/tmp`. No cambiar.
5. **typecheck**: `npx nuxt typecheck` a veces tira un `TS5083` fantasma mientras corre el dev
   server. No es real; verificar con `pnpm build`.
6. **`ganancia_cobrada_ars` miente**: en `v_retiros_convergencia` contiene el honorario 15%, no la
   ganancia cobrada. Las columnas `target_*`/`diferencia_*` de esa view solo conocen a Nancy y Solana.
7. **Correr `nuxt` desde una subcarpeta** (por ejemplo `app/pages`) genera `.nuxt`, `.output` y
   `node_modules` sueltos ahí adentro. Están ignorados, pero se borran.

## Estado actual (22 sep 2026)

Hecho:
- CRUD completo con edición y borrado guardado (cliente sin obras; proveedor sin ítems ni
  movimientos; obra vacía). Ítems, caja y retiros se editan y borran inline.
- Listas con búsqueda y orden. Duplicar obra. Reportes PDF de cobros, pagos y proveedor.
- Tab Proveedores: deuda por proveedor (presupuestado − pagado); debo negativo en rojo.
- Presupuesto: total en footer; toggle "Proveedor en PDF" (solo afecta el PDF).
- Jessica y switches de quién retira por obra (migración 021). Al Río C: Solana y Jessica 50/50.
- `supabase/migrations/` tiene el historial completo, con las mismas versiones que la base.

Pendiente:
- "Al Río - superado" tiene el Control en $ 1.504.213: datos incompletos o una obra reemplazada por
  Al Río B/C. Confirmar con el estudio si se borra.
- Obras con `split_*_override` en `null` (Ohiggins p. 17): el front las reparte parejo; guardar la
  configuración una vez las deja explícitas.
- Exportar PDF a futuro vía Edge Function (`exportar-presupuesto`), no html2pdf. Hoy alcanza con
  la impresión del navegador.

# ━━━━━━ ZONA 3 · RESTRICCIONES EXTERNAS ━━━━━━

## Supabase

- **La base es producción con obras reales** y no hay staging. Toda escritura (migración, update,
  seed) se confirma antes.
- **`supabase/seed_ramsay.sql` borra todas las obras** (`delete from obras`, caja, ítems y retiros)
  antes de cargar el caso Ramsay 1945. No correrlo contra esta base.
- `apply_migration` versiona con la hora de aplicación: renombrar el archivo local a esa versión.
- `create or replace view` resetea las reloptions: repetir `with (security_invoker = on)` o la view
  vuelve a ser security definer.
- Al crear usuarios por SQL, los campos `*_token` de `auth.users` van en `''`, no `NULL`.
- Proyecto free: `_keepalive` recibe un ping para que no se pause. Es la única tabla con `anon`.

## Vercel

- Proyecto `estudio-nancy-sol`, deploy automático desde `main`. Env vars:
  `NUXT_PUBLIC_SUPABASE_URL`, `NUXT_PUBLIC_SUPABASE_ANON_KEY`.
- Aplicar la migración **antes** de pushear el front que la usa.

## El Excel

- `MODELO PRESUPUESTO.xlsx` es la fuente de verdad de las fórmulas. No se versiona (confidencial).
- En documentos para el cliente, solo texto literal del Excel: no inventar leyendas ni copy.
- El presupuesto para el cliente muestra solo las columnas F a K: nunca costo, proveedor (salvo
  el toggle) ni ganancia.
