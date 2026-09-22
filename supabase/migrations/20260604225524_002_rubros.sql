-- 002_rubros.sql
-- Catálogo de rubros (catálogo editable, seed con ~30 rubros reales del Excel).

create table public.rubros (
  id uuid primary key default gen_random_uuid(),
  nombre text unique not null,
  created_at timestamptz not null default now()
);

alter table public.rubros enable row level security;

-- Grants Data API
grant select on public.rubros to authenticated;
grant select, insert, update, delete on public.rubros to authenticated;
grant select, insert, update, delete on public.rubros to service_role;

-- Policy
create policy "rubros_admin" on public.rubros for all to authenticated using (true);

-- Seed con los ~30 rubros reales del Excel
insert into public.rubros (nombre) values
  ('ALBAÑILERIA'),
  ('VOLQUETE'),
  ('MATERIALES'),
  ('ELECTRODOMESTICOS'),
  ('ART. SANIT'),
  ('REVESTIMIENTOS'),
  ('INST. AA'),
  ('CARP. MADERA'),
  ('CARP. ALUMINIO'),
  ('CARP. PVC'),
  ('INST. SANIT Y GAS'),
  ('INST. ELECTRICA'),
  ('ART. ILUMINACION'),
  ('MARMOLERIA'),
  ('VARIOS'),
  ('FLETES'),
  ('PAISAJISMO'),
  ('DURLOCK'),
  ('PULIDO E HIDRO'),
  ('YESERIA'),
  ('VIDRIOS'),
  ('IMPERM.'),
  ('TAPICERIA'),
  ('PINTURA'),
  ('MOBILIARIO'),
  ('HERRERIA'),
  ('FLETE - EMBALAJE'),
  ('EMBALAJE'),
  ('CALEFACCION'),
  ('REP. CORT ENROLLAR')
on conflict (nombre) do nothing;
