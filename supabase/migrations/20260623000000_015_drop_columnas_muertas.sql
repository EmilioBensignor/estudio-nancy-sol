-- Elimina clientes.direccion: se sacó "Dirección de la obra" del alta de cliente
-- (la dirección vive en la obra, no en el cliente). Sin dependencias en vistas.
-- NOTA: obras.tipo_cambio_fallback NO se borra: aunque ya no se carga desde la UI,
-- la vista v_presupuesto_items la usa como fallback de TC para ítems en USD.

alter table clientes drop column if exists direccion;
