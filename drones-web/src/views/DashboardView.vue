<template>
  <div class="dashboard-page">
    <header class="dashboard-header">
      <div class="user-info">
        <img src="@/Assets/vue.svg" alt="Avatar" class="avatar" />
        <div>
          <strong>{{ auth.nombre }}</strong>
          <span class="user-role">({{ auth.rol }})</span>
        </div>
      </div>
      <h2>Flota de Drones</h2>
      <button class="logout-btn" @click="logout">Salir</button>
    </header>

    <section class="dashboard-grid">
      <div class="dashboard-card">
        <h3><span class="icon">🛸</span> Drones</h3>
        <button class="refresh-btn" @click="loadDrones" :disabled="loadingDrones">
          {{ loadingDrones ? 'Cargando...' : 'Refrescar' }}
        </button>
        <table v-if="drones.length">
          <thead>
            <tr>
              <th>Modelo</th><th>Estado</th><th>Batería%</th><th>Lat</th><th>Lon</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="d in drones" :key="d.id">
              <td>{{ d.modelo }}</td>
              <td>{{ d.estado }}</td>
              <td>{{ d.bateria_pct }}</td>
              <td>{{ (d.ultima_lat ?? '').toFixed?.(6) }}</td>
              <td>{{ (d.ultima_lon ?? '').toFixed?.(6) }}</td>
            </tr>
          </tbody>
        </table>
        <p v-else class="empty-msg">
          {{ loadingDrones ? 'Cargando drones...' : 'No hay drones disponibles.' }}
        </p>
      </div>

      <div class="dashboard-card">
        <h3><span class="icon">🎯</span> Misiones</h3>
        <button class="refresh-btn" @click="loadMisiones" :disabled="loadingMisiones">
          {{ loadingMisiones ? 'Cargando...' : 'Refrescar' }}
        </button>
        <table v-if="misiones.length">
          <thead>
            <tr>
              <th>Tipo</th><th>Estado</th><th>Dron</th><th>Acciones</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="m in misiones" :key="m.id">
              <td>{{ m.tipo }}</td>
              <td>{{ m.estado }}</td>
              <td>{{ m.dron_modelo || '-' }}</td>
              <td class="actions">
                <button class="action-btn complete" @click="completar(m.id)">Completar</button>
                <button class="action-btn fail" @click="fallar(m.id)">Fallar</button>
              </td>
            </tr>
          </tbody>
        </table>
        <p v-else class="empty-msg">
          {{ loadingMisiones ? 'Cargando misiones...' : 'No hay misiones disponibles.' }}
        </p>
      </div>

      <div class="dashboard-card map">
        <h3><span class="icon">🗺️</span> Mapa</h3>
        <div id="map" class="map-placeholder">
          <span>Próximamente: integración con Leaflet/MapLibre/Google Maps</span>
        </div>
      </div>
    </section>
  </div>
</template>

<script setup>
import { h, onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '../stores/auth'
import api from '../api/axios'

const auth = useAuthStore()
const drones = ref([])
const misiones = ref([])
const loadingDrones = ref(false)
const loadingMisiones = ref(false)

const loadDrones = async () => {
  loadingDrones.value = true
  try {
    const { data } = await api.get('/drones')
    drones.value = data
  } finally {
    loadingDrones.value = false
  }
}
const loadMisiones = async () => {
  loadingMisiones.value = true
  try {
    const { data } = await api.get('/misiones')
    misiones.value = data
  } finally {
    loadingMisiones.value = false
  }
}

const completar = async (id) => {
  await api.post(`/misiones/${id}/completar`, {})
  await loadMisiones()
}
const fallar = async (id) => {
  const motivo = prompt('Motivo de la falla (opcional):') || null
  await api.post(`/misiones/${id}/fallar`, { motivo })
  await loadMisiones()
}

const logout = () => auth.logout()

onMounted(() => {
  loadDrones()
  loadMisiones()
})
</script>

<style scoped>
.dashboard-page {
  padding: 2rem;
  background: #f3f4f6;
  min-height: 100vh;
}
.dashboard-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 2rem;
  background: #fff;
  border-radius: 12px;
  padding: 1rem 2rem;
  box-shadow: 0 2px 8px rgba(99,102,241,0.08);
  text-align: center;
}
.dashboard-header h2 {
  margin: 0;
  font-size: 1.5rem;
  color: #4f46e5;
  font-weight: 600;
}
.user-info {
  display: flex;
  align-items: center;
  gap: 1rem;
}
.user-info h2 {
  margin-bottom: 0;
  text-align: center;
}
.avatar {
  width: 48px;
  height: 48px;
  border-radius: 50%;
  background: #eef2ff;
  object-fit: cover;
  border: 2px solid #6366f1;
}
.user-role {
  color: #6366f1;
  font-size: 0.95rem;
  margin-left: 4px;
}
.logout-btn {
  background: #d32f2f;
  color: #fff;
  border: none;
  border-radius: 8px;
  padding: 0.6rem 1.2rem;
  font-weight: 600;
  cursor: pointer;
  transition: background 0.2s;
}
.logout-btn:hover {
  background: #b91c1c;
}
.dashboard-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 2rem;
}
.dashboard-card {
  background: #fff;
  border-radius: 12px;
  box-shadow: 0 2px 8px rgba(99,102,241,0.08);
  padding: 1.5rem;
  min-height: 320px;
  display: flex;
  flex-direction: column;
}
.dashboard-card h3 {
  font-size: 1.3rem;
  font-weight: 600;
  color: #4f46e5;
  margin-bottom: 1rem;
  display: flex;
  align-items: center;
  gap: 0.5rem;
}
.icon {
  font-size: 1.3rem;
}
.refresh-btn {
  background: #6366f1;
  color: #fff;
  border: none;
  border-radius: 8px;
  padding: 0.5rem 1rem;
  font-weight: 500;
  cursor: pointer;
  margin-bottom: 1rem;
  transition: background 0.2s;
}
.refresh-btn:disabled {
  background: #a5b4fc;
  cursor: not-allowed;
}
.refresh-btn:hover:not(:disabled) {
  background: #4f46e5;
}
.empty-msg {
  color: #9ca3af;
  margin-top: 1rem;
  text-align: center;
}
table {
  width: 100%;
  border-collapse: collapse;
  margin-top: .5rem;
  background: #f8fafc;
  border-radius: 8px;
  overflow: hidden;
}
th, td {
  border: 1px solid #e5e7eb;
  padding: .5rem;
  text-align: left;
}
tbody tr:nth-child(even) {
  background: #eef2ff;
}
.actions {
  display: flex;
  gap: 0.5rem;
}
.action-btn {
  padding: 0.3rem 0.8rem;
  border: none;
  border-radius: 6px;
  font-weight: 500;
  cursor: pointer;
  transition: background 0.2s;
}
.action-btn.complete {
  background: #22c55e;
  color: #fff;
}
.action-btn.complete:hover {
  background: #16a34a;
}
.action-btn.fail {
  background: #f59e42;
  color: #fff;
}
.action-btn.fail:hover {
  background: #ea580c;
}
.map {
  grid-column: 1 / -1;
}
.map-placeholder {
  height: 380px;
  background: linear-gradient(135deg, #eef2ff 60%, #6366f1 100%);
  border: 2px dashed #99c;
  border-radius: 10px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #6366f1;
  font-size: 1.2rem;
  font-weight: 500;
  margin-top: 1rem;
}
</style>