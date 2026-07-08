// Capa de acceso a datos sobre Supabase. Centraliza todas las queries de la app.
// Devuelve datos crudos; las pages arman su propio estado reactivo.
// SSR-safe: useSupabase() solo corre en cliente (la app es SPA, ssr:false).

export function useDb() {
  const sb = () => useSupabase()

  // ─── Clientes ──────────────────────────────────────────────────────────
  async function getClientes() {
    // Trae clientes + sus obras (un cliente puede tener varias)
    const { data, error } = await sb()
      .from('clientes')
      .select('*, obras(id, slug, nombre_direccion)')
      .order('created_at', { ascending: false })
    if (error) throw error
    return data
  }

  async function getCliente(id) {
    const { data, error } = await sb().from('clientes').select('*').eq('id', id).single()
    if (error) throw error
    return data
  }

  async function crearCliente(cliente) {
    const { data, error } = await sb().from('clientes').insert(cliente).select().single()
    if (error) throw error
    return data
  }

  async function actualizarCliente(id, cambios) {
    const { data, error } = await sb().from('clientes').update(cambios).eq('id', id).select().single()
    if (error) throw error
    return data
  }

  // Cuenta obras asociadas: si > 0 no se puede eliminar (guarda de integridad).
  async function contarObrasDeCliente(id) {
    const { count, error } = await sb()
      .from('obras')
      .select('id', { count: 'exact', head: true })
      .eq('cliente_id', id)
    if (error) throw error
    return count || 0
  }

  async function eliminarCliente(id) {
    const { error } = await sb().from('clientes').delete().eq('id', id)
    if (error) throw error
  }

  // ─── Proveedores ───────────────────────────────────────────────────────
  async function getProveedores() {
    const { data, error } = await sb()
      .from('proveedores')
      .select('*, rubro:rubros(id, nombre)')
      .order('created_at', { ascending: false })
    if (error) throw error
    return data
  }

  async function getProveedor(id) {
    const { data, error } = await sb()
      .from('proveedores')
      .select('*, rubro:rubros(id, nombre)')
      .eq('id', id)
      .single()
    if (error) throw error
    return data
  }

  async function crearProveedor(proveedor) {
    const { data, error } = await sb().from('proveedores').insert(proveedor).select().single()
    if (error) throw error
    return data
  }

  async function actualizarProveedor(id, cambios) {
    const { data, error } = await sb().from('proveedores').update(cambios).eq('id', id).select().single()
    if (error) throw error
    return data
  }

  // Cuenta usos del proveedor en items y movimientos: si > 0 no se elimina.
  async function contarUsosDeProveedor(id) {
    const [items, movs] = await Promise.all([
      sb().from('presupuesto_items').select('id', { count: 'exact', head: true }).eq('proveedor_id', id),
      sb().from('movimientos_caja').select('id', { count: 'exact', head: true }).eq('proveedor_id', id),
    ])
    if (items.error) throw items.error
    if (movs.error) throw movs.error
    return (items.count || 0) + (movs.count || 0)
  }

  async function eliminarProveedor(id) {
    const { error } = await sb().from('proveedores').delete().eq('id', id)
    if (error) throw error
  }

  // Deuda del proveedor por obra: presupuestado (sus items) - pagado (sus movimientos).
  // Mismo cálculo que la tab Proveedores de una obra, agrupado acá por obra.
  async function getDeudaProveedorPorObra(proveedorId) {
    const [{ data: items, error: e1 }, { data: movs, error: e2 }] = await Promise.all([
      sb()
        .from('v_presupuesto_items')
        .select('obra_id, valor_proveedor_ars, obra:obras(nombre_direccion, slug)')
        .eq('proveedor_id', proveedorId),
      sb()
        .from('movimientos_caja')
        .select('obra_id, monto, tipo_cambio, obra:obras(nombre_direccion, slug)')
        .eq('proveedor_id', proveedorId)
        .eq('tipo', 'pago_proveedor'),
    ])
    if (e1) throw e1
    if (e2) throw e2

    const map = new Map()
    const get = (obraId, obra) => {
      if (!map.has(obraId)) map.set(obraId, { obraId, obra, presupuestado: 0, pagado: 0 })
      return map.get(obraId)
    }
    for (const it of items || []) get(it.obra_id, it.obra).presupuestado += Number(it.valor_proveedor_ars || 0)
    for (const m of movs || []) get(m.obra_id, m.obra).pagado += Number(m.monto) * Number(m.tipo_cambio)
    return [...map.values()]
      .map((r) => ({ ...r, debo: r.presupuestado - r.pagado }))
      .sort((a, b) => (a.obra?.nombre_direccion || '').localeCompare(b.obra?.nombre_direccion || ''))
  }

  // ─── Rubros (catálogo + crear al vuelo) ────────────────────────────────
  async function getRubros() {
    const { data, error } = await sb().from('rubros').select('id, nombre').order('nombre')
    if (error) throw error
    return data
  }

  // Busca un rubro por nombre (case-insensitive); si no existe lo crea. Devuelve el id.
  async function resolverRubroId(nombre) {
    const limpio = (nombre || '').trim()
    if (!limpio) return null
    const { data: existente } = await sb()
      .from('rubros')
      .select('id')
      .ilike('nombre', limpio)
      .maybeSingle()
    if (existente) return existente.id
    const { data: nuevo, error } = await sb()
      .from('rubros')
      .insert({ nombre: limpio })
      .select('id')
      .single()
    if (error) throw error
    return nuevo.id
  }

  // ─── Obras ─────────────────────────────────────────────────────────────
  // Lista de obras con sus saldos (join a v_saldos_obra) para la home.
  async function getObras() {
    const { data: obras, error } = await sb()
      .from('obras')
      .select('*, cliente:clientes(id, nombre)')
      .order('created_at', { ascending: false })
    if (error) throw error

    const { data: saldos, error: e2 } = await sb().from('v_saldos_obra').select('*')
    if (e2) throw e2

    const porObra = Object.fromEntries((saldos || []).map((s) => [s.obra_id, s]))
    return (obras || []).map((o) => ({
      ...o,
      cliente_nombre: o.cliente?.nombre ?? '',
      saldo_a_cobrar_ars: porObra[o.id]?.saldo_a_cobrar_ars ?? 0,
      saldo_caja_ars: porObra[o.id]?.saldo_caja_ars ?? 0,
    }))
  }

  // Acepta UUID o slug en la URL. Si parece UUID busca por id, sino por slug.
  const esUuid = (s) => /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(s)

  async function getObra(idOrSlug) {
    const { data, error } = await sb()
      .from('obras')
      .select('*, cliente:clientes(id, nombre, email, telefono)')
      .eq(esUuid(idOrSlug) ? 'id' : 'slug', idOrSlug)
      .single()
    if (error) throw error
    return data
  }

  // Convierte un texto a slug url-safe (sin acentos, minúsculas, guiones).
  function slugify(texto) {
    return (texto || '')
      .normalize('NFD').replace(/[̀-ͯ]/g, '')
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, '-')
      .replace(/^-+|-+$/g, '')
  }

  // Genera un slug único: si 'ramsay-1945' existe, prueba '-2', '-3', etc.
  async function generarSlugUnico(base) {
    const raiz = slugify(base) || 'obra'
    const { data } = await sb().from('obras').select('slug').like('slug', `${raiz}%`)
    const usados = new Set((data || []).map((o) => o.slug))
    if (!usados.has(raiz)) return raiz
    let n = 2
    while (usados.has(`${raiz}-${n}`)) n++
    return `${raiz}-${n}`
  }

  async function crearObra(obra) {
    const slug = await generarSlugUnico(obra.nombre_direccion)
    const { data, error } = await sb().from('obras').insert({ ...obra, slug }).select().single()
    if (error) throw error
    return data
  }

  async function actualizarObra(id, cambios) {
    const { data, error } = await sb().from('obras').update(cambios).eq('id', id).select().single()
    if (error) throw error
    return data
  }

  // Cuenta movimientos + items + retiros de una obra: si > 0 no se elimina.
  async function contarUsosDeObra(id) {
    const [movs, items, retiros] = await Promise.all([
      sb().from('movimientos_caja').select('id', { count: 'exact', head: true }).eq('obra_id', id),
      sb().from('presupuesto_items').select('id', { count: 'exact', head: true }).eq('obra_id', id),
      sb().from('retiros').select('id', { count: 'exact', head: true }).eq('obra_id', id),
    ])
    if (movs.error) throw movs.error
    if (items.error) throw items.error
    if (retiros.error) throw retiros.error
    return (movs.count || 0) + (items.count || 0) + (retiros.count || 0)
  }

  async function eliminarObra(id) {
    const { error } = await sb().from('obras').delete().eq('id', id)
    if (error) throw error
  }

  async function getSaldosObra(obraId) {
    const { data, error } = await sb().from('v_saldos_obra').select('*').eq('obra_id', obraId).maybeSingle()
    if (error) throw error
    return data
  }

  // Bloque de control contable de la obra (5 saldos + control que debe dar 0).
  async function getControl(obraId) {
    const { data, error } = await sb().from('v_control_obra').select('*').eq('obra_id', obraId).maybeSingle()
    if (error) throw error
    return data
  }

  // ─── Presupuesto ───────────────────────────────────────────────────────
  // Ítems con columnas derivadas (ganancia/honorario/total ya calculados en ARS).
  async function getItems(obraId) {
    const { data, error } = await sb()
      .from('v_presupuesto_items')
      .select('*, rubro:rubros(nombre), proveedor:proveedores(nombre)')
      .eq('obra_id', obraId)
      .order('fecha')
    if (error) throw error
    return data
  }

  async function crearItem(item) {
    const { data, error } = await sb().from('presupuesto_items').insert(item).select().single()
    if (error) throw error
    return data
  }

  async function actualizarItem(id, cambios) {
    const { data, error } = await sb().from('presupuesto_items').update(cambios).eq('id', id).select().single()
    if (error) throw error
    return data
  }

  async function eliminarItem(id) {
    const { error } = await sb().from('presupuesto_items').delete().eq('id', id)
    if (error) throw error
  }

  // Presupuesto para EXPORTAR al cliente: SOLO columnas F–K (rubro, detalle, valores,
  // honorario, total). NUNCA costo de proveedor ni ganancia. Defensa en profundidad:
  // se seleccionan explícitamente solo los campos públicos.
  async function getPresupuestoCliente(obraId) {
    const { data, error } = await sb()
      .from('v_presupuesto_items')
      .select('id, detalle, valor_presupuesto_ars, valor_final_ars, honorario_ars, total_ars, rubro:rubros(nombre), proveedor:proveedores(nombre)')
      .eq('obra_id', obraId)
      .order('fecha')
    if (error) throw error
    return data
  }

  // ─── Caja ──────────────────────────────────────────────────────────────
  // Movimientos con saldo acumulado (de v_caja_saldo) + descripción/proveedor.
  async function getMovimientos(obraId) {
    // Orden de visualización: más reciente arriba. El saldo acumulado se calcula
    // aparte en v_caja_saldo (cronológico ascendente), así que el orden de esta
    // lista no afecta el cálculo del acumulado.
    const { data: movs, error } = await sb()
      .from('movimientos_caja')
      .select('*, proveedor:proveedores(nombre)')
      .eq('obra_id', obraId)
      .order('fecha', { ascending: false })
      .order('created_at', { ascending: false })
    if (error) throw error

    const { data: saldo, error: e2 } = await sb()
      .from('v_caja_saldo')
      .select('id, saldo_acumulado_ars')
      .eq('obra_id', obraId)
    if (e2) throw e2
    const porId = Object.fromEntries((saldo || []).map((s) => [s.id, s.saldo_acumulado_ars]))
    return (movs || []).map((m) => ({ ...m, saldo_acumulado_ars: porId[m.id] ?? null }))
  }

  async function crearMovimiento(mov) {
    const { data, error } = await sb().from('movimientos_caja').insert(mov).select().single()
    if (error) throw error
    return data
  }

  async function actualizarMovimiento(id, cambios) {
    const { data, error } = await sb().from('movimientos_caja').update(cambios).eq('id', id).select().single()
    if (error) throw error
    return data
  }

  async function eliminarMovimiento(id) {
    const { error } = await sb().from('movimientos_caja').delete().eq('id', id)
    if (error) throw error
  }

  // ─── Retiros ───────────────────────────────────────────────────────────
  async function getRetiros(obraId) {
    const { data, error } = await sb()
      .from('retiros')
      .select('*')
      .eq('obra_id', obraId)
      .order('fecha')
    if (error) throw error
    return data
  }

  // Retiros de todas las obras (vista general para las socias), con el nombre de obra.
  async function getRetirosGlobales() {
    const { data, error } = await sb()
      .from('retiros')
      .select('*, obra:obras(nombre_direccion, slug)')
      .order('fecha', { ascending: false })
    if (error) throw error
    return data
  }

  async function getConvergencia(obraId) {
    const { data, error } = await sb()
      .from('v_retiros_convergencia')
      .select('*')
      .eq('obra_id', obraId)
      .maybeSingle()
    if (error) throw error
    return data
  }

  async function crearRetiro(retiro) {
    const { data, error } = await sb().from('retiros').insert(retiro).select().single()
    if (error) throw error
    return data
  }

  async function actualizarRetiro(id, cambios) {
    const { data, error } = await sb().from('retiros').update(cambios).eq('id', id).select().single()
    if (error) throw error
    return data
  }

  async function eliminarRetiro(id) {
    const { error } = await sb().from('retiros').delete().eq('id', id)
    if (error) throw error
  }

  // ─── Settings ──────────────────────────────────────────────────────────
  async function getSettings() {
    const { data, error } = await sb().from('settings').select('*').limit(1).maybeSingle()
    if (error) throw error
    return data
  }

  return {
    getClientes, getCliente, crearCliente, actualizarCliente, contarObrasDeCliente, eliminarCliente,
    getProveedores, getProveedor, crearProveedor, actualizarProveedor, contarUsosDeProveedor, eliminarProveedor,
    getDeudaProveedorPorObra,
    getRubros, resolverRubroId,
    getObras, getObra, crearObra, actualizarObra, contarUsosDeObra, eliminarObra, getSaldosObra, getControl,
    getItems, crearItem, actualizarItem, eliminarItem, getPresupuestoCliente,
    getMovimientos, crearMovimiento, actualizarMovimiento, eliminarMovimiento,
    getRetiros, getRetirosGlobales, getConvergencia, crearRetiro, actualizarRetiro, eliminarRetiro,
    getSettings,
  }
}
