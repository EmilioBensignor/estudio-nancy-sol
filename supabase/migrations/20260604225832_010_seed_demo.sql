-- 010_seed_demo.sql
-- Obra mockup "Ramsay 1945" sin datos confidenciales reales.
-- (El dato completo de Ramsay se carga con supabase/seed_ramsay.sql.)

-- Cliente demo
insert into public.clientes (nombre, sobrenombre, telefono, email)
values ('Eli Ramsay', 'Eli', '+54 11 0000 0000', 'eli@demo.com')
returning id;

-- Obra Ramsay 1945
insert into public.obras (cliente_id, nombre_direccion, fecha_inicio, estado, tipo_cambio_fallback)
values (
  (select id from public.clientes where sobrenombre = 'Eli'),
  'Ramsay 1945',
  '2026-01-15',
  'activa',
  1200  -- TC fallback demo
)
returning id;
