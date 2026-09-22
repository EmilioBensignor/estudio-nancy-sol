-- 013_campos_cuit_direccion — Campos del Excel faltantes (2026-06-05)
-- Agrega CUIT a clientes y proveedores, y dirección al cliente (hoja Data del Excel).
-- Columnas nuevas en tablas existentes: heredan grants (authenticated/service_role)
-- y RLS de la tabla. No requieren GRANT nuevo (los grants son a nivel tabla).

alter table public.clientes    add column if not exists cuit text;
alter table public.clientes    add column if not exists direccion text;
alter table public.proveedores add column if not exists cuit text;
