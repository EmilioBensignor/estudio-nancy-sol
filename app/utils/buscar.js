// Búsqueda por inicial: "a" encuentra lo que empieza con A (sin importar tildes ni mayúsculas).
const plano = (s) => String(s || '').normalize('NFD').replace(/[̀-ͯ]/g, '').toLowerCase()

export function empiezaCon(texto, q) {
  return plano(texto).startsWith(plano(q).trim())
}
