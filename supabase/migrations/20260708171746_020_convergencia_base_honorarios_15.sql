-- El techo de retiros es el honorario 15% (lo presupuestado), NO la ganancia cobrada.
-- Alinea la convergencia con v_control_obra: honorarios_a_retirar = honorario_15 - retiros.
-- OJO: la columna sigue llamándose ganancia_cobrada_ars pero contiene el honorario 15%.
create or replace view public.v_retiros_convergencia as
select
  r.obra_id,
  sum(r.monto_nancy * r.tipo_cambio) as total_retiros_nancy_ars,
  sum(r.monto_sol * r.tipo_cambio) as total_retiros_sol_ars,
  sum((r.monto_nancy + r.monto_sol) * r.tipo_cambio) as total_retiros_ars,
  h.honorario_15_ars as ganancia_cobrada_ars,
  h.honorario_15_ars * coalesce(o.split_nancy_override, s.target_reparto_nancy) as target_nancy_ars,
  h.honorario_15_ars * coalesce(o.split_sol_override, s.target_reparto_sol) as target_sol_ars,
  sum(r.monto_nancy * r.tipo_cambio) - h.honorario_15_ars * coalesce(o.split_nancy_override, s.target_reparto_nancy) as diferencia_nancy_ars,
  sum(r.monto_sol * r.tipo_cambio) - h.honorario_15_ars * coalesce(o.split_sol_override, s.target_reparto_sol) as diferencia_sol_ars,
  h.honorario_15_ars - sum((r.monto_nancy + r.monto_sol) * r.tipo_cambio) as disponible_para_retirar_ars
from retiros r
  join obras o on o.id = r.obra_id
  cross join settings s
  join lateral (
    select coalesce(sum(pi.honorario_ars), 0) as honorario_15_ars
    from v_presupuesto_items pi
    where pi.obra_id = r.obra_id
  ) h on true
group by r.obra_id, o.split_nancy_override, o.split_sol_override, s.target_reparto_nancy, s.target_reparto_sol, h.honorario_15_ars;

alter view public.v_retiros_convergencia set (security_invoker = on);
