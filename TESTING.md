# Testeo de la app

## Dato de prueba cargado

La única obra en la DB es **Ramsay 1945** (cliente Eli), cargada desde
`MODELO PRESUPUESTO.xlsx` con `supabase/seed_ramsay.sql`. Tiene:

- 44 ítems de presupuesto (rubros y proveedores reales del Excel)
- 63 proveedores en 31 rubros
- 9 cobros del cliente
- 27 pagos a proveedor
- 2 retiros de las socias

Con estos datos el **Control da 0** (ver migración `014_control_alinear_excel`).

## Cómo testear

1. Levantar el server: `pnpm dev` → http://localhost:3000
2. Loguearse y abrir la obra Ramsay 1945.
3. Verificar el bloque **Control** arriba: fila "Control" en verde = `$ 0`.

### Qué revisar de los pedidos del cliente

- **Cobro en USD → pesos**: Caja → Registrar movimiento → tipo "Cobro",
  toggle a `US$`, cargar monto + valor dólar. Debe mostrar el equivalente
  en pesos en vivo (`= $ ...`) y al guardar la fila muestra USD + su
  equivalente en ARS debajo.
- **Esos pesos sirven para pagar proveedor**: el cobro en USD suma al
  "Saldo en caja" en pesos; un pago a proveedor lo descuenta.
- **Control = 0**: las cuentas cierran.

## El Control y por qué puede dar ≠ 0

El Control replica la fórmula del Excel:

```
saldo_a_cobrar + saldo_caja - deuda_a_pagar - honorarios_a_retirar = 0
```

- `saldo_a_cobrar` = total facturado − lo cobrado al cliente
- `saldo_caja` = cobros − pagos − retiros
- `deuda_a_pagar` = lo presupuestado a proveedores − lo ya pagado (lo que **falta** pagar)
- `honorarios_a_retirar` = ganancia total − lo ya retirado (lo que **falta** retirar)

**Cierra en 0 solo si los datos son coherentes.** Si cargás un cobro de
prueba suelto sin su contraparte (pago/retiro), el Control se descuadra a
propósito — esa es su función: avisar que falta registrar algo. No es un bug.

## Para recargar el dato de prueba desde cero

Correr `supabase/seed_ramsay.sql` en el SQL Editor de Supabase. Borra todas
las obras y deja solo Ramsay 1945.
