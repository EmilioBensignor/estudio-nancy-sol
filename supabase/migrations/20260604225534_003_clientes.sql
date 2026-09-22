-- 003_clientes.sql

create table public.clientes (
  id uuid primary key default gen_random_uuid(),
  nombre text not null,
  sobrenombre text,
  telefono text,
  email text,
  created_at timestamptz not null default now()
);

alter table public.clientes enable row level security;

grant select on public.clientes to authenticated;
grant select, insert, update, delete on public.clientes to authenticated;
grant select, insert, update, delete on public.clientes to service_role;

create policy "clientes_admin" on public.clientes for all to authenticated using (true);
