# Modelo de datos

Estado vivo de la base (Supabase `zhnudiedkqlhslebproh`, MCP `supabase-nancy`) al 22/09/2026.
Toda la aritmética contable vive en views de Postgres: el front lee resultados, no calcula saldos.
El historial completo está en `supabase/migrations/` (22 archivos, mismas versiones que la base).

## Tablas

| Tabla | Qué guarda | Columnas clave |
|---|---|---|
| `settings` | Singleton de configuración | `honorario_default` 0.15, `target_reparto_nancy/sol` 0.50 |
| `rubros` | Catálogo editable (se crea al vuelo desde `RubroCombo`) | `nombre` único |
| `clientes` | Hoja Data del Excel | `nombre`, `sobrenombre`, `telefono`, `email`, `cuit` |
| `proveedores` | Hoja Data del Excel | `nombre`, `rubro_id` (FK), `cuit` |
| `obras` | Una por Excel | `slug` único, `estado`, `honorario_override`, `retira_*`, `split_*_override`, `tipo_cambio_fallback` |
| `presupuesto_items` | Hoja Presupuesto, solo inputs | `valor_proveedor` + `moneda_proveedor` + `tc_proveedor`, `valor_presupuesto`, `valor_final` + `moneda` + `tc_item` |
| `movimientos_caja` | Cobros y pagos | `tipo` (`cobro_cliente`/`pago_proveedor`), `monto` positivo, `moneda`, `tipo_cambio`, `medio_pago` |
| `retiros` | Retiros de las socias | `monto_nancy`, `monto_sol`, `monto_jessica`, `moneda`, `tipo_cambio` |
| `_keepalive` | Ping de un cron para que el proyecto free no se pause | Única tabla con grants a `anon` |

Seguridad: RLS en todas, policy `for all to authenticated using (true)` (login compartido).
`anon` no tiene acceso a nada de negocio (migración 012). Views con `security_invoker = on`.

## Views

| View | Devuelve |
|---|---|
| `v_presupuesto_items` | Ítem + montos en ARS (`valor_*_ars`), `honorario_ars`, `total_ars`, `ganancia_ars`, `adicional_ars` |
| `v_obra_totales` | Sumas por obra: costo, presupuesto, final, honorarios, adicional, total general |
| `v_caja_saldo` | Unión cobros (+), pagos (−) y retiros (−) en ARS con saldo acumulado |
| `v_saldos_obra` | `saldo_a_cobrar_ars`, `total_cobrado_ars`, `saldo_caja_ars` (suma, no "último acumulado") |
| `v_ganancia_cobrada` | Ganancia proporcional a lo cobrado. Ya no la usa la convergencia |
| `v_retiros_convergencia` | Techo de retiros y `disponible_para_retirar_ars` por obra |
| `v_control_obra` | Bloque Control del Excel. Debe dar 0 |
| `v_pagos_por_proveedor` | Total pagado por proveedor y obra |

**Trampa de nombres:** en `v_retiros_convergencia` la columna `ganancia_cobrada_ars` contiene el
**honorario 15% presupuestado**, no la ganancia cobrada (migración 020 del 08/07). Se dejó el nombre
para no romper el front. Las columnas `target_*` y `diferencia_*` de esa view solo conocen a Nancy y
Solana: el front ya no las usa y calcula los objetivos por socia (ver Retiros).

## Reglas contables

- **Montos en moneda nativa + TC de la transacción.** Todo se consolida en ARS multiplicando por
  `tipo_cambio`. USD en caja es siempre efectivo (la UI oculta el medio de pago).
- **Honorario** = `valor_final × honorario` (15% por defecto, override por obra).
- **Total al cliente** = `valor_final × (1 + honorario)`.
- **Adicional** = `valor_presupuesto − valor_proveedor`. Es una reserva (cubre IVA de proveedores
  grandes), no ganancia de las socias.
- **Saldo de caja** = suma de todos los movimientos en ARS (cobros − pagos − retiros).
- **Control** (debe dar 0):
  `saldo_a_cobrar + saldo_caja − deuda_proveedores − honorarios_a_retirar − adicional = 0`, donde
  deuda es lo que falta pagar (presupuestado − pagado) y honorarios a retirar es
  `honorario 15% − retiros hechos`. Si no da 0, falta cargar algo: es un aviso, no un bug.

## Retiros

- Pueden retirar **Nancy, Solana y Jessica**. Cada obra tiene un switch por persona
  (`retira_nancy`, `retira_sol`, `retira_jessica`). Default: Nancy y Solana sí, Jessica no.
- El reparto va en `split_<socia>_override` (fracción, suma 1 entre las activas; 0 para las apagadas).
  Al prender o apagar a alguien en Configuración, el reparto vuelve a quedar parejo y se puede ajustar.
  Si una obra tiene los splits en `null`, el front reparte parejo entre las activas.
- Techo total = honorario 15% de la obra. `disponible = honorario 15% − retiros`. Pasarse es un
  warning, no un bloqueo.
- Objetivo por socia (calculado en el front, `obras/[id]/index.vue`) = `honorario 15% × split`.
  "Para emparejar": la socia que más retiró respecto de su split marca el ritmo; al resto le falta
  `ritmo × split − retirado`.
- Las columnas de retiros siguen el patrón `monto_<key>` con las keys de `app/composables/useSocias.js`.
  Sumar una persona más = columna nueva en `retiros` y `obras`, entrada en `SOCIAS`, y agregar
  su monto a las sumas `monto_nancy + monto_sol + monto_jessica` de las views (la migración 021
  muestra cómo hacerlo con `pg_get_viewdef`).

## Historial de migraciones

| Versión | Qué hizo |
|---|---|
| 001–008 | Tablas base, grants y RLS |
| 009 | Las 7 views originales |
| 010 | Obra demo Ramsay 1945 (el dato completo va en `supabase/seed_ramsay.sql`) |
| 011 | `_keepalive` |
| 012 | Hardening: revoca `anon`, views a security invoker, `search_path` del trigger |
| 013 | CUIT en clientes y proveedores |
| `crear_v_control_obra` | Primera versión del Control |
| 014 | Control alineado al Excel: deuda y honorarios = lo que falta |
| 015 | Borra `clientes.direccion` |
| 016, 017 | Saldo de caja como suma de movimientos |
| 018 | Honorarios a retirar sin adicional; adicional resta en el Control |
| 019 | `obras.slug` para las URLs |
| 020 | Convergencia con techo = honorario 15% |
| 021 (`020_retiros_jessica` en la base) | Jessica, switches por obra, `monto_jessica` en las views |
