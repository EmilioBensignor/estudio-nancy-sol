-- 005_obras.sql

create table public.obras (
  id uuid primary key default gen_random_uuid(),
  cliente_id uuid not null references public.clientes(id),
  nombre_direccion text not null,
  fecha_inicio date,
  estado text not null default 'activa' check (estado in ('activa', 'finalizada', 'pausada')),
  honorario_override numeric,
  split_nancy_override numeric,
  split_sol_override numeric,
  tipo_cambio_fallback numeric,
  created_at timestamptz not null default now()
);

alter table public.obras enable row level security;

grant select on public.obras to authenticated;
grant select, insert, update, delete on public.obras to authenticated;
grant select, insert, update, delete on public.obras to service_role;

create policy "obras_admin" on public.obras for all to authenticated using (true);
