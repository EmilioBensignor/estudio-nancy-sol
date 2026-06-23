-- Seed: caso real del Excel 'MODELO PRESUPUESTO' (obra Ramsay 1945).
-- Generado desde el Excel. Igual al Excel. Idempotente.
begin;

delete from retiros;
delete from movimientos_caja;
delete from presupuesto_items;
delete from obras;

insert into clientes (id, nombre, email)
values ('11111111-1111-1111-1111-111111111111','Eli','bensignornancy@gmail.com')
on conflict (id) do update set nombre=excluded.nombre, email=excluded.email;

-- Rubros
insert into rubros (nombre) values ('ALBAÑILERIA') on conflict do nothing;
insert into rubros (nombre) values ('ART. ILUMINACION') on conflict do nothing;
insert into rubros (nombre) values ('ART. SANIT') on conflict do nothing;
insert into rubros (nombre) values ('ART. SANIT.') on conflict do nothing;
insert into rubros (nombre) values ('CALEFACCION') on conflict do nothing;
insert into rubros (nombre) values ('CARP. ALUMINIO') on conflict do nothing;
insert into rubros (nombre) values ('CARP. MADERA') on conflict do nothing;
insert into rubros (nombre) values ('CARP. PVC') on conflict do nothing;
insert into rubros (nombre) values ('DATOS') on conflict do nothing;
insert into rubros (nombre) values ('DURLOCK') on conflict do nothing;
insert into rubros (nombre) values ('ELECTRODOMESTICOS') on conflict do nothing;
insert into rubros (nombre) values ('EMBALAJE') on conflict do nothing;
insert into rubros (nombre) values ('FLETES') on conflict do nothing;
insert into rubros (nombre) values ('HERRERIA') on conflict do nothing;
insert into rubros (nombre) values ('IMPERM. TAPICERIA') on conflict do nothing;
insert into rubros (nombre) values ('INST. AA') on conflict do nothing;
insert into rubros (nombre) values ('INST. ELECTRICA') on conflict do nothing;
insert into rubros (nombre) values ('INST.SANIT Y GAS') on conflict do nothing;
insert into rubros (nombre) values ('MARMOLERIA') on conflict do nothing;
insert into rubros (nombre) values ('MATERIALES') on conflict do nothing;
insert into rubros (nombre) values ('MOBILIARIO') on conflict do nothing;
insert into rubros (nombre) values ('PAISAJISMO') on conflict do nothing;
insert into rubros (nombre) values ('PINTURA') on conflict do nothing;
insert into rubros (nombre) values ('PULIDO E HIDRO') on conflict do nothing;
insert into rubros (nombre) values ('REP. CORT ENROLLAR') on conflict do nothing;
insert into rubros (nombre) values ('REVESTIMIENTOS') on conflict do nothing;
insert into rubros (nombre) values ('TAPICERIA') on conflict do nothing;
insert into rubros (nombre) values ('VARIOS') on conflict do nothing;
insert into rubros (nombre) values ('VIDRIOS') on conflict do nothing;
insert into rubros (nombre) values ('VOLQUETE') on conflict do nothing;
insert into rubros (nombre) values ('YESERIA') on conflict do nothing;

-- Proveedores
insert into proveedores (nombre, sobrenombre, telefono, rubro_id, cuit)
select 'Cristhian', null, null, (select id from rubros where nombre='ALBAÑILERIA' limit 1), null
where not exists (select 1 from proveedores where nombre='Cristhian');
insert into proveedores (nombre, sobrenombre, telefono, rubro_id, cuit)
select 'Volquetes', 'Vanina', null, (select id from rubros where nombre='VOLQUETE' limit 1), null
where not exists (select 1 from proveedores where nombre='Volquetes');
insert into proveedores (nombre, sobrenombre, telefono, rubro_id, cuit)
select 'Corralon Loyola', null, null, (select id from rubros where nombre='MATERIALES' limit 1), null
where not exists (select 1 from proveedores where nombre='Corralon Loyola');
insert into proveedores (nombre, sobrenombre, telefono, rubro_id, cuit)
select 'Piluso', null, null, (select id from rubros where nombre='ELECTRODOMESTICOS' limit 1), null
where not exists (select 1 from proveedores where nombre='Piluso');
insert into proveedores (nombre, sobrenombre, telefono, rubro_id, cuit)
select 'Buck & buck', null, null, (select id from rubros where nombre='ART. SANIT.' limit 1), null
where not exists (select 1 from proveedores where nombre='Buck & buck');
insert into proveedores (nombre, sobrenombre, telefono, rubro_id, cuit)
select 'Abelson', 'Piluso', null, (select id from rubros where nombre='ART. SANIT' limit 1), null
where not exists (select 1 from proveedores where nombre='Abelson');
insert into proveedores (nombre, sobrenombre, telefono, rubro_id, cuit)
select 'Eliplay', 'Javier', null, (select id from rubros where nombre='REVESTIMIENTOS' limit 1), null
where not exists (select 1 from proveedores where nombre='Eliplay');
insert into proveedores (nombre, sobrenombre, telefono, rubro_id, cuit)
select 'Sbg', 'Georgina', null, (select id from rubros where nombre='REVESTIMIENTOS' limit 1), null
where not exists (select 1 from proveedores where nombre='Sbg');
insert into proveedores (nombre, sobrenombre, telefono, rubro_id, cuit)
select 'Cyme', 'Leo', null, (select id from rubros where nombre='INST. AA' limit 1), null
where not exists (select 1 from proveedores where nombre='Cyme');
insert into proveedores (nombre, sobrenombre, telefono, rubro_id, cuit)
select 'Grupo Refri', 'Polito', null, (select id from rubros where nombre='INST. AA' limit 1), null
where not exists (select 1 from proveedores where nombre='Grupo Refri');
insert into proveedores (nombre, sobrenombre, telefono, rubro_id, cuit)
select 'Ecoklima', 'Ezequiel', null, (select id from rubros where nombre='INST. AA' limit 1), null
where not exists (select 1 from proveedores where nombre='Ecoklima');
insert into proveedores (nombre, sobrenombre, telefono, rubro_id, cuit)
select 'Semino', null, null, (select id from rubros where nombre='INST. AA' limit 1), null
where not exists (select 1 from proveedores where nombre='Semino');
insert into proveedores (nombre, sobrenombre, telefono, rubro_id, cuit)
select 'Battista', 'Sergio', null, (select id from rubros where nombre='CARP. MADERA' limit 1), null
where not exists (select 1 from proveedores where nombre='Battista');
insert into proveedores (nombre, sobrenombre, telefono, rubro_id, cuit)
select 'Occhipinti', 'Sofia Gatti', null, (select id from rubros where nombre='CARP. MADERA' limit 1), null
where not exists (select 1 from proveedores where nombre='Occhipinti');
insert into proveedores (nombre, sobrenombre, telefono, rubro_id, cuit)
select 'Tm', 'Mauricio y Tomas', null, (select id from rubros where nombre='CARP. MADERA' limit 1), null
where not exists (select 1 from proveedores where nombre='Tm');
insert into proveedores (nombre, sobrenombre, telefono, rubro_id, cuit)
select 'Missura', 'Alejandro.', null, (select id from rubros where nombre='CARP. MADERA' limit 1), null
where not exists (select 1 from proveedores where nombre='Missura');
insert into proveedores (nombre, sobrenombre, telefono, rubro_id, cuit)
select 'Roberto', null, null, (select id from rubros where nombre='CARP. MADERA' limit 1), null
where not exists (select 1 from proveedores where nombre='Roberto');
insert into proveedores (nombre, sobrenombre, telefono, rubro_id, cuit)
select 'Miguel', null, null, (select id from rubros where nombre='CARP. MADERA' limit 1), null
where not exists (select 1 from proveedores where nombre='Miguel');
insert into proveedores (nombre, sobrenombre, telefono, rubro_id, cuit)
select 'Luis Villallba', null, null, (select id from rubros where nombre='CARP. MADERA' limit 1), null
where not exists (select 1 from proveedores where nombre='Luis Villallba');
insert into proveedores (nombre, sobrenombre, telefono, rubro_id, cuit)
select 'Mi cocina', 'Tere', null, (select id from rubros where nombre='CARP. MADERA' limit 1), null
where not exists (select 1 from proveedores where nombre='Mi cocina');
insert into proveedores (nombre, sobrenombre, telefono, rubro_id, cuit)
select 'Priscila', null, null, (select id from rubros where nombre='CARP. MADERA' limit 1), null
where not exists (select 1 from proveedores where nombre='Priscila');
insert into proveedores (nombre, sobrenombre, telefono, rubro_id, cuit)
select 'Todo Aberturas', null, null, (select id from rubros where nombre='CARP. ALUMINIO' limit 1), null
where not exists (select 1 from proveedores where nombre='Todo Aberturas');
insert into proveedores (nombre, sobrenombre, telefono, rubro_id, cuit)
select 'Lusso', null, null, (select id from rubros where nombre='CARP. PVC' limit 1), null
where not exists (select 1 from proveedores where nombre='Lusso');
insert into proveedores (nombre, sobrenombre, telefono, rubro_id, cuit)
select 'Miguel Pastore', null, null, (select id from rubros where nombre='INST.SANIT Y GAS' limit 1), null
where not exists (select 1 from proveedores where nombre='Miguel Pastore');
insert into proveedores (nombre, sobrenombre, telefono, rubro_id, cuit)
select 'Portero electrico', null, null, (select id from rubros where nombre='INST. ELECTRICA' limit 1), null
where not exists (select 1 from proveedores where nombre='Portero electrico');
insert into proveedores (nombre, sobrenombre, telefono, rubro_id, cuit)
select 'Jesus Cala Rodriguez', null, null, (select id from rubros where nombre='INST. ELECTRICA' limit 1), null
where not exists (select 1 from proveedores where nombre='Jesus Cala Rodriguez');
insert into proveedores (nombre, sobrenombre, telefono, rubro_id, cuit)
select 'Parana', 'Martin', null, (select id from rubros where nombre='ART. ILUMINACION' limit 1), null
where not exists (select 1 from proveedores where nombre='Parana');
insert into proveedores (nombre, sobrenombre, telefono, rubro_id, cuit)
select 'Anton', null, null, (select id from rubros where nombre='MARMOLERIA' limit 1), null
where not exists (select 1 from proveedores where nombre='Anton');
insert into proveedores (nombre, sobrenombre, telefono, rubro_id, cuit)
select 'Aiseva', 'Tino', null, (select id from rubros where nombre='MARMOLERIA' limit 1), null
where not exists (select 1 from proveedores where nombre='Aiseva');
insert into proveedores (nombre, sobrenombre, telefono, rubro_id, cuit)
select 'Dillemberger', null, null, (select id from rubros where nombre='VARIOS' limit 1), null
where not exists (select 1 from proveedores where nombre='Dillemberger');
insert into proveedores (nombre, sobrenombre, telefono, rubro_id, cuit)
select 'Vec', null, null, (select id from rubros where nombre='VARIOS' limit 1), null
where not exists (select 1 from proveedores where nombre='Vec');
insert into proveedores (nombre, sobrenombre, telefono, rubro_id, cuit)
select 'Pablo Flete', null, null, (select id from rubros where nombre='FLETES' limit 1), null
where not exists (select 1 from proveedores where nombre='Pablo Flete');
insert into proveedores (nombre, sobrenombre, telefono, rubro_id, cuit)
select 'Pablo Goyena', null, null, (select id from rubros where nombre='FLETES' limit 1), null
where not exists (select 1 from proveedores where nombre='Pablo Goyena');
insert into proveedores (nombre, sobrenombre, telefono, rubro_id, cuit)
select 'Pauli', null, null, (select id from rubros where nombre='PAISAJISMO' limit 1), null
where not exists (select 1 from proveedores where nombre='Pauli');
insert into proveedores (nombre, sobrenombre, telefono, rubro_id, cuit)
select 'Cristian', null, null, (select id from rubros where nombre='DURLOCK' limit 1), null
where not exists (select 1 from proveedores where nombre='Cristian');
insert into proveedores (nombre, sobrenombre, telefono, rubro_id, cuit)
select 'Comercial', null, null, (select id from rubros where nombre='DURLOCK' limit 1), null
where not exists (select 1 from proveedores where nombre='Comercial');
insert into proveedores (nombre, sobrenombre, telefono, rubro_id, cuit)
select 'Prindemar', null, null, (select id from rubros where nombre='PULIDO E HIDRO' limit 1), null
where not exists (select 1 from proveedores where nombre='Prindemar');
insert into proveedores (nombre, sobrenombre, telefono, rubro_id, cuit)
select 'Carlos Cabrera', null, null, (select id from rubros where nombre='PULIDO E HIDRO' limit 1), null
where not exists (select 1 from proveedores where nombre='Carlos Cabrera');
insert into proveedores (nombre, sobrenombre, telefono, rubro_id, cuit)
select 'Alejandro Olmedo', null, null, (select id from rubros where nombre='YESERIA' limit 1), null
where not exists (select 1 from proveedores where nombre='Alejandro Olmedo');
insert into proveedores (nombre, sobrenombre, telefono, rubro_id, cuit)
select 'Juan Cortes', null, null, (select id from rubros where nombre='VIDRIOS' limit 1), null
where not exists (select 1 from proveedores where nombre='Juan Cortes');
insert into proveedores (nombre, sobrenombre, telefono, rubro_id, cuit)
select 'Adrian Romano', null, null, (select id from rubros where nombre='VIDRIOS' limit 1), null
where not exists (select 1 from proveedores where nombre='Adrian Romano');
insert into proveedores (nombre, sobrenombre, telefono, rubro_id, cuit)
select 'Ag cristales', 'Eduardo', null, (select id from rubros where nombre='VIDRIOS' limit 1), null
where not exists (select 1 from proveedores where nombre='Ag cristales');
insert into proveedores (nombre, sobrenombre, telefono, rubro_id, cuit)
select 'Anibal Guevara', null, null, null, null
where not exists (select 1 from proveedores where nombre='Anibal Guevara');
insert into proveedores (nombre, sobrenombre, telefono, rubro_id, cuit)
select 'Protela', null, null, (select id from rubros where nombre='IMPERM. TAPICERIA' limit 1), null
where not exists (select 1 from proveedores where nombre='Protela');
insert into proveedores (nombre, sobrenombre, telefono, rubro_id, cuit)
select 'Sergio', null, null, (select id from rubros where nombre='PINTURA' limit 1), null
where not exists (select 1 from proveedores where nombre='Sergio');
insert into proveedores (nombre, sobrenombre, telefono, rubro_id, cuit)
select 'Rodrigo', null, null, (select id from rubros where nombre='PINTURA' limit 1), null
where not exists (select 1 from proveedores where nombre='Rodrigo');
insert into proveedores (nombre, sobrenombre, telefono, rubro_id, cuit)
select 'Marini', 'Franco', null, (select id from rubros where nombre='MOBILIARIO' limit 1), null
where not exists (select 1 from proveedores where nombre='Marini');
insert into proveedores (nombre, sobrenombre, telefono, rubro_id, cuit)
select 'Fontenla', null, null, null, null
where not exists (select 1 from proveedores where nombre='Fontenla');
insert into proveedores (nombre, sobrenombre, telefono, rubro_id, cuit)
select 'Rugit', 'Tibi, Laura (si) Isabel (uy)', null, null, null
where not exists (select 1 from proveedores where nombre='Rugit');
insert into proveedores (nombre, sobrenombre, telefono, rubro_id, cuit)
select 'Tramma', null, null, null, null
where not exists (select 1 from proveedores where nombre='Tramma');
insert into proveedores (nombre, sobrenombre, telefono, rubro_id, cuit)
select 'Taller Ferro', null, null, null, null
where not exists (select 1 from proveedores where nombre='Taller Ferro');
insert into proveedores (nombre, sobrenombre, telefono, rubro_id, cuit)
select 'Tintachini', null, null, null, null
where not exists (select 1 from proveedores where nombre='Tintachini');
insert into proveedores (nombre, sobrenombre, telefono, rubro_id, cuit)
select 'Leonardo', null, null, null, null
where not exists (select 1 from proveedores where nombre='Leonardo');
insert into proveedores (nombre, sobrenombre, telefono, rubro_id, cuit)
select 'FCH', null, null, null, null
where not exists (select 1 from proveedores where nombre='FCH');
insert into proveedores (nombre, sobrenombre, telefono, rubro_id, cuit)
select 'Oscar', null, null, (select id from rubros where nombre='HERRERIA' limit 1), null
where not exists (select 1 from proveedores where nombre='Oscar');
insert into proveedores (nombre, sobrenombre, telefono, rubro_id, cuit)
select 'Juan', null, null, (select id from rubros where nombre='TAPICERIA' limit 1), null
where not exists (select 1 from proveedores where nombre='Juan');
insert into proveedores (nombre, sobrenombre, telefono, rubro_id, cuit)
select 'Zanav', 'Miriam', null, null, null
where not exists (select 1 from proveedores where nombre='Zanav');
insert into proveedores (nombre, sobrenombre, telefono, rubro_id, cuit)
select 'Tienda mayor', null, null, null, null
where not exists (select 1 from proveedores where nombre='Tienda mayor');
insert into proveedores (nombre, sobrenombre, telefono, rubro_id, cuit)
select 'Pablo', null, null, (select id from rubros where nombre='EMBALAJE' limit 1), null
where not exists (select 1 from proveedores where nombre='Pablo');
insert into proveedores (nombre, sobrenombre, telefono, rubro_id, cuit)
select 'Fernando', null, null, null, null
where not exists (select 1 from proveedores where nombre='Fernando');
insert into proveedores (nombre, sobrenombre, telefono, rubro_id, cuit)
select 'Jorge', null, null, (select id from rubros where nombre='CALEFACCION' limit 1), null
where not exists (select 1 from proveedores where nombre='Jorge');
insert into proveedores (nombre, sobrenombre, telefono, rubro_id, cuit)
select 'Hugo', null, null, (select id from rubros where nombre='REP. CORT ENROLLAR' limit 1), null
where not exists (select 1 from proveedores where nombre='Hugo');
insert into proveedores (nombre, sobrenombre, telefono, rubro_id, cuit)
select 'Saver', null, null, (select id from rubros where nombre='DATOS' limit 1), null
where not exists (select 1 from proveedores where nombre='Saver');

-- Obra
insert into obras (id, cliente_id, nombre_direccion, estado)
values ('9a6e1e78-cb27-491c-98ad-01b915582523', '11111111-1111-1111-1111-111111111111', 'Ramsay 1945', 'activa')
on conflict (id) do update set nombre_direccion=excluded.nombre_direccion;

-- Ítems del presupuesto
insert into presupuesto_items (obra_id, fecha, proveedor_id, rubro_id, detalle, valor_proveedor, valor_presupuesto, valor_final, notas)
values ('9a6e1e78-cb27-491c-98ad-01b915582523', '2025-12-16', (select id from proveedores where nombre='Cristhian' limit 1), (select id from rubros where nombre='ALBAÑILERIA' limit 1), 'Mano de obra', 250000, 250000, 250000, null);
insert into presupuesto_items (obra_id, fecha, proveedor_id, rubro_id, detalle, valor_proveedor, valor_presupuesto, valor_final, notas)
values ('9a6e1e78-cb27-491c-98ad-01b915582523', '2025-12-17', (select id from proveedores where nombre='Corralon Loyola' limit 1), (select id from rubros where nombre='MATERIALES' limit 1), 'Provision de materiales gruesos para la obra, valor segun avance hasta la fecha de hoy', 822000, 822000, 822000, null);
insert into presupuesto_items (obra_id, fecha, proveedor_id, rubro_id, detalle, valor_proveedor, valor_presupuesto, valor_final, notas)
values ('9a6e1e78-cb27-491c-98ad-01b915582523', '2025-12-18', (select id from proveedores where nombre='Volquetes' limit 1), (select id from rubros where nombre='VOLQUETE' limit 1), 'Volquetes segun avance hasta el dia de la fecha de hoy', 104650, 104650, 104650, null);
insert into presupuesto_items (obra_id, fecha, proveedor_id, rubro_id, detalle, valor_proveedor, valor_presupuesto, valor_final, notas)
values ('9a6e1e78-cb27-491c-98ad-01b915582523', '2025-12-19', (select id from proveedores where nombre='Abelson' limit 1), (select id from rubros where nombre='ART. SANIT' limit 1), 'Sanitarios, griferias, segun detalle 1 y 2 (bañera)', 202128, 202128, 202128, null);
insert into presupuesto_items (obra_id, fecha, proveedor_id, rubro_id, detalle, valor_proveedor, valor_presupuesto, valor_final, notas)
values ('9a6e1e78-cb27-491c-98ad-01b915582523', null, (select id from proveedores where nombre='Piluso' limit 1), (select id from rubros where nombre='ELECTRODOMESTICOS' limit 1), '2 hornos elect + microondas+ lavavajillas panelable + anafe Whirpool,  extractor Bosch, sin cotizar', 0, 0, 0, null);
insert into presupuesto_items (obra_id, fecha, proveedor_id, rubro_id, detalle, valor_proveedor, valor_presupuesto, valor_final, notas)
values ('9a6e1e78-cb27-491c-98ad-01b915582523', '2025-12-19', (select id from proveedores where nombre='Sbg' limit 1), (select id from rubros where nombre='REVESTIMIENTOS' limit 1), 'Baños y cocina, lavadero y dorm serv. , usd 13 658', 526365, 526365, 526365, null);
insert into presupuesto_items (obra_id, fecha, proveedor_id, rubro_id, detalle, valor_proveedor, valor_presupuesto, valor_final, notas)
values ('9a6e1e78-cb27-491c-98ad-01b915582523', '2025-12-19', (select id from proveedores where nombre='Eliplay' limit 1), (select id from rubros where nombre='REVESTIMIENTOS' limit 1), 'Baño de servicio', 79800, 93000, 93000, 'Hizo descuento por otra obra');
insert into presupuesto_items (obra_id, fecha, proveedor_id, rubro_id, detalle, valor_proveedor, valor_presupuesto, valor_final, notas)
values ('9a6e1e78-cb27-491c-98ad-01b915582523', '2025-12-19', (select id from proveedores where nombre='Battista' limit 1), (select id from rubros where nombre='CARP. MADERA' limit 1), 'Cocina, lavadero - amoblamiento segun plano -usd 21.190', 310000, 310000, 310000, null);
insert into presupuesto_items (obra_id, fecha, proveedor_id, rubro_id, detalle, valor_proveedor, valor_presupuesto, valor_final, notas)
values ('9a6e1e78-cb27-491c-98ad-01b915582523', '2025-12-19', (select id from proveedores where nombre='Occhipinti' limit 1), (select id from rubros where nombre='CARP. MADERA' limit 1), 'Paso, dorm ppal y dorm 1- placards (3)  y vestidores (2)  usd 29 500', 44416, 50000, 50000, 'Hizo descuento por otra obra');
insert into presupuesto_items (obra_id, fecha, proveedor_id, rubro_id, detalle, valor_proveedor, valor_presupuesto, valor_final, notas)
values ('9a6e1e78-cb27-491c-98ad-01b915582523', '2025-12-20', (select id from proveedores where nombre='Tm' limit 1), (select id from rubros where nombre='CARP. MADERA' limit 1), 'Baños - mueble de guardado altos (2) y vanitorys (2)', 27310, 27310, 27310, null);
insert into presupuesto_items (obra_id, fecha, proveedor_id, rubro_id, detalle, valor_proveedor, valor_presupuesto, valor_final, notas)
values ('9a6e1e78-cb27-491c-98ad-01b915582523', '2025-12-21', (select id from proveedores where nombre='Missura' limit 1), (select id from rubros where nombre='CARP. MADERA' limit 1), 'Amoblamiento segun descripicion:', 34707, 34707, 34707, null);
insert into presupuesto_items (obra_id, fecha, proveedor_id, rubro_id, detalle, valor_proveedor, valor_presupuesto, valor_final, notas)
values ('9a6e1e78-cb27-491c-98ad-01b915582523', null, null, null, 'Escritorio- living - cerramiento', 0, 0, 0, null);
insert into presupuesto_items (obra_id, fecha, proveedor_id, rubro_id, detalle, valor_proveedor, valor_presupuesto, valor_final, notas)
values ('9a6e1e78-cb27-491c-98ad-01b915582523', null, null, null, 'Escritorio - mueble de guardado', 0, 0, 0, null);
insert into presupuesto_items (obra_id, fecha, proveedor_id, rubro_id, detalle, valor_proveedor, valor_presupuesto, valor_final, notas)
values ('9a6e1e78-cb27-491c-98ad-01b915582523', null, null, null, 'Living comedor - vajillero y mueble tv', 0, 0, 0, null);
insert into presupuesto_items (obra_id, fecha, proveedor_id, rubro_id, detalle, valor_proveedor, valor_presupuesto, valor_final, notas)
values ('9a6e1e78-cb27-491c-98ad-01b915582523', null, null, null, 'Living comedor - puertas (2)', 0, 0, 0, null);
insert into presupuesto_items (obra_id, fecha, proveedor_id, rubro_id, detalle, valor_proveedor, valor_presupuesto, valor_final, notas)
values ('9a6e1e78-cb27-491c-98ad-01b915582523', null, null, null, 'Dorm 1 - paneles respaldo cama y estante tv', 0, 0, 0, null);
insert into presupuesto_items (obra_id, fecha, proveedor_id, rubro_id, detalle, valor_proveedor, valor_presupuesto, valor_final, notas)
values ('9a6e1e78-cb27-491c-98ad-01b915582523', null, null, null, 'Dorm 2 - mueble de guardado', 0, 0, 0, null);
insert into presupuesto_items (obra_id, fecha, proveedor_id, rubro_id, detalle, valor_proveedor, valor_presupuesto, valor_final, notas)
values ('9a6e1e78-cb27-491c-98ad-01b915582523', null, (select id from proveedores where nombre='Luis Villallba' limit 1), (select id from rubros where nombre='CARP. MADERA' limit 1), 'Varios - contramarcos, ajustes, etc, sin cotizar', 0, 0, 0, null);
insert into presupuesto_items (obra_id, fecha, proveedor_id, rubro_id, detalle, valor_proveedor, valor_presupuesto, valor_final, notas)
values ('9a6e1e78-cb27-491c-98ad-01b915582523', '2025-12-05', (select id from proveedores where nombre='Lusso' limit 1), (select id from rubros where nombre='CARP. PVC' limit 1), 'Gral - provision y colocacion de aberturas pvc -usd 23 600 + izaje', 21793, 21793, 21793, null);
insert into presupuesto_items (obra_id, fecha, proveedor_id, rubro_id, detalle, valor_proveedor, valor_presupuesto, valor_final, notas)
values ('9a6e1e78-cb27-491c-98ad-01b915582523', '2026-04-10', (select id from proveedores where nombre='Comercial' limit 1), (select id from rubros where nombre='DURLOCK' limit 1), 'Gral- prov. y coloc. de cielorraso, incluye adicionales en referencia a la inst aa, cierre de ventanas de baños, etc', 12511, 12511, 12511, null);
insert into presupuesto_items (obra_id, fecha, proveedor_id, rubro_id, detalle, valor_proveedor, valor_presupuesto, valor_final, notas)
values ('9a6e1e78-cb27-491c-98ad-01b915582523', '2026-01-31', (select id from proveedores where nombre='Grupo Refri' limit 1), (select id from rubros where nombre='INST. AA' limit 1), 'Segun detalle, equipos usd 15500 y mano de obra y otros $26 000 000', 59564, 59564, 59564, null);
insert into presupuesto_items (obra_id, fecha, proveedor_id, rubro_id, detalle, valor_proveedor, valor_presupuesto, valor_final, notas)
values ('9a6e1e78-cb27-491c-98ad-01b915582523', null, (select id from proveedores where nombre='Jesus Cala Rodriguez' limit 1), null, 'Desintalacion de esplits existentes', 36000, 36000, 36000, null);
insert into presupuesto_items (obra_id, fecha, proveedor_id, rubro_id, detalle, valor_proveedor, valor_presupuesto, valor_final, notas)
values ('9a6e1e78-cb27-491c-98ad-01b915582523', null, (select id from proveedores where nombre='Jesus Cala Rodriguez' limit 1), (select id from rubros where nombre='INST. ELECTRICA' limit 1), 'Mano de obra y materiales,   incluye diferencia por tendido de cañeria para aire acondicionado y datos', 22021, 22021, 22021, null);
insert into presupuesto_items (obra_id, fecha, proveedor_id, rubro_id, detalle, valor_proveedor, valor_presupuesto, valor_final, notas)
values ('9a6e1e78-cb27-491c-98ad-01b915582523', null, (select id from proveedores where nombre='Parana' limit 1), (select id from rubros where nombre='ART. ILUMINACION' limit 1), 'Segun detalle adj.', 14390, 14390, 14390, null);
insert into presupuesto_items (obra_id, fecha, proveedor_id, rubro_id, detalle, valor_proveedor, valor_presupuesto, valor_final, notas)
values ('9a6e1e78-cb27-491c-98ad-01b915582523', null, (select id from proveedores where nombre='Miguel Pastore' limit 1), (select id from rubros where nombre='INST.SANIT Y GAS' limit 1), 'Mano de obra y materiales (diferencia por cambio de desagues baños, cocina, baja silueta, etc)', 13400, 13400, 13400, null);
insert into presupuesto_items (obra_id, fecha, proveedor_id, rubro_id, detalle, valor_proveedor, valor_presupuesto, valor_final, notas)
values ('9a6e1e78-cb27-491c-98ad-01b915582523', null, null, (select id from rubros where nombre='MARMOLERIA' limit 1), 'Segun detalle adj.', 0, 0, 0, null);
insert into presupuesto_items (obra_id, fecha, proveedor_id, rubro_id, detalle, valor_proveedor, valor_presupuesto, valor_final, notas)
values ('9a6e1e78-cb27-491c-98ad-01b915582523', null, null, (select id from rubros where nombre='MARMOLERIA' limit 1), null, 0, 0, 0, null);
insert into presupuesto_items (obra_id, fecha, proveedor_id, rubro_id, detalle, valor_proveedor, valor_presupuesto, valor_final, notas)
values ('9a6e1e78-cb27-491c-98ad-01b915582523', null, (select id from proveedores where nombre='Anton' limit 1), (select id from rubros where nombre='MARMOLERIA' limit 1), null, 70476, 70476, 70476, null);
insert into presupuesto_items (obra_id, fecha, proveedor_id, rubro_id, detalle, valor_proveedor, valor_presupuesto, valor_final, notas)
values ('9a6e1e78-cb27-491c-98ad-01b915582523', null, (select id from proveedores where nombre='Sergio' limit 1), (select id from rubros where nombre='PINTURA' limit 1), 'Gral - subtotal mano de obra y materiales', 16800, 16800, 16800, null);
insert into presupuesto_items (obra_id, fecha, proveedor_id, rubro_id, detalle, valor_proveedor, valor_presupuesto, valor_final, notas)
values ('9a6e1e78-cb27-491c-98ad-01b915582523', null, (select id from proveedores where nombre='Hugo' limit 1), null, 'Gral- reparacion y acondicionamiento de cortinas de enrollar, valor de referencia', 27600, 27600, 27600, null);
insert into presupuesto_items (obra_id, fecha, proveedor_id, rubro_id, detalle, valor_proveedor, valor_presupuesto, valor_final, notas)
values ('9a6e1e78-cb27-491c-98ad-01b915582523', null, (select id from proveedores where nombre='Carlos Cabrera' limit 1), (select id from rubros where nombre='VARIOS' limit 1), 'Gral - Retiro de piso existente, provision y colocacion de tablonado roble eslavonia prefinish ingenieril (50.150 000)', 50150, 50150, 50150, null);
insert into presupuesto_items (obra_id, fecha, proveedor_id, rubro_id, detalle, valor_proveedor, valor_presupuesto, valor_final, notas)
values ('9a6e1e78-cb27-491c-98ad-01b915582523', null, null, (select id from rubros where nombre='VIDRIOS' limit 1), 'Baño ppal - provision y colocacion de espejo 1.60x1.20 y mampara PF fijo de 0.90x 2.25', 0, 0, 0, null);
insert into presupuesto_items (obra_id, fecha, proveedor_id, rubro_id, detalle, valor_proveedor, valor_presupuesto, valor_final, notas)
values ('9a6e1e78-cb27-491c-98ad-01b915582523', null, null, null, 'Baño 2 - provision y colocacion de mampara, PF, 090X2.25', 0, 0, 0, null);
insert into presupuesto_items (obra_id, fecha, proveedor_id, rubro_id, detalle, valor_proveedor, valor_presupuesto, valor_final, notas)
values ('9a6e1e78-cb27-491c-98ad-01b915582523', null, null, null, 'Baño 3 - provision y colocacion de mampara, PF y movil sobre bañera', 0, 0, 0, null);
insert into presupuesto_items (obra_id, fecha, proveedor_id, rubro_id, detalle, valor_proveedor, valor_presupuesto, valor_final, notas)
values ('9a6e1e78-cb27-491c-98ad-01b915582523', null, (select id from proveedores where nombre='Adrian Romano' limit 1), null, 'Subtotal vidrios', 26400, 26400, 26400, null);
insert into presupuesto_items (obra_id, fecha, proveedor_id, rubro_id, detalle, valor_proveedor, valor_presupuesto, valor_final, notas)
values ('9a6e1e78-cb27-491c-98ad-01b915582523', null, (select id from proveedores where nombre='Sbg' limit 1), null, 'Baño 2 y 3 - provision y colocacion de espejo (2)- SBG', 60300, 60300, 60300, null);
insert into presupuesto_items (obra_id, fecha, proveedor_id, rubro_id, detalle, valor_proveedor, valor_presupuesto, valor_final, notas)
values ('9a6e1e78-cb27-491c-98ad-01b915582523', null, null, (select id from rubros where nombre='TAPICERIA' limit 1), 'Dorm ppal y dorm 1 - respaldo tapizado con cuero', 0, 0, 0, null);
insert into presupuesto_items (obra_id, fecha, proveedor_id, rubro_id, detalle, valor_proveedor, valor_presupuesto, valor_final, notas)
values ('9a6e1e78-cb27-491c-98ad-01b915582523', null, null, null, 'Dorm 3 - provision y colocacion de respaldo y base de sommier existente', 0, 0, 0, null);
insert into presupuesto_items (obra_id, fecha, proveedor_id, rubro_id, detalle, valor_proveedor, valor_presupuesto, valor_final, notas)
values ('9a6e1e78-cb27-491c-98ad-01b915582523', null, (select id from proveedores where nombre='Juan' limit 1), null, 'Subtoral tapiceria', 0, 0, 0, null);
insert into presupuesto_items (obra_id, fecha, proveedor_id, rubro_id, detalle, valor_proveedor, valor_presupuesto, valor_final, notas)
values ('9a6e1e78-cb27-491c-98ad-01b915582523', null, (select id from proveedores where nombre='Zanav' limit 1), null, 'Genero', 0, 0, 0, null);
insert into presupuesto_items (obra_id, fecha, proveedor_id, rubro_id, detalle, valor_proveedor, valor_presupuesto, valor_final, notas)
values ('9a6e1e78-cb27-491c-98ad-01b915582523', null, (select id from proveedores where nombre='Jorge' limit 1), (select id from rubros where nombre='CALEFACCION' limit 1), 'Reparacion de serpentina para calefaccion y servicio de camara termica', 76000, 76000, 76000, null);
insert into presupuesto_items (obra_id, fecha, proveedor_id, rubro_id, detalle, valor_proveedor, valor_presupuesto, valor_final, notas)
values ('9a6e1e78-cb27-491c-98ad-01b915582523', null, (select id from proveedores where nombre='Oscar' limit 1), (select id from rubros where nombre='HERRERIA' limit 1), 'Corte de aberturas en baños', 15000, 15000, 15000, null);
insert into presupuesto_items (obra_id, fecha, proveedor_id, rubro_id, detalle, valor_proveedor, valor_presupuesto, valor_final, notas)
values ('9a6e1e78-cb27-491c-98ad-01b915582523', null, (select id from proveedores where nombre='Saver' limit 1), (select id from rubros where nombre='DATOS' limit 1), 'Instalacion de datos', 10000, 10000, 10000, null);
insert into presupuesto_items (obra_id, fecha, proveedor_id, rubro_id, detalle, valor_proveedor, valor_presupuesto, valor_final, notas)
values ('9a6e1e78-cb27-491c-98ad-01b915582523', null, (select id from proveedores where nombre='Alejandro Olmedo' limit 1), (select id from rubros where nombre='YESERIA' limit 1), null, 23000, 23000, 23000, null);

-- Pagos a proveedor (caja)
insert into movimientos_caja (obra_id, tipo, proveedor_id, monto, moneda, tipo_cambio, medio_pago, fecha)
values ('9a6e1e78-cb27-491c-98ad-01b915582523', 'pago_proveedor', (select id from proveedores where nombre='Cristhian' limit 1), 250000, 'ARS', 1, 'transferencia', current_date);
insert into movimientos_caja (obra_id, tipo, proveedor_id, monto, moneda, tipo_cambio, medio_pago, fecha)
values ('9a6e1e78-cb27-491c-98ad-01b915582523', 'pago_proveedor', (select id from proveedores where nombre='Corralon Loyola' limit 1), 822000, 'ARS', 1, 'transferencia', current_date);
insert into movimientos_caja (obra_id, tipo, proveedor_id, monto, moneda, tipo_cambio, medio_pago, fecha)
values ('9a6e1e78-cb27-491c-98ad-01b915582523', 'pago_proveedor', (select id from proveedores where nombre='Volquetes' limit 1), 104650, 'ARS', 1, 'transferencia', current_date);
insert into movimientos_caja (obra_id, tipo, proveedor_id, monto, moneda, tipo_cambio, medio_pago, fecha)
values ('9a6e1e78-cb27-491c-98ad-01b915582523', 'pago_proveedor', (select id from proveedores where nombre='Abelson' limit 1), 202128, 'ARS', 1, 'transferencia', current_date);
insert into movimientos_caja (obra_id, tipo, proveedor_id, monto, moneda, tipo_cambio, medio_pago, fecha)
values ('9a6e1e78-cb27-491c-98ad-01b915582523', 'pago_proveedor', (select id from proveedores where nombre='Sbg' limit 1), 526365, 'ARS', 1, 'transferencia', current_date);
insert into movimientos_caja (obra_id, tipo, proveedor_id, monto, moneda, tipo_cambio, medio_pago, fecha)
values ('9a6e1e78-cb27-491c-98ad-01b915582523', 'pago_proveedor', (select id from proveedores where nombre='Eliplay' limit 1), 79800, 'ARS', 1, 'transferencia', current_date);
insert into movimientos_caja (obra_id, tipo, proveedor_id, monto, moneda, tipo_cambio, medio_pago, fecha)
values ('9a6e1e78-cb27-491c-98ad-01b915582523', 'pago_proveedor', (select id from proveedores where nombre='Battista' limit 1), 310000, 'ARS', 1, 'transferencia', current_date);
insert into movimientos_caja (obra_id, tipo, proveedor_id, monto, moneda, tipo_cambio, medio_pago, fecha)
values ('9a6e1e78-cb27-491c-98ad-01b915582523', 'pago_proveedor', (select id from proveedores where nombre='Occhipinti' limit 1), 44416, 'ARS', 1, 'transferencia', current_date);
insert into movimientos_caja (obra_id, tipo, proveedor_id, monto, moneda, tipo_cambio, medio_pago, fecha)
values ('9a6e1e78-cb27-491c-98ad-01b915582523', 'pago_proveedor', (select id from proveedores where nombre='Tm' limit 1), 27310, 'ARS', 1, 'transferencia', current_date);
insert into movimientos_caja (obra_id, tipo, proveedor_id, monto, moneda, tipo_cambio, medio_pago, fecha)
values ('9a6e1e78-cb27-491c-98ad-01b915582523', 'pago_proveedor', (select id from proveedores where nombre='Missura' limit 1), 34707, 'ARS', 1, 'transferencia', current_date);
insert into movimientos_caja (obra_id, tipo, proveedor_id, monto, moneda, tipo_cambio, medio_pago, fecha)
values ('9a6e1e78-cb27-491c-98ad-01b915582523', 'pago_proveedor', (select id from proveedores where nombre='Lusso' limit 1), 21793, 'ARS', 1, 'transferencia', current_date);
insert into movimientos_caja (obra_id, tipo, proveedor_id, monto, moneda, tipo_cambio, medio_pago, fecha)
values ('9a6e1e78-cb27-491c-98ad-01b915582523', 'pago_proveedor', (select id from proveedores where nombre='Comercial' limit 1), 12511, 'ARS', 1, 'transferencia', current_date);
insert into movimientos_caja (obra_id, tipo, proveedor_id, monto, moneda, tipo_cambio, medio_pago, fecha)
values ('9a6e1e78-cb27-491c-98ad-01b915582523', 'pago_proveedor', (select id from proveedores where nombre='Grupo Refri' limit 1), 59564, 'ARS', 1, 'transferencia', current_date);
insert into movimientos_caja (obra_id, tipo, proveedor_id, monto, moneda, tipo_cambio, medio_pago, fecha)
values ('9a6e1e78-cb27-491c-98ad-01b915582523', 'pago_proveedor', (select id from proveedores where nombre='Jesus Cala Rodriguez' limit 1), 36000, 'ARS', 1, 'transferencia', current_date);
insert into movimientos_caja (obra_id, tipo, proveedor_id, monto, moneda, tipo_cambio, medio_pago, fecha)
values ('9a6e1e78-cb27-491c-98ad-01b915582523', 'pago_proveedor', (select id from proveedores where nombre='Jesus Cala Rodriguez' limit 1), 22021, 'ARS', 1, 'transferencia', current_date);
insert into movimientos_caja (obra_id, tipo, proveedor_id, monto, moneda, tipo_cambio, medio_pago, fecha)
values ('9a6e1e78-cb27-491c-98ad-01b915582523', 'pago_proveedor', (select id from proveedores where nombre='Parana' limit 1), 14390, 'ARS', 1, 'transferencia', current_date);
insert into movimientos_caja (obra_id, tipo, proveedor_id, monto, moneda, tipo_cambio, medio_pago, fecha)
values ('9a6e1e78-cb27-491c-98ad-01b915582523', 'pago_proveedor', (select id from proveedores where nombre='Miguel Pastore' limit 1), 13400, 'ARS', 1, 'transferencia', current_date);
insert into movimientos_caja (obra_id, tipo, proveedor_id, monto, moneda, tipo_cambio, medio_pago, fecha)
values ('9a6e1e78-cb27-491c-98ad-01b915582523', 'pago_proveedor', (select id from proveedores where nombre='Anton' limit 1), 70476, 'ARS', 1, 'transferencia', current_date);
insert into movimientos_caja (obra_id, tipo, proveedor_id, monto, moneda, tipo_cambio, medio_pago, fecha)
values ('9a6e1e78-cb27-491c-98ad-01b915582523', 'pago_proveedor', (select id from proveedores where nombre='Sergio' limit 1), 16800, 'ARS', 1, 'transferencia', current_date);
insert into movimientos_caja (obra_id, tipo, proveedor_id, monto, moneda, tipo_cambio, medio_pago, fecha)
values ('9a6e1e78-cb27-491c-98ad-01b915582523', 'pago_proveedor', (select id from proveedores where nombre='Hugo' limit 1), 27600, 'ARS', 1, 'transferencia', current_date);
insert into movimientos_caja (obra_id, tipo, proveedor_id, monto, moneda, tipo_cambio, medio_pago, fecha)
values ('9a6e1e78-cb27-491c-98ad-01b915582523', 'pago_proveedor', (select id from proveedores where nombre='Carlos Cabrera' limit 1), 50150, 'ARS', 1, 'transferencia', current_date);
insert into movimientos_caja (obra_id, tipo, proveedor_id, monto, moneda, tipo_cambio, medio_pago, fecha)
values ('9a6e1e78-cb27-491c-98ad-01b915582523', 'pago_proveedor', (select id from proveedores where nombre='Adrian Romano' limit 1), 26400, 'ARS', 1, 'transferencia', current_date);
insert into movimientos_caja (obra_id, tipo, proveedor_id, monto, moneda, tipo_cambio, medio_pago, fecha)
values ('9a6e1e78-cb27-491c-98ad-01b915582523', 'pago_proveedor', (select id from proveedores where nombre='Sbg' limit 1), 60300, 'ARS', 1, 'transferencia', current_date);
insert into movimientos_caja (obra_id, tipo, proveedor_id, monto, moneda, tipo_cambio, medio_pago, fecha)
values ('9a6e1e78-cb27-491c-98ad-01b915582523', 'pago_proveedor', (select id from proveedores where nombre='Jorge' limit 1), 76000, 'ARS', 1, 'transferencia', current_date);
insert into movimientos_caja (obra_id, tipo, proveedor_id, monto, moneda, tipo_cambio, medio_pago, fecha)
values ('9a6e1e78-cb27-491c-98ad-01b915582523', 'pago_proveedor', (select id from proveedores where nombre='Oscar' limit 1), 15000, 'ARS', 1, 'transferencia', current_date);
insert into movimientos_caja (obra_id, tipo, proveedor_id, monto, moneda, tipo_cambio, medio_pago, fecha)
values ('9a6e1e78-cb27-491c-98ad-01b915582523', 'pago_proveedor', (select id from proveedores where nombre='Saver' limit 1), 10000, 'ARS', 1, 'transferencia', current_date);
insert into movimientos_caja (obra_id, tipo, proveedor_id, monto, moneda, tipo_cambio, medio_pago, fecha)
values ('9a6e1e78-cb27-491c-98ad-01b915582523', 'pago_proveedor', (select id from proveedores where nombre='Alejandro Olmedo' limit 1), 23000, 'ARS', 1, 'transferencia', current_date);

-- Cobros del cliente (caja)
insert into movimientos_caja (obra_id, tipo, monto, moneda, tipo_cambio, medio_pago, fecha)
values ('9a6e1e78-cb27-491c-98ad-01b915582523', 'cobro_cliente', 91350, 'ARS', 1, 'transferencia', '2025-07-18');
insert into movimientos_caja (obra_id, tipo, monto, moneda, tipo_cambio, medio_pago, fecha)
values ('9a6e1e78-cb27-491c-98ad-01b915582523', 'cobro_cliente', 50000, 'ARS', 1, 'transferencia', '2025-09-08');
insert into movimientos_caja (obra_id, tipo, monto, moneda, tipo_cambio, medio_pago, fecha)
values ('9a6e1e78-cb27-491c-98ad-01b915582523', 'cobro_cliente', 10000, 'ARS', 1, 'transferencia', '2026-12-05');
insert into movimientos_caja (obra_id, tipo, monto, moneda, tipo_cambio, medio_pago, fecha)
values ('9a6e1e78-cb27-491c-98ad-01b915582523', 'cobro_cliente', 59400, 'ARS', 1, 'transferencia', '2026-12-30');
insert into movimientos_caja (obra_id, tipo, monto, moneda, tipo_cambio, medio_pago, fecha)
values ('9a6e1e78-cb27-491c-98ad-01b915582523', 'cobro_cliente', 201960, 'ARS', 1, 'transferencia', '2026-12-29');
insert into movimientos_caja (obra_id, tipo, monto, moneda, tipo_cambio, medio_pago, fecha)
values ('9a6e1e78-cb27-491c-98ad-01b915582523', 'cobro_cliente', 44416, 'ARS', 1, 'transferencia', '2026-12-31');
insert into movimientos_caja (obra_id, tipo, monto, moneda, tipo_cambio, medio_pago, fecha)
values ('9a6e1e78-cb27-491c-98ad-01b915582523', 'cobro_cliente', 30723, 'ARS', 1, 'transferencia', '2026-01-15');
insert into movimientos_caja (obra_id, tipo, monto, moneda, tipo_cambio, medio_pago, fecha)
values ('9a6e1e78-cb27-491c-98ad-01b915582523', 'cobro_cliente', 6000, 'ARS', 1, 'transferencia', '2026-01-21');
insert into movimientos_caja (obra_id, tipo, monto, moneda, tipo_cambio, medio_pago, fecha)
values ('9a6e1e78-cb27-491c-98ad-01b915582523', 'cobro_cliente', 10000, 'ARS', 1, 'transferencia', '2026-01-21');

-- Retiros de las socias
insert into retiros (obra_id, fecha, monto_nancy, monto_sol, moneda, tipo_cambio)
values ('9a6e1e78-cb27-491c-98ad-01b915582523', '2025-07-18', 45675, 45675, 'ARS', 1);
insert into retiros (obra_id, fecha, monto_nancy, monto_sol, moneda, tipo_cambio)
values ('9a6e1e78-cb27-491c-98ad-01b915582523', '2025-09-08', 25000, 25000, 'ARS', 1);

commit;
