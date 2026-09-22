-- 011_keepalive.sql
create table public._keepalive (
  id uuid primary key default gen_random_uuid(),
  pinged_at timestamptz not null default now()
);
alter table public._keepalive enable row level security;

-- IMPORTANTE: grants para el ping del keep-alive.sh
grant select, insert, delete on public._keepalive to anon;
create policy "keepalive_anon_insert" on public._keepalive for insert to anon with check (true);
create policy "keepalive_anon_delete" on public._keepalive for delete to anon using (true);
create policy "keepalive_anon_select" on public._keepalive for select to anon using (true);
