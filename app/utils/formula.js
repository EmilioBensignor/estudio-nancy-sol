// Montos con fórmula, como en el Excel: "=1000*1,21", "350x12", "1500+2300+800".
// Acepta + - * / x y paréntesis. Coma decimal; el punto es de miles solo si agrupa de a 3
// ("1.210" = 1210, "1.5" = 1,5).
const limpiar = (texto) => String(texto ?? '').trim().replace(/^=/, '').trim()

export function esFormula(texto) {
  return /[-+*/()xX]/.test(limpiar(texto).replace(/^-/, ''))
}

export function formulaDe(texto) {
  return esFormula(texto) ? limpiar(texto) : null
}

function numero(t) {
  if (/^\d{1,3}(\.\d{3})+$/.test(t)) return Number(t.replaceAll('.', ''))
  if (t.includes(',')) return Number(t.replaceAll('.', '').replace(',', '.'))
  return Number(t)
}

export function evaluarFormula(texto) {
  const tokens = limpiar(texto).replace(/\s+/g, '').replace(/[xX]/g, '*').match(/[\d.,]+|./g) || []
  let i = 0
  const factor = () => {
    const t = tokens[i++]
    if (t === '-') return -factor()
    if (t === '+') return factor()
    if (t === '(') {
      const v = suma()
      return tokens[i++] === ')' ? v : NaN
    }
    return /^[\d.,]+$/.test(t || '') ? numero(t) : NaN
  }
  const producto = () => {
    let v = factor()
    while (tokens[i] === '*' || tokens[i] === '/') v = tokens[i++] === '*' ? v * factor() : v / factor()
    return v
  }
  const suma = () => {
    let v = producto()
    while (tokens[i] === '+' || tokens[i] === '-') v = tokens[i++] === '+' ? v + producto() : v - producto()
    return v
  }
  if (!tokens.length) return NaN
  const v = suma()
  return i === tokens.length && Number.isFinite(v) ? Math.round(v * 100) / 100 : NaN
}
