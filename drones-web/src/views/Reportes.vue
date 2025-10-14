<template>
  <div class="dashboard-container">
    <aside class="sidebar">
      <div class="sidebar-header">
        <span class="sidebar-logo">D</span>
        <h2>Drone<span>.io</span></h2>
      </div>
      <nav class="sidebar-nav">
        <RouterLink to="/dashboard" class="sidebar-link">
          <span class="icon">📊</span>
          <span>Dashboard</span>
        </RouterLink>
        <RouterLink to="/drones" class="sidebar-link">
          <span class="icon">🛸</span>
          <span>Drones</span>
        </RouterLink>
        <RouterLink to="/misiones" class="sidebar-link">
          <span class="icon">🎯</span>
          <span>Misiones</span>
        </RouterLink>
        <RouterLink to="/reportes" class="sidebar-link active">
          <span class="icon">📈</span>
          <span>Reportes</span>
        </RouterLink>
      </nav>
      <div class="sidebar-footer">
        <button class="logout-btn" @click="logout">
          <span>Cerrar sesión</span>
        </button>
      </div>
    </aside>
    <main class="main-content reportes-bg">
      <header class="content-header">
        <h1 class="header-title">Reportes</h1>
        <div class="actions">
          <RouterLink class="refresh-btn" to="/">Volver</RouterLink>
          <button class="refresh-btn" @click="refreshResumen" :disabled="loading">
            {{ loading ? 'Actualizando…' : 'Refrescar resumen' }}
          </button>
          <button class="refresh-btn outline" @click="exportCSV" :disabled="!rows.length">Exportar CSV</button>
        </div>
      </header>
      <div class="dashboard-content">
        <div class="section-title">Resumen de misiones completadas por tipo</div>
        <div class="data-card">
          <div class="table-container">
            <table v-if="rows.length">
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
            <p v-else class="empty-msg">No hay datos aún.</p>
          </div>
        </div>
        <div class="section-title">Visualización</div>
        <div class="data-card">
          <div v-if="rows.length" class="bars">
            <div v-for="r in rows" :key="r.tipo" class="bar-row">
              <div class="bar-label">{{ r.tipo }}</div>
              <div class="bar-wrap">
                <div class="bar-fill" :style="{ width: pct(r.total) + '%'}"></div>
              </div>
              <div class="bar-value">{{ r.total }}</div>
            </div>
          </div>
          <p v-else class="empty-msg">Carga datos para ver el gráfico.</p>
        </div>
      </div>
    </main>
  </div>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue'
import { RouterLink, useRouter } from 'vue-router'
import { useAuthStore } from '../stores/auth'
import api from '../api/axios'

const auth = useAuthStore()
const router = useRouter()

const logout = () => {
  auth.logout()
  router.push('/login')
}

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
@import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;600;700&display=swap');
.dashboard-container {
  font-family: 'Inter', Arial, Helvetica, sans-serif;
  display: flex;
  min-height: 100vh;
  background: #f8fafc;
}
.sidebar {
  width: 260px;
  background: #fff;
  border-right: 1px solid #e0e7ff;
  display: flex;
  flex-direction: column;
  position: fixed;
  height: 100vh;
  box-shadow: 2px 0 10px rgba(0,0,0,0.05);
  z-index: 10;
}
.sidebar-header {
  padding: 1.5rem;
  display: flex;
  align-items: center;
  gap: 10px;
  border-bottom: 1px solid #e0e7ff;
}
.sidebar-logo {
  width: 40px;
  height: 40px;
  background: #6366f1;
  color: white;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 600;
  font-size: 20px;
  box-shadow: 0 2px 8px rgba(99,102,241,0.25);
}
.sidebar-header h2 {
  color: #4fe6e5;
  font-weight: 600;
  font-size: 1.5rem;
  margin: 0;
}
.sidebar-header h2 span {
  color: #6366f1;
}
.sidebar-nav {
  flex: 1;
  padding: 1.5rem 0;
}
.sidebar-link {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 12px 1.5rem;
  color: #4b5563;
  text-decoration: none;
  font-weight: 500;
  transition: background 0.2s, color 0.2s;
  border-left: 3px solid transparent;
  margin-bottom: 4px;
}
.sidebar-link:hover {
  background: #eef2ff;
  color: #6366f1;
}
.sidebar-link.active {
  background: #eef2ff;
  color: #6366f1;
  border-left-color: #6366f1;
  font-weight: 600;
}
.sidebar-footer {
  padding: 1.5rem;
  border-top: 1px solid #e0e7ff;
}
.logout-btn {
  width: 100%;
  padding: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  background: #f8fafc;
  color: #4b5563;
  border: 1px solid #e0e7ff;
  border-radius: 8px;
  font-weight: 600;
  cursor: pointer;
  transition: background 0.2s; 
}
.logout-btn:hover {
  background: #d32f2fe8;
  color: black;
}
.main-content {
  flex: 1;
  margin-left: 260px;
  padding: 2rem;
}
.content-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 2rem;
  padding-bottom: 1.5rem;
  border-bottom: 1px solid #e0e7ff;
}
.header-title {
  font-size: 2rem;
  font-weight: 600;
  color: #1f2937;
  margin: 0;
}
.actions {
  display: flex;
  gap: 0.5rem;
}
.refresh-btn {
  background: #6366f1;
  color: white;
  border: none;
  border-radius: 8px;
  padding: 10px 16px;
  font-weight: 500;
  cursor: pointer;
  box-shadow: 0 2px 8px rgba(99,102,241,0.15);
  transition: background 0.2s;
}
.refresh-btn:hover:not(:disabled) {
  background: #4f46e5;
}
.refresh-btn:disabled {
  background: #a5b4fc;
  cursor: not-allowed;
}
.refresh-btn.outline {
  background: #fff;
  color: #6366f1;
  border: 1px solid #e0e7ff;
}
.dashboard-content {
  display: flex;
  flex-direction: column;
}
.section-title {
  font-size: 1.25rem;
  font-weight: 600;
  color: #1f2937;
  margin: 2rem 0 1rem 0;
  padding-left: 0.75rem;
  border-left: 4px solid #6366f1;
}
.data-card {
  background: #fff;
  border-radius: 12px;
  padding: 1.5rem;
  box-shadow: 0 4px 12px rgba(99,102,241,0.08);
  margin-bottom: 1.5rem;
  border: 1px solid #e0e7ff;
}
.table-container {
  overflow-x: auto;
  border-radius: 8px;
  background: var(--input-bg);
}
table {
  width: 100%;
  border-collapse: collapse;
  background: white;
}
th, td {
  padding: 12px 16px;
  text-align: left;
  border: none;
}
th {
  font-weight: 600;
  color: #1f2937;
  background: #eef2ff;
}
tbody tr {
  border-bottom: 1px solid #e0e7ff;
}
tbody tr:last-child {
  border-bottom: none;
}
tbody tr:hover {
  background: #eef2ff;
}
tbody tr:nth-child(even) {
  background: rgba(238, 242, 255, 0.5);
}
.empty-msg {
  text-align: center;
  color: #9ca3af;
  padding: 2rem;
}
.bars {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
  margin-top: 0.5rem;
}
.bar-row {
  display: grid;
  grid-template-columns: 140px 1fr 60px;
  align-items: center;
  gap: 0.5rem;
}
.bar-label {
  font-weight: 600;
}
.bar-wrap {
  height: 12px;
  background: #f1f5f9;
  border-radius: 6px;
  overflow: hidden;
  border: 1px solid #e5e7eb;
}
.bar-fill {
  height: 100%;
  background: #6366f1;
}
.bar-value {
  text-align: right;
}
</style>
