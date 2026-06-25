-- El adicional es una RESERVA (cubre IVA de proveedores grandes), no ganancia de las socias.
-- honorarios_a_retirar = solo el honorario 15% (no la ganancia que incluía el adicional).
-- El adicional pasa de informativo a término que RESTA en el control (reserva guardada).
-- Identidad: saldo_a_cobrar + saldo_caja - deuda - honorarios_15 - adicional = 0
create or replace view v_control_obra as
select
  o.id as obra_id,
  coalesce(s.saldo_a_cobrar_ars, 0) as saldo_a_cobrar,
  coalesce(s.saldo_caja_ars, 0) as saldo_caja,
  -- deuda = lo que falta pagar a proveedores (presupuestado - pagado)
  -(
    coalesce((select sum(total_costo_ars) from v_obra_totales where obra_id = o.id), 0)
    - coalesce((select sum(-monto_ars) from v_caja_saldo where obra_id = o.id and tipo = 'pago_proveedor'), 0)
  ) as deuda_proveedores,
  -- adicional = reserva (resta en el control, no es ganancia)
  -coalesce((select sum(adicional_ars) from v_presupuesto_items where obra_id = o.id), 0) as adicionales,
  -- honorarios a retirar = honorario 15% - lo ya retirado (SIN adicional)
  -(
    coalesce((select sum(honorario_ars) from v_presupuesto_items where obra_id = o.id), 0)
    - coalesce((select sum((monto_nancy + monto_sol) * tipo_cambio) from retiros where obra_id = o.id), 0)
  ) as honorarios_a_retirar,
  -- control: debe dar 0
  coalesce(s.saldo_a_cobrar_ars, 0)
    + coalesce(s.saldo_caja_ars, 0)
    - (
        coalesce((select sum(total_costo_ars) from v_obra_totales where obra_id = o.id), 0)
        - coalesce((select sum(-monto_ars) from v_caja_saldo where obra_id = o.id and tipo = 'pago_proveedor'), 0)
      )
    - coalesce((select sum(adicional_ars) from v_presupuesto_items where obra_id = o.id), 0)
    - (
        coalesce((select sum(honorario_ars) from v_presupuesto_items where obra_id = o.id), 0)
        - coalesce((select sum((monto_nancy + monto_sol) * tipo_cambio) from retiros where obra_id = o.id), 0)
      ) as control
from obras o
left join v_saldos_obra s on s.obra_id = o.id;
