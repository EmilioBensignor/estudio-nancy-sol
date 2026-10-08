-- Ítems apagados: aparecen en el presupuesto pero no suman (pedido del estudio: listar
-- tareas sin valorizar y cargar el valor en un solo ítem del rubro). Todas las columnas
-- *_ars se multiplican por incluido::int, así totales, Control, convergencia y deuda de
-- proveedores los ignoran sin tocar las otras views. Los valores crudos se conservan.
alter table presupuesto_items add column if not exists incluido boolean not null default true;

create or replace view v_presupuesto_items with (security_invoker = on) as
select
  pi.id,
  pi.obra_id,
  pi.fecha,
  pi.proveedor_id,
  pi.rubro_id,
  pi.detalle,
  pi.valor_proveedor,
  pi.moneda_proveedor,
  pi.tc_proveedor,
  pi.valor_presupuesto,
  pi.moneda,
  pi.tc_item,
  pi.valor_final,
  pi.notas,
  pi.created_at,
  obra.honorario_override,
  obra.tipo_cambio_fallback,
  t.tc_item_efectivo,
  t.tc_proveedor_efectivo,
  pi.valor_proveedor * t.tc_proveedor_efectivo * t.f as valor_proveedor_ars,
  pi.valor_presupuesto * t.tc_item_efectivo * t.f as valor_presupuesto_ars,
  pi.valor_final * t.tc_item_efectivo * t.f as valor_final_ars,
  pi.valor_final * t.tc_item_efectivo * t.hon * t.f as honorario_ars,
  pi.valor_final * t.tc_item_efectivo * (1 + t.hon) * t.f as total_ars,
  (pi.valor_final * t.tc_item_efectivo * (1 + t.hon) - pi.valor_proveedor * t.tc_proveedor_efectivo) * t.f as ganancia_ars,
  (pi.valor_presupuesto * t.tc_item_efectivo - pi.valor_proveedor * t.tc_proveedor_efectivo) * t.f as adicional_ars,
  pi.incluido
from presupuesto_items pi
join obras obra on obra.id = pi.obra_id
cross join settings sett
cross join lateral (
  select
    case when pi.moneda = 'ARS' then 1::numeric
      else coalesce(nullif(pi.tc_item, 0), obra.tipo_cambio_fallback) end as tc_item_efectivo,
    case when pi.moneda_proveedor = 'ARS' then 1::numeric
      else coalesce(nullif(pi.tc_proveedor, 0), obra.tipo_cambio_fallback) end as tc_proveedor_efectivo,
    coalesce(obra.honorario_override, sett.honorario_default) as hon,
    pi.incluido::int as f
) t;
