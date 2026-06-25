-- Fix: v_saldos_obra elegía "el último saldo de caja" ordenando solo por fecha.
-- Con dos movimientos del mismo día el desempate era no-determinista y podía
-- tomar el saldo equivocado (rompía el Control). Se agrega created_at al orden.
-- NOTA: superada por la migration 017 (saldo = suma de movimientos), se deja por trazabilidad.
create or replace view v_saldos_obra as
select
  o.id as obra_id,
  coalesce((select sum(total_general_ars) from v_obra_totales where obra_id = o.id), 0)
    - coalesce((select sum(monto_ars) from v_caja_saldo where obra_id = o.id and tipo = 'cobro_cliente'), 0) as saldo_a_cobrar_ars,
  coalesce((select sum(monto_ars) from v_caja_saldo where obra_id = o.id and tipo = 'pago_proveedor'), 0) as deuda_proveedores_ars,
  coalesce((select sum(monto_ars) from v_caja_saldo where obra_id = o.id and tipo = 'cobro_cliente'), 0) as total_cobrado_ars,
  coalesce((select saldo_acumulado_ars from v_caja_saldo where obra_id = o.id order by fecha desc, created_at desc limit 1), 0) as saldo_caja_ars
from obras o;
