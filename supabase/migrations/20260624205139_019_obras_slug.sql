-- Slug legible para la URL de obra (/obras/ramsay-1945 en vez del UUID).
-- Único: si una dirección se repite, el front agrega sufijo -2, -3, etc.
alter table obras add column if not exists slug text;

-- Backfill: slug desde nombre_direccion para las obras existentes.
update obras
set slug = lower(
  regexp_replace(
    regexp_replace(
      translate(nombre_direccion, 'áéíóúüñÁÉÍÓÚÜÑ', 'aeiouunAEIOUUN'),
      '[^a-zA-Z0-9]+', '-', 'g'
    ),
    '(^-+|-+$)', '', 'g'
  )
)
where slug is null;

create unique index if not exists obras_slug_key on obras (slug);
