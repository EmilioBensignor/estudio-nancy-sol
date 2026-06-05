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
      .select('*, obras(id, nombre_direccion)')
      .order('created_at', { ascending: false })
    if (error) throw error
    return data
  }

  async function crearCliente(cliente) {
    const { data, error } = await sb().from('clientes').insert(cliente).select().single()
    if (error) throw error
    return data
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

  async function crearProveedor(proveedor) {
    const { data, error } = await sb().from('proveedores').insert(proveedor).select().single()
    if (error) throw error
    return data
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

  async function getObra(id) {
    const { data, error } = await sb()
      .from('obras')
      .select('*, cliente:clientes(id, nombre, email, telefono)')
      .eq('id', id)
      .single()
    if (error) throw error
    return data
  }

  async function crearObra(obra) {
    const { data, error } = await sb().from('obras').insert(obra).select().single()
    if (error) throw error
    return data
  }

  async function actualizarObra(id, cambios) {
    const { data, error } = await sb().from('obras').update(cambios).eq('id', id).select().single()
    if (error) throw error
    return data
  }

  async function getSaldosObra(obraId) {
    const { data, error } = await sb().from('v_saldos_obra').select('*').eq('obra_id', obraId).maybeSingle()
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

  // Presupuesto para EXPORTAR al cliente: SOLO columnas F–K (rubro, detalle, valores,
  // honorario, total). NUNCA costo de proveedor ni ganancia. Defensa en profundidad:
  // se seleccionan explícitamente solo los campos públicos.
  async function getPresupuestoCliente(obraId) {
    const { data, error } = await sb()
      .from('v_presupuesto_items')
      .select('id, detalle, valor_presupuesto_ars, valor_final_ars, honorario_ars, total_ars, rubro:rubros(nombre)')
      .eq('obra_id', obraId)
      .order('fecha')
    if (error) throw error
    return data
  }

  // ─── Caja ──────────────────────────────────────────────────────────────
  // Movimientos con saldo acumulado (de v_caja_saldo) + descripción/proveedor.
  async function getMovimientos(obraId) {
    const { data: movs, error } = await sb()
      .from('movimientos_caja')
      .select('*, proveedor:proveedores(nombre)')
      .eq('obra_id', obraId)
      .order('fecha')
      .order('created_at')
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

  // ─── Settings ──────────────────────────────────────────────────────────
  async function getSettings() {
    const { data, error } = await sb().from('settings').select('*').limit(1).maybeSingle()
    if (error) throw error
    return data
  }

  return {
    getClientes, crearCliente,
    getProveedores, crearProveedor,
    getRubros, resolverRubroId,
    getObras, getObra, crearObra, actualizarObra, getSaldosObra,
    getItems, crearItem, getPresupuestoCliente,
    getMovimientos, crearMovimiento,
    getRetiros, getConvergencia, crearRetiro,
    getSettings,
  }
}
