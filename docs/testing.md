# Testeo de la app

## Datos

La base es **producción con obras reales** del estudio (Al Río B, Al Río C, Ohiggins p. 17 y
"Al Río - superado"). No hay base de staging: cualquier prueba se hace sobre datos reales, así que
conviene crear una obra de prueba y borrarla al terminar (se puede borrar solo si está vacía).

`supabase/seed_ramsay.sql` reproduce el Excel original (obra Ramsay 1945, cliente Eli: 44 ítems,
63 proveedores, 9 cobros, 27 pagos, 2 retiros). **Empieza con `delete from obras` y borra todas
las obras, caja, presupuestos y retiros.** Correrlo hoy borraría los datos reales del estudio.
Sirve solo contra una base vacía (por ejemplo, un proyecto Supabase de prueba).

## Cómo testear

1. Levantar el server: `pnpm dev` → http://localhost:3002
2. Loguearse y abrir una obra.
3. Verificar el bloque **Control** arriba: fila "Control" en verde = `$ 0`.

### Qué revisar

- **Cobro en USD → pesos**: Caja → Registrar movimiento → tipo "Cobro", toggle a `US$`, cargar
  monto + valor dólar. Muestra el equivalente en pesos en vivo y al guardar la fila muestra USD +
  su equivalente en ARS.
- **Retiros por obra**: en Configuración, prender o apagar socias (Nancy, Solana, Jessica). El tab
  Retiros muestra solo a las activas (más cualquiera que ya tenga retiros cargados), prellena el
  total según el reparto y avisa cuánto le falta a cada una para emparejar.
- **Vista global `/retiros`**: columnas y totales de las tres socias.
- **Control = 0** después de cargar movimientos coherentes.

## El Control y por qué puede dar ≠ 0

```
saldo_a_cobrar + saldo_caja − deuda_proveedores − honorarios_a_retirar − adicional = 0
```

Detalle de cada término en [modelo-de-datos.md](modelo-de-datos.md). **Cierra en 0 solo si los
datos son coherentes.** Un cobro suelto sin su contraparte descuadra el Control a propósito: avisa
que falta registrar algo. No es un bug.
