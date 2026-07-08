<script setup>
// Documento imprimible genérico para reportes de una obra (pagos recibidos,
// pagos a proveedores, detalle de proveedor). Recibe columnas + filas ya
// armadas; no calcula nada del negocio.
import { fmtArs as fmt } from '~/composables/useFormato'

const props = defineProps({
  obra: { type: Object, default: null },
  titulo: { type: String, default: 'Reporte' },
  // Subtítulo opcional (ej. nombre del proveedor en el detalle).
  subtitulo: { type: String, default: '' },
  // [{ key, label, num }] — num alinea a la derecha y usa fuente mono.
  columnas: { type: Array, default: () => [] },
  // Filas: cada una es un objeto con las keys de columnas. El valor puede venir
  // ya formateado (string) o crudo (number): si es number, se formatea con fmt.
  filas: { type: Array, default: () => [] },
  // Filas de pie: [{ label, valor }] apiladas a la derecha.
  totales: { type: Array, default: () => [] },
})

const hoy = new Date()
const fechaEmision = `${String(hoy.getDate()).padStart(2, '0')}/${String(hoy.getMonth() + 1).padStart(2, '0')}/${hoy.getFullYear()}`

function celda(fila, col) {
  const v = fila[col.key]
  if (col.num && typeof v === 'number') return fmt(v)
  return v ?? '—'
}
</script>

<template>
  <article class="doc" data-doc-reporte>
    <header class="doc__head">
      <div class="doc__estudio-names">
        <span class="doc__name">Nancy Bensignor · Solana Rutenberg</span>
      </div>
      <div class="doc__contacto">
        <span>bensignornancy@gmail.com</span>
        <span>solrutenberg@gmail.com</span>
      </div>
    </header>

    <section class="doc__bar">
      <span class="doc__title">{{ titulo }}</span>
      <span class="doc__date">{{ fechaEmision }}</span>
    </section>

    <section class="doc__obra">
      <div class="doc__field">
        <span class="doc__field-label">Obra</span>
        <span class="doc__field-value">{{ obra?.nombre_direccion }}</span>
      </div>
      <div v-if="subtitulo" class="doc__field">
        <span class="doc__field-label">Proveedor</span>
        <span class="doc__field-value">{{ subtitulo }}</span>
      </div>
    </section>

    <table class="doc__table">
      <thead>
        <tr>
          <th v-for="col in columnas" :key="col.key" :class="{ 'col-num': col.num }">{{ col.label }}</th>
        </tr>
      </thead>
      <tbody>
        <tr v-if="!filas.length">
          <td :colspan="columnas.length" class="doc__vacio">Sin registros.</td>
        </tr>
        <tr v-for="(fila, i) in filas" :key="i">
          <td v-for="col in columnas" :key="col.key" :class="[col.num ? 'col-num mono' : '']">{{ celda(fila, col) }}</td>
        </tr>
      </tbody>
      <tfoot v-if="totales.length">
        <tr v-for="(t, i) in totales" :key="i">
          <td :colspan="columnas.length - 1" class="doc__total-label">{{ t.label }}</td>
          <td class="col-num mono doc__total-value">{{ typeof t.valor === 'number' ? fmt(t.valor) : t.valor }}</td>
        </tr>
      </tfoot>
    </table>
  </article>
</template>

<style scoped>
.doc {
  max-width: 794px;
  margin: 0 auto;
  background: #fff;
  padding: 56px 56px 48px;
  color: #1c1a17;
  font-family: 'DM Sans', system-ui, sans-serif;
  font-size: 13px;
  line-height: 1.5;
}

.doc__head {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  padding-bottom: 20px;
  border-bottom: 2px solid #1c1a17;
}
.doc__estudio-names { display: flex; flex-direction: column; gap: 4px; }
.doc__name { font-size: 18px; font-weight: 600; letter-spacing: -0.01em; }
.doc__contacto {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 2px;
  font-size: 11.5px;
  color: #6b6860;
  padding-top: 2px;
}

.doc__bar {
  display: flex;
  align-items: baseline;
  justify-content: space-between;
  padding: 16px 0 0;
}
.doc__title { font-size: 15px; font-weight: 600; letter-spacing: -0.01em; }
.doc__date { font-size: 13px; font-variant-numeric: tabular-nums; color: #45423c; }

.doc__obra { display: flex; gap: 48px; padding: 20px 0 26px; }
.doc__field { display: flex; flex-direction: column; gap: 4px; }
.doc__field-label { font-size: 11px; font-weight: 600; text-transform: uppercase; letter-spacing: 0.07em; color: #6b6860; }
.doc__field-value { font-size: 15px; font-weight: 500; }

.doc__table { width: 100%; border-collapse: collapse; }
.doc__table th {
  text-align: left;
  font-size: 11px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  color: #6b6860;
  padding: 0 10px 9px;
  border-bottom: 1px solid #d8d4cc;
  white-space: nowrap;
}
.doc__table td { padding: 12px 10px; border-bottom: 1px solid #ece9e3; vertical-align: top; font-size: 13px; }
.col-num { text-align: right; color: #45423c; }
.doc__table th.col-num { text-align: right; }
.mono { font-variant-numeric: tabular-nums; white-space: nowrap; }
.doc__vacio { color: #6b6860; font-style: italic; }

.doc__table tfoot td { padding: 16px 10px; border-top: 2px solid #1c1a17; border-bottom: none; }
.doc__total-label { font-size: 12px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.08em; }
.doc__total-value { font-size: 18px; font-weight: 700; letter-spacing: -0.01em; }

@media print {
  .doc { max-width: none; padding: 18mm 16mm; }
}
</style>
