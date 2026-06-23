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
