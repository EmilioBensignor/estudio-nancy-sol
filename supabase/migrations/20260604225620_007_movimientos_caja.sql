-- 007_movimientos_caja.sql

create table public.movimientos_caja (
  id uuid primary key default gen_random_uuid(),
  obra_id uuid not null references public.obras(id),
  tipo text not null check (tipo in ('cobro_cliente', 'pago_proveedor', 'retiro')),
  proveedor_id uuid references public.proveedores(id),
  monto numeric not null,
  moneda text not null default 'ARS',
  tipo_cambio numeric not null,
  medio_pago text check (medio_pago in ('efectivo', 'transferencia')),
  fecha date not null,
  created_at timestamptz not null default now()
);

alter table public.movimientos_caja enable row level security;

grant select on public.movimientos_caja to authenticated;
grant select, insert, update, delete on public.movimientos_caja to authenticated;
grant select, insert, update, delete on public.movimientos_caja to service_role;

create policy "movimientos_caja_admin" on public.movimientos_caja for all to authenticated using (true);
