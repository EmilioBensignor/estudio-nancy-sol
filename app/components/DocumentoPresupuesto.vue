<script setup>
// Documento imprimible del presupuesto para el cliente.
// SOLO columnas F–K (rubro, detalle, valor, honorarios, total). Nunca costo ni ganancia.
// Se renderiza oculto en el detalle de obra; al imprimir (@media print) queda solo esta hoja.
import { fmtArs as fmt } from '~/composables/useFormato'

const props = defineProps({
  obra: { type: Object, default: null },
  items: { type: Array, default: () => [] },
  mostrarProveedor: { type: Boolean, default: false },
})

const hoy = new Date()
const fechaEmision = `${String(hoy.getDate()).padStart(2, '0')}/${String(hoy.getMonth() + 1).padStart(2, '0')}/${hoy.getFullYear()}`

const totalGeneral = computed(() => props.items.reduce((a, i) => a + Number(i.total_ars || 0), 0))
const totalHonorarios = computed(() => props.items.reduce((a, i) => a + Number(i.honorario_ars || 0), 0))
const totalValor = computed(() => props.items.reduce((a, i) => a + Number(i.valor_final_ars || 0), 0))
</script>

<template>
  <article class="doc" data-doc-presupuesto>
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
      <span class="doc__date">{{ fechaEmision }}</span>
    </section>

    <section class="doc__obra">
      <div class="doc__field">
        <span class="doc__field-label">Obra</span>
        <span class="doc__field-value">{{ obra?.nombre_direccion }}</span>
      </div>
      <div class="doc__field">
        <span class="doc__field-label">Cliente</span>
        <span class="doc__field-value">{{ obra?.cliente?.nombre }}</span>
      </div>
    </section>

    <table class="doc__table">
      <thead>
        <tr>
          <th class="col-rubro">Rubro</th>
          <th v-if="mostrarProveedor" class="col-prov">Proveedor</th>
          <th class="col-detalle">Detalle</th>
          <th class="col-num">Valor</th>
          <th class="col-num">Honorarios 15%</th>
          <th class="col-num">Total</th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="it in items" :key="it.id">
          <td class="col-rubro">{{ it.rubro?.nombre || '—' }}</td>
          <td v-if="mostrarProveedor" class="col-prov">{{ it.proveedor?.nombre || '—' }}</td>
          <td class="col-detalle">{{ it.detalle }}</td>
          <td class="col-num mono">{{ fmt(it.valor_final_ars) }}</td>
          <td class="col-num mono">{{ fmt(it.honorario_ars) }}</td>
          <td class="col-num mono col-total">{{ fmt(it.total_ars) }}</td>
        </tr>
      </tbody>
      <tfoot>
        <tr>
          <td :colspan="mostrarProveedor ? 3 : 2" class="doc__total-label">Total</td>
          <td class="col-num mono doc__total-value">{{ fmt(totalValor) }}</td>
          <td class="col-num mono">{{ fmt(totalHonorarios) }}</td>
          <td class="col-num mono doc__total-value">{{ fmt(totalGeneral) }}</td>
        </tr>
      </tfoot>
    </table>

    <section class="doc__notas">
      <p>HONORARIOS PROFESIONALES INCLUYEN: PROYECTO O ELABORACIÓN DE PROPUESTA, REALIZACIÓN DE CÓMPUTO Y PRESUPUESTO, REPLANTEO DE OBRA, ASESORAMIENTO EN GENERAL, DIRECCIÓN Y EJECUCIÓN</p>
      <p>DEBIDO A LA INESTABILIDAD DE PRECIOS, EL PRESUPUESTO PUEDE VARIAR</p>
      <p>NOTA 1. LOS VALORES SE AJUSTARAN LUEGO DEL REPLANTEO DE CADA GREMIO DE SER NECESARIO</p>
      <p>NOTA 2. FORMA DE PAGO: SE VERÁ SEGÚN CADA GREMIO</p>
      <p>NOTA 3: FORMA DE PAGO HONORARIOS: a convenir</p>
      <p>NOTA 4: LOS ENVÍOS, DE SER NECESARIOS, NO ESTAN INCLUIDOS.</p>
    </section>
  </article>
</template>

<style scoped>
/* Documento A4 (210mm ≈ 794px a 96dpi) */
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

/* Fecha del documento */
.doc__bar {
  display: flex;
  justify-content: flex-end;
  padding: 16px 0 0;
}
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
.col-rubro { width: 17%; font-weight: 600; color: #1c1a17; }
.col-prov { width: 16%; color: #45423c; }
.col-detalle { color: #45423c; }
.col-total { font-weight: 600; color: #1c1a17; }
.mono { font-variant-numeric: tabular-nums; white-space: nowrap; }

.doc__table tfoot td { padding: 16px 10px; border-top: 2px solid #1c1a17; border-bottom: none; }
.doc__total-label { font-size: 12px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.08em; }
.doc__total-value { font-size: 18px; font-weight: 700; letter-spacing: -0.01em; }

.doc__notas {
  margin-top: 36px;
  padding-top: 22px;
  border-top: 1px solid #d8d4cc;
  font-size: 11.5px;
  color: #45423c;
  line-height: 1.6;
}
/* El texto viene en mayúsculas del Excel; se muestra en caja normal con
   inicial mayúscula, sin alterar el contenido literal. */
.doc__notas p { text-transform: lowercase; }
.doc__notas p::first-letter { text-transform: uppercase; }
.doc__notas p + p { margin-top: 5px; }

/* Al imprimir: @page tiene margin 0 (oculta headers del navegador), así que
   el documento aporta su propio margen de hoja con padding. */
@media print {
  .doc {
    max-width: none;
    margin: 0;
    padding: 18mm 16mm;
  }
}
</style>
