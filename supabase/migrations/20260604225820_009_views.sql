-- 009_views.sql (corregido: fecha en v_caja_saldo, created_at en UNION)

-- 3.1 v_presupuesto_items
create or replace view public.v_presupuesto_items as
SELECT
  pi.*,
  obra.honorario_override,
  obra.tipo_cambio_fallback,
  CASE
    WHEN pi.moneda = 'ARS' THEN 1
    ELSE COALESCE(NULLIF(pi.tc_item, 0), obra.tipo_cambio_fallback)
  END AS tc_item_efectivo,
  CASE
    WHEN pi.moneda_proveedor = 'ARS' THEN 1
    ELSE COALESCE(NULLIF(pi.tc_proveedor, 0), obra.tipo_cambio_fallback)
  END AS tc_proveedor_efectivo,
  (pi.valor_proveedor * CASE WHEN pi.moneda_proveedor = 'ARS' THEN 1 ELSE COALESCE(NULLIF(pi.tc_proveedor, 0), obra.tipo_cambio_fallback) END) AS valor_proveedor_ars,
  (pi.valor_presupuesto * CASE WHEN pi.moneda = 'ARS' THEN 1 ELSE COALESCE(NULLIF(pi.tc_item, 0), obra.tipo_cambio_fallback) END) AS valor_presupuesto_ars,
  (pi.valor_final * CASE WHEN pi.moneda = 'ARS' THEN 1 ELSE COALESCE(NULLIF(pi.tc_item, 0), obra.tipo_cambio_fallback) END) AS valor_final_ars,
  (pi.valor_final * CASE WHEN pi.moneda = 'ARS' THEN 1 ELSE COALESCE(NULLIF(pi.tc_item, 0), obra.tipo_cambio_fallback) END * COALESCE(obra.honorario_override, sett.honorario_default)) AS honorario_ars,
  (pi.valor_final * CASE WHEN pi.moneda = 'ARS' THEN 1 ELSE COALESCE(NULLIF(pi.tc_item, 0), obra.tipo_cambio_fallback) END * (1 + COALESCE(obra.honorario_override, sett.honorario_default))) AS total_ars,
  (pi.valor_final * CASE WHEN pi.moneda = 'ARS' THEN 1 ELSE COALESCE(NULLIF(pi.tc_item, 0), obra.tipo_cambio_fallback) END * (1 + COALESCE(obra.honorario_override, sett.honorario_default))
   - pi.valor_proveedor * CASE WHEN pi.moneda_proveedor = 'ARS' THEN 1 ELSE COALESCE(NULLIF(pi.tc_proveedor, 0), obra.tipo_cambio_fallback) END) AS ganancia_ars,
  ((pi.valor_presupuesto * CASE WHEN pi.moneda = 'ARS' THEN 1 ELSE COALESCE(NULLIF(pi.tc_item, 0), obra.tipo_cambio_fallback) END)
   - pi.valor_proveedor * CASE WHEN pi.moneda_proveedor = 'ARS' THEN 1 ELSE COALESCE(NULLIF(pi.tc_proveedor, 0), obra.tipo_cambio_fallback) END) AS adicional_ars
FROM presupuesto_items pi
JOIN obras obra ON obra.id = pi.obra_id
CROSS JOIN settings sett;

grant select on public.v_presupuesto_items to authenticated;
grant select on public.v_presupuesto_items to service_role;

-- 3.2 v_obra_totales
create or replace view public.v_obra_totales as
SELECT
  obra_id,
  COUNT(*) AS total_items,
  SUM(valor_proveedor_ars) AS total_costo_ars,
  SUM(valor_presupuesto_ars) AS total_presupuesto_ars,
  SUM(valor_final_ars) AS total_final_ars,
  SUM(ganancia_ars) AS total_ganancia_ars,
  SUM(honorario_ars) AS total_honorarios_ars,
  SUM(adicional_ars) AS total_adicional_ars,
  SUM(total_ars) AS total_general_ars,
  SUM(CASE WHEN pi.moneda = 'USD' THEN pi.valor_final ELSE 0 END) AS total_final_usd,
  SUM(CASE WHEN pi.moneda = 'USD' THEN pi.valor_proveedor ELSE 0 END) AS total_costo_usd
FROM v_presupuesto_items pi
GROUP BY obra_id;

grant select on public.v_obra_totales to authenticated;
grant select on public.v_obra_totales to service_role;

-- 3.3 v_caja_saldo (incluye fecha y created_at en el SELECT)
create or replace view public.v_caja_saldo as
WITH caja_union AS (
  SELECT obra_id, id, fecha, created_at, 'cobro_cliente' AS tipo, monto * tipo_cambio AS monto_ars
  FROM movimientos_caja WHERE tipo = 'cobro_cliente'
  UNION ALL
  SELECT obra_id, id, fecha, created_at, 'pago_proveedor' AS tipo, -monto * tipo_cambio AS monto_ars
  FROM movimientos_caja WHERE tipo = 'pago_proveedor'
  UNION ALL
  SELECT r.obra_id, r.id, r.fecha, r.created_at, 'retiro' AS tipo, -(r.monto_nancy + r.monto_sol) * r.tipo_cambio AS monto_ars
  FROM retiros r
)
SELECT
  obra_id, id, tipo, monto_ars, fecha,
  SUM(monto_ars) OVER (PARTITION BY obra_id ORDER BY fecha, created_at
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS saldo_acumulado_ars
FROM caja_union;

grant select on public.v_caja_saldo to authenticated;
grant select on public.v_caja_saldo to service_role;

-- 3.4 v_pagos_por_proveedor
create or replace view public.v_pagos_por_proveedor as
SELECT mc.obra_id, mc.proveedor_id, p.nombre AS nombre_proveedor,
  SUM(mc.monto * mc.tipo_cambio) AS total_pagado_ars
FROM movimientos_caja mc
JOIN proveedores p ON p.id = mc.proveedor_id
WHERE mc.tipo = 'pago_proveedor'
GROUP BY mc.obra_id, mc.proveedor_id, p.nombre;

grant select on public.v_pagos_por_proveedor to authenticated;
grant select on public.v_pagos_por_proveedor to service_role;

-- 3.5 v_saldos_obra
create or replace view public.v_saldos_obra as
SELECT
  o.id AS obra_id,
  COALESCE((SELECT SUM(total_general_ars) FROM v_obra_totales WHERE obra_id = o.id), 0)
    - COALESCE((SELECT SUM(monto_ars) FROM v_caja_saldo WHERE obra_id = o.id AND tipo = 'cobro_cliente'), 0)
    AS saldo_a_cobrar_ars,
  COALESCE((SELECT SUM(monto_ars) FROM v_caja_saldo WHERE obra_id = o.id AND tipo = 'pago_proveedor'), 0)
    AS deuda_proveedores_ars,
  COALESCE((SELECT SUM(monto_ars) FROM v_caja_saldo WHERE obra_id = o.id AND tipo = 'cobro_cliente'), 0)
    AS total_cobrado_ars,
  COALESCE((SELECT saldo_acumulado_ars FROM v_caja_saldo WHERE obra_id = o.id ORDER BY fecha DESC LIMIT 1), 0)
    AS saldo_caja_ars
FROM obras o;

grant select on public.v_saldos_obra to authenticated;
grant select on public.v_saldos_obra to service_role;

-- 3.6 v_ganancia_cobrada
create or replace view public.v_ganancia_cobrada as
SELECT
  ot.obra_id,
  COALESCE((SELECT SUM(monto_ars) FROM v_caja_saldo WHERE obra_id = ot.obra_id AND tipo = 'cobro_cliente'), 0)
    AS total_cobrado_ars,
  ot.total_general_ars AS total_facturado_ars,
  ot.total_ganancia_ars,
  CASE WHEN ot.total_general_ars > 0
    THEN (
      COALESCE((SELECT SUM(monto_ars) FROM v_caja_saldo WHERE obra_id = ot.obra_id AND tipo = 'cobro_cliente'), 0)
      / ot.total_general_ars
    ) * ot.total_ganancia_ars
    ELSE 0
  END AS ganancia_cobrada_ars
FROM v_obra_totales ot;

grant select on public.v_ganancia_cobrada to authenticated;
grant select on public.v_ganancia_cobrada to service_role;

-- 3.7 v_retiros_convergencia
create or replace view public.v_retiros_convergencia as
SELECT
  r.obra_id,
  SUM(r.monto_nancy * r.tipo_cambio) AS total_retiros_nancy_ars,
  SUM(r.monto_sol * r.tipo_cambio) AS total_retiros_sol_ars,
  SUM((r.monto_nancy + r.monto_sol) * r.tipo_cambio) AS total_retiros_ars,
  gc.ganancia_cobrada_ars,
  gc.ganancia_cobrada_ars * COALESCE(o.split_nancy_override, s.target_reparto_nancy) AS target_nancy_ars,
  gc.ganancia_cobrada_ars * COALESCE(o.split_sol_override, s.target_reparto_sol) AS target_sol_ars,
  SUM(r.monto_nancy * r.tipo_cambio) - (gc.ganancia_cobrada_ars * COALESCE(o.split_nancy_override, s.target_reparto_nancy)) AS diferencia_nancy_ars,
  SUM(r.monto_sol * r.tipo_cambio) - (gc.ganancia_cobrada_ars * COALESCE(o.split_sol_override, s.target_reparto_sol)) AS diferencia_sol_ars,
  gc.ganancia_cobrada_ars - SUM((r.monto_nancy + r.monto_sol) * r.tipo_cambio) AS disponible_para_retirar_ars
FROM retiros r
JOIN obras o ON o.id = r.obra_id
CROSS JOIN settings s
JOIN v_ganancia_cobrada gc ON gc.obra_id = r.obra_id
GROUP BY r.obra_id, o.split_nancy_override, o.split_sol_override,
         s.target_reparto_nancy, s.target_reparto_sol, gc.ganancia_cobrada_ars;

grant select on public.v_retiros_convergencia to authenticated;
grant select on public.v_retiros_convergencia to service_role;
