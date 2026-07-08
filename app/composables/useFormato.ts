// Helpers de formato compartidos (moneda y fecha).

// Formato moneda ARS. Conserva el signo siempre (nunca abs sin signo).
export function fmtArs(val: number | null | undefined): string {
  if (val == null) return '—'
  const n = Number(val)
  const abs = Math.abs(n).toLocaleString('es-AR', { minimumFractionDigits: 0, maximumFractionDigits: 0 })
  return `${n < 0 ? '-' : ''}$ ${abs}`
}

// Formato moneda USD. Conserva el signo siempre.
export function fmtUsd(val: number | null | undefined): string {
  if (val == null) return '—'
  const n = Number(val)
  const abs = Math.abs(n).toLocaleString('es-AR', { minimumFractionDigits: 0, maximumFractionDigits: 0 })
  return `${n < 0 ? '-' : ''}USD ${abs}`
}

export function fmtFecha(iso: string): string {
  const [y = '', m = '', d = ''] = iso.split('-')
  return `${d}/${m}/${y.slice(2)}`
}

// Intercala filas de subtotal por rubro entre los items. Asume items ya
// ordenados por rubro (si no, agrupa mal). Devuelve una lista mixta:
// { tipo: 'item', it } | { tipo: 'subtotal', rubro, valor, honorario, total }.
export function agruparPorRubro(items: any[]): any[] {
  const filas: any[] = []
  let acum: any = null
  // Subtotal solo si el rubro tiene más de una fila (con una sola es redundante).
  const cerrar = () => {
    if (acum && acum.n > 1) filas.push({ tipo: 'subtotal', ...acum })
  }
  for (const it of items) {
    const rubro = it.rubro?.nombre || '—'
    if (!acum || acum.rubro !== rubro) {
      cerrar()
      acum = { rubro, n: 0, valor: 0, honorario: 0, total: 0 }
    }
    acum.n += 1
    acum.valor += Number(it.valor_final_ars || 0)
    acum.honorario += Number(it.honorario_ars || 0)
    acum.total += Number(it.total_ars || 0)
    filas.push({ tipo: 'item', it })
  }
  cerrar()
  return filas
}
