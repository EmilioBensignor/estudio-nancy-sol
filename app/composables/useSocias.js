// Personas que pueden retirar. key = sufijo de columnas en DB:
// obras.retira_<key>, obras.split_<key>_override, retiros.monto_<key>.
export const SOCIAS = [
  { key: 'nancy', nombre: 'Nancy' },
  { key: 'sol', nombre: 'Solana' },
  { key: 'jessica', nombre: 'Jessica' },
]

// Socias que retiran en una obra (según sus switches).
export function sociasDeObra(obra) {
  return SOCIAS.filter((s) => obra?.[`retira_${s.key}`])
}

// Reparto parejo entre las activas, en % enteros que suman 100 (ej. 34/33/33).
export function repartoParejo(keys) {
  const base = Math.floor(100 / (keys.length || 1))
  const resto = 100 - base * keys.length
  return Object.fromEntries(keys.map((k, i) => [k, String(i === 0 ? base + resto : base)]))
}
