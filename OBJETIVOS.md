# Objetivos de la app — Estudio Nancy Sol

> Este documento traduce el Excel `MODELO PRESUPUESTO.xlsx` en objetivos de la app.
> Nada de acá está inventado: cada objetivo mapea a una hoja o columna real del Excel.
> Sirve para validar con el cliente que entendimos bien cómo trabaja hoy.

## De dónde sale todo

El Excel tiene **3 hojas**, que son en realidad un sistema relacional:

| Hoja Excel | Qué contiene | Se convierte en |
|---|---|---|
| `Data` | Clientes y proveedores (por rubro) | Secciones **Clientes** y **Proveedores** |
| `Presupuesto` | Ítems de una obra: rubro, proveedor, costo, valor final, honorario, total | **Presupuesto** dentro de cada obra |
| `Caja` | Cobros del cliente, pagos a proveedores, retiros, saldos | **Caja** dentro de cada obra |

Cada archivo Excel representa **una obra**. La app gestiona varias obras a la vez.

## Los nombres del estudio

Confirmados en el Excel (mails reales):
- **Nancy Bensignor** — bensignornancy@gmail.com
- **Solana Rutenberg** — solrutenberg@gmail.com

## Objetivos

### 1. Gestionar obras
Dar de alta una obra, verlas todas en una lista, saber su estado (activa / finalizada).
*Excel: cada planilla es una obra.*

### 2. Cargar el presupuesto de cada obra
Cargar los ítems: rubro, proveedor, costo del proveedor, valor presupuesto, valor final,
honorario (15% por defecto) y total. El total y el honorario se calculan solos.
*Excel: hoja `Presupuesto`, columnas A–M.*

### 3. Registrar la caja
Anotar la plata que entra (**cobros del cliente**) y la que sale (**pagos a proveedores**),
y ver el **saldo en caja** actualizado al instante.
*Excel: hoja `Caja` → "Movimiento de cuentas con cliente" y "con proveedores".*

### 4. Registrar retiros y seguir la convergencia 50/50
Anotar cuánto retira Nancy y cuánto Solana (montos libres, pueden ser desiguales),
y ver cuánto falta para emparejar al 50/50 al final de la obra.
*Excel: hoja `Caja` → bloque RETIROS (columnas NANCY, SOL, DE C/COBRO, ACUMULADO)
y el "Control debe ser 0".*

### 5. Ver los saldos de la obra
De un vistazo: cuánto falta cobrar, cuánto se debe a proveedores, saldo en caja,
y honorarios disponibles para retirar.
*Excel: hoja `Caja` → "Saldo a Cobrar del Cliente", "Deuda a Proveedores",
"Saldo en Caja", "Saldo de Honorarios a retirar".*

### 6. Administrar clientes y proveedores
Lista de clientes (nombre, teléfono, dirección, CUIT) y de proveedores
agrupados por rubro (albañilería, sanitarios, carpintería, etc.).
*Excel: hoja `Data`.*

### 7. Exportar el presupuesto para el cliente
Generar un presupuesto limpio e imprimible para mandarle al cliente, que muestre
**solo lo que el cliente debe ver** (rubro, detalle, valores y total) y **nunca**
los costos internos ni la ganancia del estudio.
*Excel: columnas F a K de la hoja `Presupuesto`.*

### 8. Trabajar en pesos y dólares
Cada cobro, pago, retiro o ítem puede estar en ARS o USD, guardando el tipo de cambio
de esa operación. Todo se consolida en pesos.
*Excel: columnas U$S, Cambio, Pesos equival de la hoja `Caja`.*

## Cómo se navega la app

```
              NANCY BENSIGNOR
              SOLANA RUTENBERG
        ──────────────────────────
        Obras    Clientes    Proveedores
```

- **Obras** → lista → click en una obra → su detalle (presupuesto + caja + retiros + saldos)
- **Clientes** → catálogo de clientes
- **Proveedores** → catálogo de proveedores por rubro

El **exportar** vive dentro de cada obra (es una acción, no una sección).

## Qué falta confirmar con el cliente

1. ¿Los retiros salen de la **ganancia cobrada** (lo recibido) o del honorario teórico? *(asumimos: ganancia cobrada, base caja).*
2. ¿El presupuesto se exporta como PDF para imprimir, o alcanza con verlo en pantalla?
3. ¿Quieren ver montos también en dólares con un toggle, o siempre en pesos?
