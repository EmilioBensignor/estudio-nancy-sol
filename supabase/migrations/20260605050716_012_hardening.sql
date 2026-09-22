-- 012_hardening — Endurecimiento de seguridad post-auditoría (2026-06-05)
--
-- Corrige 3 hallazgos de la auditoría sobre el esquema ya aplicado (001–010):
--   1. Grants de INSERT/UPDATE/DELETE a `anon` en las 8 tablas de negocio.
--      Regla del CLAUDE.md global: `anon` NO se incluye salvo acceso público real.
--      La app es 100% interna (login compartido) → `anon` no debe poder escribir.
--   2. Las 7 views se crearon como SECURITY DEFINER (saltean RLS del usuario).
--      Supabase lo marca como ERROR. Se pasan a SECURITY INVOKER.
--   3. La función del trigger tiene search_path mutable (WARN). Se fija.
--
-- NO toca `_keepalive`: esa tabla SÍ necesita `anon` (la escribe un cron sin login
-- para evitar que el proyecto free se pause). Su exposición es nula (tabla vacía).

-- ── 1. Revocar grants de anon en las tablas de negocio ──────────────────────
-- Quita todo privilegio de anon. authenticated y service_role quedan intactos,
-- así que crear-rubro-al-vuelo (insert en rubros desde el cliente logueado) sigue ok.
revoke all on public.settings          from anon;
revoke all on public.rubros            from anon;
revoke all on public.clientes          from anon;
revoke all on public.proveedores       from anon;
revoke all on public.obras             from anon;
revoke all on public.presupuesto_items from anon;
revoke all on public.movimientos_caja  from anon;
revoke all on public.retiros           from anon;

-- ── 2. Views a SECURITY INVOKER ─────────────────────────────────────────────
-- security_invoker = on hace que la view corra con permisos+RLS del que consulta,
-- no del creador. No cambia la lógica de la view. Requiere Postgres 15+.
alter view public.v_presupuesto_items   set (security_invoker = on);
alter view public.v_obra_totales         set (security_invoker = on);
alter view public.v_caja_saldo           set (security_invoker = on);
alter view public.v_pagos_por_proveedor  set (security_invoker = on);
alter view public.v_saldos_obra          set (security_invoker = on);
alter view public.v_ganancia_cobrada     set (security_invoker = on);
alter view public.v_retiros_convergencia set (security_invoker = on);

-- ── 3. Fijar search_path del trigger ────────────────────────────────────────
-- Evita que un search_path mutable permita resolución de nombres inesperada.
alter function public.tf_set_tc_from_fallback() set search_path = public, pg_temp;
