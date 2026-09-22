-- 006_presupuesto_items.sql

create table public.presupuesto_items (
  id uuid primary key default gen_random_uuid(),
  obra_id uuid not null references public.obras(id),
  fecha date,
  proveedor_id uuid references public.proveedores(id),
  rubro_id uuid references public.rubros(id),
  detalle text,
  valor_proveedor numeric not null default 0,
  moneda_proveedor text not null default 'ARS',
  tc_proveedor numeric,
  valor_presupuesto numeric not null default 0,
  moneda text not null default 'ARS',
  tc_item numeric,
  valor_final numeric not null default 0,
  notas text,
  created_at timestamptz not null default now()
);

alter table public.presupuesto_items enable row level security;

grant select on public.presupuesto_items to authenticated;
grant select, insert, update, delete on public.presupuesto_items to authenticated;
grant select, insert, update, delete on public.presupuesto_items to service_role;

create policy "presupuesto_items_admin" on public.presupuesto_items for all to authenticated using (true);

-- Trigger: completa TC desde el fallback de la obra si falta (USD sin TC)
create or replace function public.tf_set_tc_from_fallback()
returns trigger as $$
begin
  if NEW.moneda = 'USD' and NEW.tc_item is null then
    SELECT tipo_cambio_fallback INTO NEW.tc_item
    FROM obras WHERE id = NEW.obra_id;
  end if;
  if NEW.moneda_proveedor = 'USD' and NEW.tc_proveedor is null then
    SELECT tipo_cambio_fallback INTO NEW.tc_proveedor
    FROM obras WHERE id = NEW.obra_id;
  end if;
  return NEW;
end;
$$ language plpgsql;

create trigger tr_set_tc_item
  before insert or update on public.presupuesto_items
  for each row execute function public.tf_set_tc_from_fallback();

-- CHECK: solo dispara si el fallback también es null (red final anti-silencio)
alter table public.presupuesto_items add constraint chk_tc_item
  check (moneda = 'ARS' or tc_item is not null);
alter table public.presupuesto_items add constraint chk_tc_proveedor
  check (moneda_proveedor = 'ARS' or tc_proveedor is not null);
