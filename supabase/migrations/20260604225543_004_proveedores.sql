-- 004_proveedores.sql

create table public.proveedores (
  id uuid primary key default gen_random_uuid(),
  nombre text not null,
  sobrenombre text,
  telefono text,
  rubro_id uuid references public.rubros(id),
  email text,
  created_at timestamptz not null default now()
);

alter table public.proveedores enable row level security;

grant select on public.proveedores to authenticated;
grant select, insert, update, delete on public.proveedores to authenticated;
grant select, insert, update, delete on public.proveedores to service_role;

create policy "proveedores_admin" on public.proveedores for all to authenticated using (true);
