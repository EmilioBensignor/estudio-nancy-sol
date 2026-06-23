-- Alinea el Control con el Excel (MODELO PRESUPUESTO, hoja Caja filas 170-175).
-- Identidad que cierra en 0:
--   saldo_a_cobrar + saldo_caja - deuda_a_pagar - honorarios_a_retirar = 0
-- Cambios vs version anterior de v_control_obra:
--   * deuda_proveedores: ahora es lo que FALTA pagar (presupuestado - pagado), no lo pagado.
--   * honorarios_a_retirar: lo que FALTA retirar (ganancia total - retiros).
--   * adicionales: queda informativa, NO suma al control (ya esta dentro del valor a cobrar).
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
  -- adicionales: informativo, ya incluido en el valor a cobrar
  coalesce((select sum(adicional_ars) from v_presupuesto_items where obra_id = o.id), 0) as adicionales,
  -- honorarios a retirar = ganancia total - lo ya retirado
  -(
    coalesce((select total_ganancia_ars from v_obra_totales where obra_id = o.id), 0)
    - coalesce((select sum((monto_nancy + monto_sol) * tipo_cambio) from retiros where obra_id = o.id), 0)
  ) as honorarios_a_retirar,
  -- control: debe dar 0
  coalesce(s.saldo_a_cobrar_ars, 0)
    + coalesce(s.saldo_caja_ars, 0)
    - (
        coalesce((select sum(total_costo_ars) from v_obra_totales where obra_id = o.id), 0)
        - coalesce((select sum(-monto_ars) from v_caja_saldo where obra_id = o.id and tipo = 'pago_proveedor'), 0)
      )
    - (
        coalesce((select total_ganancia_ars from v_obra_totales where obra_id = o.id), 0)
        - coalesce((select sum((monto_nancy + monto_sol) * tipo_cambio) from retiros where obra_id = o.id), 0)
      ) as control
from obras o
left join v_saldos_obra s on s.obra_id = o.id;
