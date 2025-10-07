<template>
  <div class="page">
    <header class="hdr">
      <h2>Reportes</h2>
      <div class="actions">
        <router-link class="btn link" to="/">⟵ Volver</router-link>
        <button class="btn" @click="refreshResumen" :disabled="loading">
          {{ loading ? 'Actualizando…' : 'Refrescar resumen' }}
        </button>
        <button class="btn outline" @click="exportCSV" :disabled="!rows.length">Exportar CSV</button>
      </div>
    </header>

    <section class="card">
      <h3>Resumen de misiones completadas por tipo</h3>

      <table v-if="rows.length" class="tbl">
        <thead>
          <tr>
            <th>Tipo</th>
            <th>Total</th>
            <th>Horas promedio</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="r in rows" :key="r.tipo">
            <td>{{ r.tipo }}</td>
            <td>{{ r.total }}</td>
            <td>{{ fmtHours(r.horas_promedio) }}</td>
          </tr>
        </tbody>
        <tfoot>
          <tr>
            <td><strong>Total</strong></td>
            <td><strong>{{ totalMisiones }}</strong></td>
            <td>—</td>
          </tr>
        </tfoot>
      </table>
      <p v-else class="muted">No hay datos aún.</p>
    </section>

    <section class="card">
      <h3>Visualización</h3>
      <div v-if="rows.length" class="bars">
        <div v-for="r in rows" :key="r.tipo" class="bar-row">
          <div class="bar-label">{{ r.tipo }}</div>
          <div class="bar-wrap">
            <div class="bar-fill" :style="{ width: pct(r.total) + '%'}"></div>
          </div>
          <div class="bar-value">{{ r.total }}</div>
        </div>
      </div>
      <p v-else class="muted">Carga datos para ver el gráfico.</p>
    </section>
  </div>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue'
import api from '../api/axios'

const rows = ref([])
const loading = ref(false)

const fmtHours = (h) => (h == null ? '0.00' : Number(h).toFixed(2))
const totalMisiones = computed(() => rows.value.reduce((a, r) => a + Number(r.total || 0), 0))
const maxTotal = computed(() => Math.max(1, ...rows.value.map(r => Number(r.total || 0))))
const pct = (val) => Math.round((Number(val || 0) / maxTotal.value) * 100)

async function fetchResumen() {
  const { data } = await api.get('/reportes/resumen')
  // Backend devuelve [{ tipo, total, horas_promedio }]
  rows.value = Array.isArray(data) ? data : []
}

async function refreshResumen() {
  try {
    loading.value = true
    await api.post('/reportes/resumen/refresh', {})
    await fetchResumen()
  } finally {
    loading.value = false
  }
}

function exportCSV() {
  const header = ['tipo', 'total', 'horas_promedio']
  const body = rows.value.map(r => [r.tipo, r.total, r.horas_promedio])
  const csv = [header, ...body].map(row => row.map(v => `"${String(v).replace(/"/g,'""')}"`).join(',')).join('\r\n')
  const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = 'reporte_resumen.csv'
  a.click()
  URL.revokeObjectURL(url)
}

onMounted(fetchResumen)
</script>

<style scoped>
.page { padding: 1.5rem; }
.hdr { display:flex; align-items:center; justify-content:space-between; margin-bottom: 1rem; }
.actions { display:flex; gap:.5rem; }
.card { background:#fff; border:1px solid #ddd; border-radius:10px; padding:1rem; margin-bottom: 1rem; }
.btn { padding:.45rem .75rem; border-radius:8px; border:1px solid #ddd; background:#0f62fe; color:#fff; cursor:pointer; }
.btn:disabled { opacity:.6; cursor:not-allowed; }
.btn.outline { background:#fff; color:#333; }
.btn.link { background:#fff; color:#0f62fe; border-color:#cfe2ff; }
.tbl { width:100%; border-collapse: collapse; margin-top:.5rem; }
.tbl th, .tbl td { border:1px solid #eee; padding:.5rem; text-align:left; }
.muted { color:#666; }

.bars { display:flex; flex-direction:column; gap:.5rem; margin-top:.5rem; }
.bar-row { display:grid; grid-template-columns: 140px 1fr 60px; align-items:center; gap:.5rem; }
.bar-label { font-weight:600; }
.bar-wrap { height:12px; background:#f1f5f9; border-radius:6px; overflow:hidden; border:1px solid #e5e7eb; }
.bar-fill { height:100%; background:#22c55e; }
.bar-value { text-align:right; }
</style>
