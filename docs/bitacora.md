# Bitácora de cambios (con fecha)

Cambios ya aplicados, del más nuevo al más viejo. No es contexto de arranque: se lee cuando el tema vuelve. Las reglas vigentes viven en `CLAUDE.md`.

## Montos con fórmula, estilo Excel (2026-10-28)

Pedido de Nancy: cargar un valor con fórmula y verla al pasar por el renglón, como en el Excel. Los tres casos que nombró: sumarle IVA, unitario por cantidad y sumatoria de varios ítems.

| Se escribe | Da |
|---|---|
| `=1000*1,21` | 1.210 |
| `350x12` | 4.200 |
| `1500+2300+800` | 4.600 |
| `(100+50)*2` | 300 |

**Campos con fórmula**: costo, adicional y valor final del ítem, el valor de cada renglón en "Varios ítems" y el monto del movimiento de caja. El valor del dólar y los retiros siguen siendo número suelto.

- **`app/utils/formula.js`**: parser propio (recursive descent), sin `eval`. Acepta `+ - * / x` y paréntesis, con o sin `=` adelante. `evaluarFormula()` devuelve `NaN` si la fórmula está incompleta (`1000*`), así que las validaciones de "mayor a cero" la rechazan solas.
- **Coma decimal; el punto es de miles solo si agrupa de a 3**: `1.210` = 1210, `1.5` = 1,5, `1.234.567,5` = 1234567,5. Así los valores viejos que vienen de la base como `"1210.5"` se siguen leyendo bien al editar.
- **`MontoField.vue`** se comporta como una celda: con foco muestra la fórmula, sin foco el resultado en terracota (`.field--formula`) y la fórmula en el `title`. Es un `<input>` raíz, así que `class`, `disabled`, `data-varios` y los `@input`/`@keydown` del padre le llegan por fallthrough. Expone `focus()` para el `costoInput` de la carga de corrido.

### Datos (migración 023)

| Tabla | Columnas nuevas |
|---|---|
| `presupuesto_items` | `formula_costo`, `formula_adicional`, `formula_final` |
| `movimientos_caja` | `formula_monto` |

- **Las cuentas no cambian**: se guarda el texto de la fórmula junto al número ya calculado, y las views siguen sumando el número. `null` = se cargó un número suelto.
- `v_presupuesto_items` se recreó con las tres columnas al final, repitiendo `security_invoker = on`.
- Al editar, el form levanta la fórmula si hay (`formula_x ?? String(valor)`).
- En "Varios ítems" la misma fórmula va a `formula_costo` y `formula_final`, porque ese modo guarda costo = presupuesto = final.

### Dónde se ve

| Tabla | Tooltip del renglón |
|---|---|
| Presupuesto | `tituloFormulas()`: una línea por fórmula (costo, adicional, valor final). Si costo y final comparten fórmula, solo la del final |
| Proveedores | `formula_costo` |
| Caja | `formula_monto` |

El PDF del cliente no las muestra: `getPresupuestoCliente` selecciona columnas explícitas y no las incluye.

---

## Varios ítems de corrido y orden de carga (2026-10-27)

Switch **"Varios ítems"** en el form de alta del presupuesto, en la fila del botón. Reemplaza los bloques de costo/adicional/final por una lista de renglones detalle + valor final, todos del mismo rubro y proveedor.

- **Enter** en el detalle pasa al valor; Enter en el valor pasa al renglón siguiente (y lo crea si era el último). El foco se mueve por `data-varios="d0"`/`"v0"`.
- **Un renglón sin valor se guarda apagado** (`incluido: false`): queda como título del grupo ("Dormitorio de mujeres:") sin sumar.
- Cada renglón es un ítem normal con costo = presupuesto = final, en ARS.
- No se muestra al editar, y **editar un ítem apaga el modo** (si no, el form de edición quedaba en modo varios y no tenía los campos del ítem).

**Orden dentro del rubro**: pasó de alfabético por detalle a **orden de carga** (`created_at`), en la tabla y en el PDF. Si no, los títulos de grupo y sus renglones se mezclaban. Por eso `getPresupuestoCliente` ahora trae `created_at`.

**Detalle multilínea**: el detalle del ítem es un `<textarea>` que crece con el texto (`field-sizing: content`, de 88 a 320px). Tabla y PDF lo muestran con `white-space: pre-line`, respetando los saltos de línea.

---

## Rubros editables, Proveedores por ítem y corte de página en PDFs (2026-10-23)

### `/rubros`

Página nueva (botón "Rubros" en la lista de proveedores): búsqueda, renombrar inline y borrar. **Solo se borra un rubro sin usos**: `getRubrosConUsos()` cuenta proveedores + ítems que lo usan y el `ConfirmDialog` lo bloquea con la cantidad.

### Tab Proveedores renglón por ítem

Antes era una fila por proveedor + rubro. Ahora es un renglón por ítem, como el presupuesto, con rubro y proveedor sin repetir (`repite`).

- **Pagado y Debo siguen siendo por proveedor + rubro**: los pagos no tienen ítem, así que van solo en el primer renglón del grupo. Los proveedores con pagos y sin ítems quedan al final con renglón propio.
- Switch **"Comparar con presupuesto"**: suma la columna Valor final al lado de lo presupuestado al proveedor.

### Saldo en el presupuesto

El pie de la tabla del presupuesto suma "Pagado a cuenta" y "Saldo" cuando hay cobros, igual que el PDF desde el 14-10.

### Corte de página en los PDFs

`DocumentoPresupuesto` y `DocumentoReporte` tienen `@page margin 0`, y en la segunda hoja la tabla quedaba pegada al borde.

- **Fila vacía `.doc__page-gap` de 16mm** en `thead` y `tfoot`, que el navegador repite en cada hoja: hace de margen arriba y abajo. En la primera hoja un `margin-top: -16mm` compensa.
- Los totales pasaron de `tfoot` a un `tbody.doc__totales`; si no, se repetían al pie de cada hoja.
- `tr { break-inside: avoid }`: ningún renglón se parte entre hojas.

Subtotales por rubro, en tabla y PDF: dejaron de ser una banda con fondo y mayúsculas. Ahora se leen como una suma, alineados a la derecha junto al monto.

---

## PDF del presupuesto: pagado a cuenta y saldo (2026-10-14)

`DocumentoPresupuesto` recibe `pagado` (los cobros del cliente en ARS, `totalCobros`). Si es mayor a 0, el pie suma **"Pagado a cuenta"** y **"Saldo"** (total − pagado). Sin cobros, el PDF queda como antes.

---

## Ítems apagados (2026-10-08)

Pedido del estudio: listar tareas sin valorizar y cargar el valor en un solo ítem del rubro.

- Columna `presupuesto_items.incluido` (migración 022), con switch en cada renglón y "Suma al subtotal" en el form.
- **`v_presupuesto_items` multiplica todos los `*_ars` por `incluido::int`**. Totales, Control, convergencia y deuda de proveedores los ignoran sin tocar las otras views. Los valores crudos se conservan, así que prender el switch los recupera.
- En la tabla el renglón queda al 45% de opacidad y muestra el valor crudo si tiene, o un guion. En el PDF aparece sin valor.
- Con el switch apagado el valor final puede quedar en 0.

---

## Pantalla completa y zoom del presupuesto (2026-10-02)

- **Pantalla completa**: Fullscreen API sobre el mismo panel (`panelPresupuesto.requestFullscreen()`), así que sigue siendo editable. El estado se sincroniza con `fullscreenchange`, porque Esc sale sin pasar por el botón.
- **Zoom** 50% a 200%, con `zoom` CSS sobre la tabla, como en el Excel. Se recuerda por navegador en `localStorage` (`zoomPresupuesto`), con try/catch.

---

## Búsqueda por inicial, tablas compactas y carga de corrido (2026-10-02)

| Cambio | Detalle |
|---|---|
| Búsqueda por inicial | `app/utils/buscar.js` → `empiezaCon()`: "a" encuentra lo que **empieza** con A, sin tildes ni mayúsculas. En obras, clientes, proveedores, `RubroCombo` y `SelectField` |
| `SelectField` tipeable | Con el select enfocado, tipear filtra las opciones; Enter elige la primera, Backspace borra, Esc cierra. El texto se ve con un cursor terracota |
| Tablas compactas | `.table` a 14px y filas de 6px de padding, para ver más renglones (pedido del estudio). Es la única excepción al mínimo de 16px |
| Rubro y proveedor sin repetir | Si el renglón repite rubro y proveedor del anterior, quedan en blanco y sin borde entre los dos (`row--repite`) |
| Carga de corrido | Después de un alta el form queda abierto con el mismo rubro y proveedor, y el foco en el costo |
