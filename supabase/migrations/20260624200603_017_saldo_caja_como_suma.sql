-- El saldo de caja es la SUMA de todos los movimientos (cobros - pagos - retiros),
-- no "el último saldo acumulado". Tomar el último por fecha era no-determinista
-- con movimientos del mismo día y rompía el Control. La suma es inmune a empates.
create or replace view v_saldos_obra as
select
  o.id as obra_id,
  coalesce((select sum(total_general_ars) from v_obra_totales where obra_id = o.id), 0)
    - coalesce((select sum(monto_ars) from v_caja_saldo where obra_id = o.id and tipo = 'cobro_cliente'), 0) as saldo_a_cobrar_ars,
  coalesce((select sum(monto_ars) from v_caja_saldo where obra_id = o.id and tipo = 'pago_proveedor'), 0) as deuda_proveedores_ars,
  coalesce((select sum(monto_ars) from v_caja_saldo where obra_id = o.id and tipo = 'cobro_cliente'), 0) as total_cobrado_ars,
  coalesce((select sum(monto_ars) from v_caja_saldo where obra_id = o.id), 0) as saldo_caja_ars
from obras o;
