# Plan — App "Estudio Nancy Sol" (reemplazo del Excel de obras)

> Estado: **brainstorming cerrado, pre-spec**. Próximo paso del flujo: cerrar 2 decisiones
> pendientes → escribir spec HTML en `docs/specs/` → CHECKPOINT de aprobación → migraciones → app.
> Este archivo es el handoff entre sesiones. Todo lo de acá está anclado al Excel real, no a suposiciones.

---

## 0. Contexto del proyecto

- **Cliente**: estudio de dirección de obra (reformas/construcción), dos socias: **Nancy** y **Sol**.
  (Confirmado en el Excel: columnas de retiros se llaman `NANCY` y `SOL`, mails
  `bensignornancy@gmail.com` y `solrutenberg@gmail.com`.)
- **Hoy**: gestionan cada obra en un Excel frágil (`MODELO PRESUPUESTO.xlsx`, en la raíz del repo).
  Fórmulas copiadas a mano, referencias por posición, celdas `#REF!` ya rotas (confirmado:
  `definedNames` todos en `#REF!`, y `T6` de Caja apunta a `#REF!`).
- **Objetivo**: app interna, simple, mantenible, confidencial, que reemplaza el Excel y **no se
  rompe nunca al crecer** (agregar ítems, obras, proveedores). Las "fórmulas" pasan a generated
  columns / views de Postgres → se recalculan solas.
- **Stack**: Nuxt 4 + Vue 3 (Composition API, `<script setup>`, **JS no TS**) + Tailwind +
  Supabase + Vercel. SSR-safe. Comentarios en español. Orden de clases Tailwind del proyecto
  (ver CLAUDE.md global). NO usar prettier-plugin-tailwindcss.
- **Repo actual**: vacío salvo `MODELO PRESUPUESTO.xlsx`. NO es git todavía. Sin `package.json`.

---

## 1. Estructura real del Excel (analizada, fuente de verdad)

3 hojas que son un modelo relacional encubierto:

### Hoja `Data`
Dos tablas apiladas:
- **Clientes**: Nombre completo, Sobrenombre, Teléfono, Dirección de la obra, CUIT.
- **Proveedores**: Nombre, Sobrenombre, Teléfono, **Rubro**, CUIT.
  Rubros reales encontrados (lista para seed / enum sugerido):
  `ALBAÑILERIA, VOLQUETE, MATERIALES, ELECTRODOMESTICOS, ART. SANIT, REVESTIMIENTOS,
  INST. AA, CARP. MADERA, CARP. ALUMINIO, CARP. PVC, INST.SANIT Y GAS, INST. ELECTRICA,
  ART. ILUMINACION, MARMOLERIA, VARIOS, FLETES, PAISAJISMO, DURLOCK, PULIDO E HIDRO,
  YESERIA, VIDRIOS, IMPERM. TAPICERIA, PINTURA, MOBILIARIO, HERRERIA, TAPICERIA,
  FLETE - EMBALAJE, EMBALAJE, CALEFACCION, REP. CORT ENROLLAR`.
  → Rubro como tabla `rubros` (catálogo editable), NO enum hardcodeado. Permite agregar sin migración.

### Hoja `Presupuesto` (fórmulas confirmadas celda por celda)
Encabezado: Cliente + Obra (refs a Data). `J5 = 0.15` es el honorario (vive en celda → va a settings).
Columnas y su fórmula REAL:

| Col | Nombre Excel | Fórmula real | Destino en DB |
|-----|-------------|--------------|---------------|
| A | control | `=K - D - C` → **siempre 0** | **desaparece** (es K−D−(K−D)) |
| B | fecha | serial Excel (ej. 46007) | `fecha` date |
| C | ganancia | `=K - D` (total − valor_proveedor) | **generated/view** `ganancia` [INTERNO] |
| D | valor_proveedor | a mano | `valor_proveedor` numeric [INTERNO] |
| E | proveedor | `=Data!A{n}` | FK `proveedor_id` [INTERNO] |
| F | item / rubro | `=Data!D{n}` o texto | `rubro` (FK a rubros o texto) |
| G | detalle | texto libre | `detalle` text |
| H | valor_presupuesto | `=D * 1.21` (default, **se pisa a mano**) | `valor_presupuesto` numeric |
| I | valor_final | `=H` (default, **se pisa a mano**, ej. descuento) | `valor_final` numeric |
| J | honorario | `=I * $J$5` (=I*0.15) | **generated/view** |
| K | total | `=I + J` | **generated/view** |
| L | notas | texto | `notas` text [INTERNO] |
| M | adicional | `=H - D` | **generated/view** [INTERNO] |

Observaciones críticas:
- `valor_presupuesto` y `valor_final` se **pisan a mano** seguido (R13/R15: descuentos).
  Por eso NO pueden ser generated columns puras: son inputs con default sugerido. El default
  `D*1.21` y `H` se calcula en la UI al crear el ítem, pero queda editable. En DB son columnas normales.
- Solo `ganancia (C)`, `honorario (J)`, `total (K)`, `adicional (M)` son derivadas puras → generated/view.
- Items en **USD y ARS mezclados** (detalles dicen "usd 13.658", "usd 21.190", "usd 29.500",
  "usd 23.600"). La bimoneda es real desde el día 1.
- Paginado a mano "HOJA 1 / HOJA 2" → irrelevante en DB (es paginación de impresión).

### Hoja `Caja` (1096 filas, fórmulas confirmadas)
- **Cobros al cliente** = `Presupuesto!K` (total).
- **Pagos a proveedores** = `-Presupuesto!D` (valor_proveedor en negativo).
- **Matriz de ~86 columnas** (I..AL+) que pivotea pagos por proveedor → **es un REPORTE, no datos**.
  Ya tiene un `#REF!` roto (T6). → En DB es una **VIEW pivot**, jamás columnas que se cargan.
- **Retiros**: columnas `NANCY`, `SOL`, `DE C/COBRO`, `ACUMULADO` + label
  "Control Debe ser 0 o revisar". → tabla `retiros` + view de convergencia.
- **Bimoneda explícita en Caja**: columnas `U$S`, `Cambio`, `Pesos equival` → cada transacción
  guarda moneda + tipo de cambio. También `Efectivo` / `Transfer` → **medio de pago** se trackea.
- Labels de saldos: "Saldo a Cobrar", "Pagado", "Deuda a Proveedores", "Saldo en Caja",
  **"Saldo de Honorarios a retirar"** → todas son VIEWS.

---

## 2. Reglas de negocio (confirmadas con cliente)

### 2.1 Bimoneda — DECISIÓN CERRADA
- **Almacenamiento**: SIEMPRE monto en moneda nativa (ARS/USD) **+ tipo de cambio de esa
  transacción**. Nunca persistir solo el ARS convertido.
- **Consolidación**: moneda base = **ARS** (es lo que hace el Excel "Pesos equival" y lo que
  firma el cliente). Va en `settings` (default ARS) por si en el futuro quieren USD.
- Cada transacción (cobro/pago/retiro) y cada ítem en USD lleva su TC. Fallback: TC manual por obra
  (`obras.tipo_cambio_fallback`) cuando la transacción no trae uno.
- Vista en USD = toggle gratis, porque guardamos montos nativos.
- Regla anti-bug: **nunca sumar cross-moneda sin convertir primero a ARS vía el TC correspondiente.**
  Documentar en el spec dónde y cuándo se convierte, antes de codear sumas.

### 2.2 Honorario
- 15% sobre `valor_final`. Default `0.15` en `settings`. Override por obra (`obras.honorario_override`).
- No hardcodear nunca.

### 2.3 Retiros — DECISIÓN CERRADA (refinada por cliente)
- NO es 50/50 por cobro. Cada retiro registra `monto_nancy` y `monto_sol` libres (desiguales),
  con moneda + TC + fecha. El **acumulado debe converger a 50/50** al final de la obra.
- **Bolsa de la que salen los retiros** = **GANANCIA COBRADA ACUMULADA**, no el honorario solo:
  - Ganancia del estudio = `honorario + adicional` (spread cuando `valor_final > valor_proveedor`).
    La columna `ganancia (C = K − D)` del Excel ya captura esto correctamente. En la mayoría de
    ítems `valor_final = costo` → ganancia = honorario, pero el modelo DEBE incluir el spread.
  - **Base caja, no devengado**: solo cuenta la ganancia de cobros EFECTIVAMENTE recibidos.
    `disponible_para_retirar = ganancia_cobrada_acumulada − retiros_ya_hechos`.
  - El tope es un **WARNING, no bloqueo duro**. Mostrar "disponible para retirar: $X"; si se pasan,
    avisar pero **permitir override**. No frenar con error.
- View de convergencia: acumulado por socia + diferencia vs. target 50/50 ("cuánto falta emparejar
  en el próximo retiro"). Reemplaza la vieja columna "control / debe ser 0".
- `target_reparto` (default 50/50) en `settings`, override por obra (`obras.split_override`).
- **Saldo de caja total** (cobros − pagos − retiros) sigue existiendo como vista APARTE.
  "Honorario/ganancia disponible" es otra lente encima, no lo reemplaza.

> ⚠️ Implicancia de esquema de 2.1 + 2.3: "ganancia cobrada" requiere saber qué porción de cada
> cobro es ganancia. Ver decisión pendiente **D1** abajo.

### 2.4 Confidencialidad / acceso
- 100% interno: solo las dos socias. Auth: **admin compartido** (un solo login, sin roles).
  NO rol cliente, NO login de cliente.
- El cliente SOLO existe como destinatario del **export** del presupuesto: columnas **F a K**
  (item/rubro, detalle, valor_presupuesto, valor_final, honorario, total) + encabezado obra/cliente.
- Campos [INTERNO] (valor_proveedor/costo, proveedor, ganancia, notas, adicional) **NUNCA** salen
  en el export, **ni siquiera en metadata** del PDF/HTML.

---

## 3. Modelo de datos propuesto (Supabase / Postgres)

> Ajustado al Excel real. FKs por todos lados, cero referencia por posición.

```
settings            (singleton global, editable)
  honorario_default        numeric  default 0.15
  target_reparto_nancy     numeric  default 0.50
  target_reparto_sol       numeric  default 0.50
  moneda_base              text     default 'ARS'
  -- (tipo_cambio_fallback NO es global: vive por obra)

rubros              (catálogo editable, seed con los ~30 rubros reales)
  id, nombre

clientes
  id, nombre, sobrenombre, telefono, email, cuit, created_at

proveedores
  id, nombre, sobrenombre, telefono, rubro_id (FK rubros), cuit, created_at

obras
  id, cliente_id (FK), nombre_direccion, fecha_inicio, estado,
  honorario_override        numeric null   -- null = usa settings
  split_nancy_override      numeric null
  split_sol_override        numeric null
  tipo_cambio_fallback      numeric null    -- TC ARS/USD por defecto de la obra
  created_at

presupuesto_items
  id, obra_id (FK), fecha,
  proveedor_id (FK) null,
  rubro_id (FK) null,          -- o texto libre; ver Excel col F (a veces Data!D, a veces texto)
  detalle text,
  valor_proveedor   numeric,   moneda_proveedor text,   tc_proveedor numeric null  [INTERNO]
  valor_presupuesto numeric,                                                -- default D*1.21 en UI
  valor_final       numeric,   moneda text,             tc_item numeric null  -- default = valor_presupuesto en UI
  notas text [INTERNO]
  -- DERIVADAS (generated columns donde se pueda; si dependen de settings/obra → VIEW):
  --   ganancia  = total - valor_proveedor          [INTERNO]
  --   honorario = valor_final * honorario_efectivo  (override obra ?? settings)
  --   total     = valor_final + honorario
  --   adicional = valor_presupuesto - valor_proveedor [INTERNO]

movimientos_caja
  id, obra_id (FK), tipo text check in ('cobro_cliente','pago_proveedor','retiro'),
  proveedor_id (FK) null,     -- solo para pago_proveedor
  presupuesto_item_id (FK) null,  -- ver decisión D1: linkear cobro/pago al ítem
  monto numeric,              -- positivo cobro, negativo pago (o signo por tipo; decidir en spec)
  moneda text,  tipo_cambio numeric,  -- TC de ESTA transacción
  medio_pago text null check in ('efectivo','transferencia') null,  -- visto en Excel
  fecha date, created_at

retiros
  id, obra_id (FK), fecha,
  monto_nancy numeric, monto_sol numeric,   -- libres, desiguales
  moneda text, tipo_cambio numeric, created_at
```

### Generated columns vs. views — criterio
- **Generated column** solo si depende de columnas de la MISMA fila y constantes.
  `total`, `adicional` de un ítem podrían serlo si el honorario fuera constante de fila.
- Pero `honorario` depende de `honorario_override` de la obra → **NO** es de la misma fila →
  va en **VIEW** (`v_presupuesto_items` que joinea obra+settings y expone ganancia/honorario/total/adicional).
  → Decisión: dejar `presupuesto_items` con solo inputs; toda la aritmética en `v_presupuesto_items`.
  Más limpio y respeta "override por obra" sin duplicar el % en cada fila.

### Views (las "fórmulas" del Excel, recalculadas solas)
1. `v_presupuesto_items` — ítems + ganancia/honorario/total/adicional + montos convertidos a ARS.
2. `v_obra_totales` — por obra: total presupuesto, total final, total honorarios, total ganancia,
   total costo proveedores (en ARS y USD).
3. `v_caja_saldo` — running balance por obra con window function (cobros − pagos − retiros),
   en ARS y USD. Reemplaza "Saldo en Caja".
4. `v_pagos_por_proveedor` — el pivot de las 86 columnas, como agregación. Reemplaza la matriz rota.
5. `v_saldos_obra` — "Saldo a Cobrar del Cliente", "Deuda a Proveedores", "Pagado". (labels del Excel)
6. `v_ganancia_cobrada` — ganancia atribuible a los cobros efectivamente recibidos (base caja).
   Depende de D1.
7. `v_retiros_convergencia` — acumulado Nancy/Sol + diferencia vs target + `disponible_para_retirar`
   (= v_ganancia_cobrada − retiros acumulados). El "control debe ser 0".

### Grants (regla global CLAUDE.md)
Toda tabla nueva en `public` debe incluir GRANT explícito. Como es app con login compartido
(authenticated), grants a `authenticated` + `service_role`. `anon` NO (nada público; el export
se genera server-side o tras login). RLS habilitado; policy simple "authenticated puede todo"
(es admin compartido de 2 personas).

---

## 4. Decisiones PENDIENTES (cerrar al inicio de la próxima sesión)

### D1 — Atribución cobro→ganancia (base caja para retiros) ⚠️ CAMBIA EL ESQUEMA
La bolsa de retiros = "ganancia COBRADA acumulada". Pero un cobro al cliente puede ser parcial
(seña, avance). ¿Cómo sé qué ganancia entró con cada cobro?
- **Opción A (proporcional)**: ganancia cobrada = `total_cobrado_obra / total_presupuesto_obra ×
  ganancia_total_obra`. Simple, no necesita linkear cobros a ítems. Asume que cada peso cobrado
  trae su parte proporcional de ganancia. **Recomendada** (los cobros en el Excel no se linkean a ítem).
- **Opción B (por ítem)**: cada cobro se linkea a un `presupuesto_item_id`; la ganancia entra cuando
  se cobra ese ítem. Más preciso pero exige que carguen la relación cobro↔ítem (fricción para usuarias
  no técnicas, y el Excel no lo hace así).
→ Si A: `movimientos_caja.presupuesto_item_id` se puede omitir. Si B: es obligatorio para cobros.

### D2 — `rubro` en presupuesto_items: ¿FK estricta o texto libre?
En el Excel a veces es `=Data!D{n}` (ref al rubro del proveedor) y a veces texto suelto.
- **Opción A**: `rubro_id` FK a `rubros`, nullable; si no hay proveedor, eligen rubro de la lista.
  Consistente, reportable. **Recomendada.**
- **Opción B**: texto libre además del FK (campo `rubro_texto`) para casos sueltos.
→ Afecta si `presupuesto_items` tiene `rubro_id`, `rubro_texto`, o ambos.

(El resto de ambigüedades menores se resuelven con criterio dentro del spec, sin checkpoint.)

---

## 5. Orden de trabajo

### PASO 1 — Spec HTML (ÚNICO CHECKPOINT) ⛔
- Cerrar D1 y D2.
- Escribir spec en `docs/specs/YYYY-MM-DD-modelo-datos-estudio-nancysol.html` (HTML versionado).
- Incluir: diagrama de tablas, FKs, qué es generated vs view, manejo bimoneda (dónde/cuándo convierte),
  las 7 views con su SQL conceptual, plan de migraciones, mapeo Excel→DB (la tabla de §1).
- **PARAR y mostrar para aprobación.** Después seguir de corrido sin más checkpoints.

### PASO 2 — Migraciones Supabase
- Proyecto Supabase: **NO está en el mapa de CLAUDE.md** (orgs listadas no incluyen este estudio).
  → Preguntar qué proyecto/org usar o crear uno nuevo antes de cualquier `apply_migration`.
- Migraciones SQL idempotentes. Reglas de negocio en `settings` + overrides por obra, nunca hardcode.
- GRANT explícito en cada tabla (regla global).
- Seed: obra mockup **"Ramsay 1945"** (cliente "Eli", mails reales del Excel) + proveedores por rubro,
  usando la estructura real de §1. Demuestra sin datos confidenciales reales.

### PASO 3 — App Nuxt
- Scaffold Nuxt 4 + Tailwind + supabase-js. SSR-safe.
- Auth: login compartido (Supabase Auth, un usuario admin para las 2 socias).
- ABM: clientes, proveedores (con rubro), obras. Multi-obra desde día 1: lista + selector de obra.
- **Presupuesto por obra**: tabla editable de ítems. `ganancia/honorario/total/adicional` salen
  de `v_presupuesto_items` → **read-only en UI** (imposible romper un cálculo desde la interfaz).
  `valor_presupuesto` default `D*1.21` y `valor_final` default `=valor_presupuesto`, ambos editables.
  Agregar ítem nunca rompe nada (sin posiciones, todo FK).
- **Caja por obra**: cobros, pagos, retiros. Saldo acumulado en ARS y USD (`v_caja_saldo`).
  Reporte por proveedor = `v_pagos_por_proveedor` (view/pivot, no carga manual).
  Tracker de retiros con indicador de convergencia 50/50 + "disponible para retirar" (warning, no bloqueo).
- **Export imprimible** del presupuesto (PDF/print): SOLO columnas F–K + encabezado obra/cliente.
  Campos [INTERNO] nunca salen, ni en metadata. Generar server-side o componente print-only.

---

## 6. Restricciones no negociables (checklist permanente)
- [ ] Cero fragilidad Excel: cero refs por posición, todo FK. Fórmulas = generated/view, nunca copiadas.
- [ ] UX usuarias NO técnicas: simple, sin jerga, imposible romper un cálculo desde la UI.
- [ ] Reglas de negocio en settings (global) + override por obra. Nada hardcodeado.
- [ ] Auth admin compartido, 2 socias. NO rol cliente.
- [ ] Multi-obra desde día 1.
- [ ] Export F–K: [INTERNO] nunca se filtra, ni en metadata.
- [ ] Nunca sumar cross-moneda sin convertir vía TC. Montos siempre guardados en moneda nativa.
- [ ] Stack: Nuxt 4 + Vue 3 Composition API `<script setup>` JS (no TS) + Tailwind + Supabase + Vercel.
- [ ] SSR-safe (onMounted libs cliente, ClientOnly donde aplique).
- [ ] Comentarios en español. Orden Tailwind del proyecto. NO prettier-plugin-tailwindcss.
- [ ] Specs en HTML versionado en docs/specs/.

---

## 7. Notas de implementación
- Git: el repo NO está inicializado. Confirmar con el usuario antes de `git init` / cualquier git de
  escritura (regla CLAUDE.md: nunca git de escritura sin confirmación explícita).
- Supabase MCP: confirmar proyecto/org (no está en el mapa) antes de migrar contra producción.
- El `MODELO PRESUPUESTO.xlsx` queda como referencia; no se versiona en el export ni se sube a Supabase.
- Fechas del Excel son seriales (46007 ≈ ene-2026); convertir a date real en el seed.
