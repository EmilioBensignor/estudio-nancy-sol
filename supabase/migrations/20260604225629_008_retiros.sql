-- 008_retiros.sql

create table public.retiros (
  id uuid primary key default gen_random_uuid(),
  obra_id uuid not null references public.obras(id),
  fecha date not null,
  monto_nancy numeric not null default 0,
  monto_sol numeric not null default 0,
  moneda text not null default 'ARS',
  tipo_cambio numeric not null,
  created_at timestamptz not null default now()
);

alter table public.retiros enable row level security;

grant select on public.retiros to authenticated;
grant select, insert, update, delete on public.retiros to authenticated;
grant select, insert, update, delete on public.retiros to service_role;

create policy "retiros_admin" on public.retiros for all to authenticated using (true);
