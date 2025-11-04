<template>
  <div class="dashboard-container">
    <!-- Sidebar reutilizable -->
    <Sidebar :active="'dashboard'" @navigate="navigateTo" @logout="logout" />
    
    <!-- Main Content -->
    <main class="main-content">
      <!-- Header -->
      <header class="content-header">
        <h1 class="header-title">Flota de Drones</h1>
        <div class="user-info">
          <div class="user-details">
            <span class="user-name">{{ auth.nombre }}</span>
            <span class="user-role">({{ auth.rol }})</span>
          </div>
          <div class="user-avatar">{{ auth.nombre.charAt(0) }}</div>
        </div>
      </header>
      
      <!-- Dashboard Content -->
      <div class="dashboard-content">
        <!-- Summary Cards -->
        <div class="summary-cards">
          <div class="summary-card">
            <div class="card-icon">🛸</div>
            <div class="card-info">
              <h3>{{ drones.length }}</h3>
              <p>Drones Activos</p>
            </div>
          </div>
          
          <div class="summary-card">
            <div class="card-icon">🎯</div>
            <div class="card-info">
              <h3>{{ misiones.length }}</h3>
              <p>Misiones Totales</p>
            </div>
          </div>
          
          <div class="summary-card">
            <div class="card-icon">✅</div>
            <div class="card-info">
              <h3>{{ misiones.filter(m => m.estado?.toLowerCase() === 'completada').length }}</h3>
              <p>Misiones Completadas</p>
            </div>
          </div>
        </div>
        
        <!-- Drones Section -->
        <div class="section-title">Información de la Flota</div>
        
        <div class="data-card">
          <div class="card-header">
            <h2><span class="icon">🛸</span> Drones</h2>
            <button class="refresh-btn" @click="loadDrones" :disabled="loadingDrones">
              {{ loadingDrones ? 'Cargando...' : 'Refrescar' }}
            </button>
          </div>
          
          <div class="table-container">
            <table v-if="drones.length">
              <thead>
                <tr>
                  <th>Modelo</th>
                  <th>Estado</th>
                  <th>Batería%</th>
                  <th>Lat</th>
                  <th>Lon</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="d in drones" :key="d.id">
                  <td>{{ d.modelo }}</td>
                  <td>
                    <span :class="'status-badge ' + d.estado.toLowerCase()">
                      {{ d.estado }}
                    </span>
                  </td>
                  <td>
                    <div class="battery-indicator">
                      <div class="battery-level" :style="{width: d.bateria_pct + '%', 
                           background: d.bateria_pct > 70 ? '#22c55e' : 
                                      (d.bateria_pct > 30 ? '#f59e42' : '#d32f2f')}"></div>
                    </div>
                    <span>{{ d.bateria_pct }}%</span>
                  </td>
                  <td>{{ (d.ultima_lat ?? '').toFixed?.(6) }}</td>
                  <td>{{ (d.ultima_lon ?? '').toFixed?.(6) }}</td>
                </tr>
              </tbody>
            </table>
            <p v-else class="empty-msg">
              {{ loadingDrones ? 'Cargando drones...' : 'No hay drones disponibles.' }}
            </p>
          </div>
        </div>
        
        <!-- Misiones Section -->
        <div class="section-title">Gestión de Misiones</div>
        
        <div class="data-card">
          <div class="card-header">
            <h2><span class="icon">🎯</span> Misiones</h2>
            <button class="refresh-btn" @click="loadMisiones" :disabled="loadingMisiones">
              {{ loadingMisiones ? 'Cargando...' : 'Refrescar' }}
            </button>
          </div>
          
          <div class="table-container">
            <table v-if="misiones.length">
              <thead>
                <tr>
                  <th>Tipo</th>
                  <th>Estado</th>
                  <th>Dron</th>
                  <th>Acciones</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="m in misiones" :key="m.id">
                  <td>{{ m.tipo }}</td>
                  <td>
                    <span :class="'status-badge ' + m.estado.toLowerCase()">
                      {{ m.estado }}
                    </span>
                  </td>
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
        </div>
        
        <!-- Map Section -->
        <div class="section-title">Visualización</div>
        
        <div class="data-card map-card">
          <div class="card-header">
            <h2><span class="icon">🗺️</span> Mapa de Operaciones</h2>
          </div>
          <div class="card map">
            <h3>Mapa</h3>
            <DronesMap :drones="drones" :misiones="misiones" />
          </div>
        </div>
      </div>
    </main>
  </div>
</template>

<script setup>
import { onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '../stores/auth'
import api from '../api/axios'
import DronesMap from '../components/DronesMap.vue';
import Sidebar from '../components/Sidebar.vue';

const auth = useAuthStore()
const router = useRouter()
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

const logout = () => {
  auth.logout()
  router.push('/login')
}

onMounted(() => {
  loadDrones()
  loadMisiones()
})

const navigateTo = (route) => {
  router.push(route);
};
</script>

<style scoped>

/* === FUENTES === */
.dashboard-container {
  font-family: 'Inter', Arial, Helvetica, sans-serif;
}

/* === LAYOUT PRINCIPAL === */
.dashboard-container {
  display: flex;
  min-height: 100vh;
  background: #f8fafc;
}

/* === SIDEBAR === */
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

/* === CONTENIDO PRINCIPAL === */
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

.user-info {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 8px 16px;
  background: #eef2ff;
  border-radius: 50px;
  box-shadow: 0 2px 10px rgba(0,0,0,0.05);
}

.user-details {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
}

.user-name {
  font-weight: 600;
  color: #1f2937;
}

.user-role {
  font-size: 0.9rem;
  color: #6366f1;
}

.user-avatar {
  width: 40px;
  height: 40px;
  background: #6366f1;
  color: white;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 600;
  box-shadow: 0 2px 8px rgba(99,102,241,0.25);
}

/* === SECCIONES === */
.section-title {
  font-size: 1.25rem;
  font-weight: 600;
  color: #1f2937;
  margin: 2rem 0 1rem 0;
  padding-left: 0.75rem;
  border-left: 4px solid #6366f1;
}

/* === CONTENIDO DEL DASHBOARD === */
.dashboard-content {
  display: flex;
  flex-direction: column;
}

/* === TARJETAS RESUMEN === */
.summary-cards {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 1.5rem;
  margin-bottom: 1rem;
}

.summary-card {
  background: #fff;
  border-radius: 12px;
  padding: 1.5rem;
  display: flex;
  align-items: center;
  gap: 1.5rem;
  box-shadow: 0 4px 12px rgba(99,102,241,0.08);
  border: 1px solid #e0e7ff;
  transition: transform 0.2s, box-shadow 0.2s;
}

.summary-card:hover {
  transform: translateY(-3px);
  box-shadow: 0 6px 16px rgba(99,102,241,0.12);
}

.card-icon {
  width: 54px;
  height: 54px;
  background: #eef2ff;
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 1.75rem;
}

.card-info h3 {
  font-size: 1.8rem;
  font-weight: 700;
  color: #1f2937;
  margin: 0 0 5px 0;
}

.card-info p {
  margin: 0;
  color: #9ca3af;
}

/* === TARJETAS DE DATOS === */
.data-card {
  background: #fff;
  border-radius: 12px;
  padding: 1.5rem;
  box-shadow: 0 4px 12px rgba(99,102,241,0.08);
  margin-bottom: 1.5rem;
  border: 1px solid #e0e7ff;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1.5rem;
  padding-bottom: 1rem;
  border-bottom: 1px solid #e0e7ff;
}

.card-header h2 {
  font-size: 1.3rem;
  font-weight: 600;
  color: #1f2937;
  margin: 0;
  display: flex;
  align-items: center;
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

/* === TABLAS === */
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

/* === INDICADORES DE ESTADO === */
.status-badge {
  padding: 6px 10px;
  border-radius: 20px;
  font-size: 0.85rem;
  font-weight: 500;
  text-align: center;
  display: inline-block;
}

.status-badge.activo, .status-badge.completada {
  background: rgba(34, 197, 94, 0.15);
  color: #22c55e;
}

.status-badge.inactivo, .status-badge.fallida {
  background: rgba(211, 47, 47, 0.15);
  color: #d32f2f;
}

.status-badge.en_curso, .status-badge.pendiente {
  background: rgba(245, 158, 66, 0.15);
  color: #f59e42;
}

/* === INDICADOR DE BATERÍA === */
.battery-indicator {
  width: 60px;
  height: 10px;
  background: #e0e0e0;
  border-radius: 10px;
  overflow: hidden;
  margin-right: 10px;
  display: inline-block;
  vertical-align: middle;
}

.battery-level {
  height: 100%;
  border-radius: 10px;
}

/* === BOTONES DE ACCIÓN === */
.actions {
  display: flex;
  gap: 0.5rem;
}

.action-btn {
  padding: 8px 12px;
  border: none;
  border-radius: 8px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

.action-btn.complete {
  color: black;
}

.action-btn.complete:hover {
  background: #22c55e;
  transform: translateY(-2px);
  color: white;
}

.action-btn.fail {  
  background: white;
}

.action-btn.fail:hover {
  background: #f59e42;
  color: white;
  transform: translateY(-2px);
}

/* === MAPA === */
.map-card {
  margin-bottom: 2rem;
}

.map-placeholder {
  height: 380px;
  background: linear-gradient(135deg, #eef2ff 60%, #6366f1 100%);
  border-radius: 10px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #6366f1;
  font-size: 1.2rem;
  font-weight: 500;
  border: 1px dashed #e0e7ff;
}

/* === RESPONSIVE === */
@media (max-width: 1024px) {
  .summary-cards {
    grid-template-columns: repeat(2, 1fr);
  }
  .summary-card:last-child {
    grid-column: span 2;
  }
}

@media (max-width: 768px) {
  .sidebar {
    transform: translateX(-100%);
    z-index: 100;
    transition: transform 0.3s ease;
  }
  .main-content {
    margin-left: 0;
  }
  .summary-cards {
    grid-template-columns: 1fr;
  }
  .summary-card:last-child {
    grid-column: auto;
  }
}
</style>