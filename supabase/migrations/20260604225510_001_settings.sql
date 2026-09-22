-- 001_settings.sql
-- Tabla singleton para configuración global del estudio.

create table public.settings (
  id uuid primary key default gen_random_uuid() constraint settings_singleton check (id = '00000000-0000-0000-0000-000000000001'),
  honorario_default numeric not null default 0.15,
  target_reparto_nancy numeric not null default 0.50,
  target_reparto_sol numeric not null default 0.50,
  moneda_base text not null default 'ARS',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.settings enable row level security;

-- Grants Data API
grant select on public.settings to authenticated;
grant select, insert, update, delete on public.settings to authenticated;
grant select, insert, update, delete on public.settings to service_role;

-- Policy: authenticated puede todo (admin compartido 2 socias)
create policy "settings_admin" on public.settings for all to authenticated using (true);

-- Fila inicial
insert into public.settings (id, honorario_default, target_reparto_nancy, target_reparto_sol, moneda_base)
values ('00000000-0000-0000-0000-000000000001', 0.15, 0.50, 0.50, 'ARS')
on conflict (id) do nothing;
