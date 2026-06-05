# Backend — Estudio Nancy Sol

> Estado del backend. **Prácticamente completo y verificado end-to-end.** Auth, migraciones,
> persistencia de todos los forms y cálculos auditados contra el Excel. Lo único que queda
> está en **"## 6. Lo único que falta"** al final. Ver `PLAN.md` (modelo) y `OBJETIVOS.md`.
>
> `useMockData.ts` ya NO provee data: solo quedan los helpers de formato `fmtArs` / `fmtFecha`.

## 0. Prerequisito: proyecto Supabase

- [x] **Proyecto Supabase**: existe → "Nancy" (`zhnudiedkqlhslebproh`), org Bensignor,
      accesible vía MCP `supabase-bensignor`. URL `https://zhnudiedkqlhslebproh.supabase.co`.
- [x] `useSupabase.ts` conectado (lee runtime config). `.env` ya tiene URL + anon key.
- [x] Variables de entorno (`.env`): `NUXT_PUBLIC_SUPABASE_URL`, `NUXT_PUBLIC_SUPABASE_ANON_KEY`.

## 1. Migraciones (tablas + grants + RLS) — ✅ APLICADAS

Modelo completo en `PLAN.md` secciones 3-5. **Todas aplicadas** (migraciones 001–010 del
04/06 + `012_hardening` del 05/06). Tablas:

- [x] `settings` (honorario default, moneda base)
- [x] `clientes`
- [x] `proveedores` + `rubros` (D2 cerrado: **FK + crear al vuelo** — `resolverRubroId` en `useDb`)
- [x] `obras` (incluye `tipo_cambio_fallback` por obra, `honorario_override`, splits)
- [x] `presupuesto_items` (derivadas en VIEW `v_presupuesto_items`, no generated columns)
- [x] `movimientos_caja` (cobros, pagos; bimoneda: monto nativo + TC por transacción)
- [x] `retiros` (monto_nancy, monto_sol libres; moneda + TC)
- [x] Views: las 7 (saldos, totales, caja, pagos por proveedor, ganancia cobrada, convergencia)
- [x] **Hardening** (`012`): revocado `anon` en tablas de negocio, views a SECURITY INVOKER,
      `search_path` del trigger fijado. Advisors de seguridad: sin errores.

## 2. Persistencia de formularios — ✅ HECHO

Capa de datos en `app/composables/useDb.js`. Auth en `useAuth.js` + middleware `auth.global.js`
+ login (`pages/login.vue`). Forms conectados:

- [x] **Nueva obra** (`obras/nueva.vue`) → insert en `obras` (select de clientes reales)
- [x] **Nuevo cliente** (`clientes/nuevo.vue`) → insert en `clientes`
- [x] **Nuevo proveedor** (`proveedores/nuevo.vue`) → insert + rubro al vuelo
- [x] **Configuración de obra** (`obras/[id]/configuracion.vue`) → update `obras` (%→fracción)
- [x] **Movimiento de caja** (`obras/[id]/index.vue`, `agregarMovimiento`) → insert + TC efectivo
- [x] **Ítem de presupuesto** (`obras/[id]/index.vue`, `agregarItem`) → insert (costo + final)
- [x] **Retiro** (`obras/[id]/index.vue`, `registrarRetiro`) → insert, **50/50 prellenado editable**

Al persistir OK: cierra el form, limpia campos, refresca tablas y saldos. ✅

> **CUIT/dirección — ✅ AGREGADO** (migración `013`): `clientes.cuit`, `clientes.direccion`,
> `proveedores.cuit`. Conectados en altas y listas. Verificado.
> **Auth**: login compartido. Usuario de prueba `lio@bensignor.com`. Falta el usuario real del estudio.
>
> **Adicional/spread + notas por ítem — ✅ HECHO**: el form de ítem separa "valor presupuesto"
> (precio al cliente) de "valor final" (lo que paga), con autocompletado costo×1,21 → presupuesto →
> final, todo editable. `notas` por ítem conectado. Adicional verificado contra la DB.
>
> **"Cobrado para" (auditoría #3) — DESCARTADO**: revisado contra el Excel, la col H de Caja es
> el pago al proveedor (`=-Presupuesto!D`), no una imputación de cobro. La matriz de proveedores
> ya está en `v_pagos_por_proveedor` y el saldo de caja (fórmula BC) en `v_caja_saldo`. No
> corresponde columna nueva.

## 3. Exportar presupuesto → PDF — ✅ HECHO (vía impresión del navegador)

- [x] Documento maquetado en `components/DocumentoPresupuesto.vue` (A4, una tipografía DM Sans,
      sin color, fiel al Excel: nombres + mails del estudio, obra/cliente, tabla F–K, notas literales).
- [x] El botón **"Exportar"** del detalle de obra arma el documento oculto y dispara
      `window.print()` directo (sin pantalla intermedia). `@page { margin:0 }` oculta los
      headers/footers del navegador (fecha/URL).
- [x] Solo columnas F–K (`getPresupuestoCliente` selecciona explícitamente; **nunca** costo ni ganancia).
- [ ] **Pendiente futuro**: Edge Function (Deno + Browserless) para descarga de-un-click real
      sin diálogo de impresión. Requiere API key de browserless.io. Por ahora alcanza con imprimir.

## 4. Datos reales del documento — ✅ HECHO

- [x] Email del cliente (en `clientes`, se trae en `getObra`)
- [x] Fecha de emisión (hoy, en el documento)
- [x] Contacto del estudio: los dos mails reales (del Excel), en el encabezado del documento

## 4b. Reglas de cálculo del Excel — ✅ AUDITADAS Y VERIFICADAS EN LA DB

Verificado fórmula por fórmula contra `MODELO PRESUPUESTO.xlsx` Y contra las views reales en
producción (`v_presupuesto_items`, `v_obra_totales`, `v_ganancia_cobrada`, `v_retiros_convergencia`).
Las reglas están bien modeladas.

- [x] **Ganancia incluye el spread (adicional).** View: `ganancia_ars = total_ars − valor_proveedor_ars`
      (no solo el 15%). El form de ítem ya permite cargar el descuento de proveedor (valor presupuesto
      ≠ valor final). Verificado con un adicional de 80k.
- [x] **Honorario = 15% sobre valor_final** (`honorario_ars = valor_final_ars × honorario`). Default
      0.15 en `settings`, override por obra. Exacto.
- [x] **Total = valor + honorario** (`total_ars = valor_final_ars × (1 + honorario)`). Exacto.
- [x] **Retiros base ganancia COBRADA** (D1): `ganancia_cobrada = ganancia × (cobrado / facturado)`,
      proporcional al cobro real (base caja). Correcto.
- [x] **TC por ítem + fallback por obra**: `COALESCE(NULLIF(tc_item,0), tipo_cambio_fallback)`. Correcto.
- [x] **Reparto 50/50**: el front usa retiros libres con 50/50 **prellenado editable** (decisión
      tomada, mejor que el 50/50 automático del Excel que las socias igual pisaban a mano). La
      convergencia se muestra en `v_retiros_convergencia`.
- [ ] **Control de cuadre "debe ser 0"** (Excel fila BE `=SUM(...)−G`). NO implementado como alerta
      visible. Menor: las views ya calculan saldos correctos; faltaría solo un check/badge que avise
      si un saldo queda descuadrado. Nice-to-have, no bloqueante.

## 5. Decisiones abiertas (de OBJETIVOS.md / PLAN.md) — ✅ CERRADAS

- [x] **D1**: proporcional (ratio cobrado/facturado × ganancia total). Validado contra el seed.
- [x] **D2**: rubro **FK + crear al vuelo** (el combo crea el rubro si no existe; sigue siendo FK).
- [x] **Retiros**: libres con **50/50 prellenado editable** (mejor que el 50/50 automático del Excel,
      que en la práctica las socias ya pisan a mano). Convergencia mostrada en la view.

## 6. Lo único que falta

Pendientes reales, ordenados por importancia. Nada bloquea el uso de la app.

- [ ] **Usuario real del estudio.** Hoy solo existe el usuario de prueba `lio@bensignor.com`.
      Falta dar de alta el/los usuario(s) reales (Nancy y/o Sol) en Supabase Auth y, si quieren,
      sacar el de prueba. Login es compartido. — *pospuesto por decisión de Lio.*

### Mejoras opcionales (nice-to-have, no bloquean)

- [ ] **Edge Function PDF** (descarga de-un-click sin diálogo de impresión). Hoy el botón
      Exportar usa `window.print()` y alcanza. Requiere Deno + Browserless + API key. Ver §3.
- [ ] **Check de cuadre "debe ser 0"** del Excel: badge/alerta si un saldo queda descuadrado. Ver §4b.

### Decisiones de UI abiertas (esperan confirmación de Lio, no son deuda técnica)

- [ ] **Dirección del cliente en la lista de clientes**: hoy se guarda pero NO se muestra (para no
      saturar la tabla; en la lista se prioriza CUIT). Decisión: dejar oculta — la obra ya tiene su
      propia dirección (`nombre_direccion`). Agregar solo si Nancy la pide.
- [ ] **CUIT/dirección del cliente en el PDF**: el documento muestra Obra + Cliente. No son datos
      internos (están en el Excel). Sugerencia: sumar **CUIT** al PDF (dato fiscal, útil para facturar);
      la dirección no hace falta (el nombre de obra suele ser la dirección). Hacer solo si lo piden.
