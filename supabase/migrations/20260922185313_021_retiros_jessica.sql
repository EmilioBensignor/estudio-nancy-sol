-- Jessica se suma como tercera persona que retira. Cada obra elige quién retira
-- (switch por persona); Jessica arranca apagada en todas las obras.
alter table obras
  add column if not exists retira_nancy boolean not null default true,
  add column if not exists retira_sol boolean not null default true,
  add column if not exists retira_jessica boolean not null default false,
  add column if not exists split_jessica_override numeric;

alter table retiros add column if not exists monto_jessica numeric not null default 0;

-- Las views suman retiros como (monto_nancy + monto_sol). v_caja_saldo y
-- v_retiros_convergencia no están versionadas en el repo, así que se reescriben
-- desde su definición viva sumando monto_jessica. create or replace resetea las
-- reloptions: se vuelve a poner security_invoker (ver 012).
do $$
declare
  v record;
  def text;
begin
  for v in
    select c.oid, c.relname
    from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public' and c.relkind = 'v'
  loop
    def := pg_get_viewdef(v.oid);
    if def ~ 'monto_sol' and def !~ 'monto_jessica' then
      def := regexp_replace(
        def,
        '(\w+\.)?monto_nancy \+ (\w+\.)?monto_sol',
        '\1monto_nancy + \2monto_sol + \2monto_jessica',
        'g'
      );
      execute format('create or replace view public.%I with (security_invoker = on) as %s', v.relname, def);
    end if;
  end loop;
end $$;

-- Al Río C: retiran Solana y Jessica, mitad y mitad.
update obras
set retira_nancy = false, retira_sol = true, retira_jessica = true,
    split_nancy_override = 0, split_sol_override = 0.5, split_jessica_override = 0.5
where nombre_direccion ilike 'al r_o c%';
