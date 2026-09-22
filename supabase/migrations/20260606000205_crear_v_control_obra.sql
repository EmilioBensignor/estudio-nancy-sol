-- Vista de control contable por obra (replica el bloque "Control" del Excel, hoja Caja filas 170-175).
-- Control = Saldo a Cobrar + Saldo en Caja + Deuda a Proveedores(neg) - Adicionales - Honorarios a retirar.
-- Debe dar 0; si no, hay un error de carga (la flag avisa).
-- NOTA: superada por 014 y 018 (fórmula actual del Control).
create or replace view v_control_obra as
select
  o.id as obra_id,
  coalesce(s.saldo_a_cobrar_ars, 0)                                    as saldo_a_cobrar,
  coalesce(s.saldo_caja_ars, 0)                                        as saldo_caja,
  coalesce(s.deuda_proveedores_ars, 0)                                 as deuda_proveedores,
  -- Adicionales: Excel G173 = -Presupuesto!M105 (suma de la columna "Adicional" de los ítems, negada)
  -coalesce((select sum(i.adicional_ars) from v_presupuesto_items i where i.obra_id = o.id), 0)
                                                                       as adicionales,
  -- Honorarios a retirar: el Excel los suma en negativo en el control
  -coalesce(c.disponible_para_retirar_ars, 0)                          as honorarios_a_retirar,
  ( coalesce(s.saldo_a_cobrar_ars, 0)
    + coalesce(s.saldo_caja_ars, 0)
    + coalesce(s.deuda_proveedores_ars, 0)
    - coalesce((select sum(i.adicional_ars) from v_presupuesto_items i where i.obra_id = o.id), 0)
    - coalesce(c.disponible_para_retirar_ars, 0)
  )                                                                    as control
from obras o
left join v_saldos_obra s on s.obra_id = o.id
left join v_retiros_convergencia c on c.obra_id = o.id;

grant select on v_control_obra to anon, authenticated, service_role;
