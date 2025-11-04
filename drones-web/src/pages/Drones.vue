<template>
  <div class="dashboard-container">
    <!-- Sidebar -->
    <aside class="sidebar">
      <div class="sidebar-header">
        <span class="sidebar-logo">D</span>
        <h2>Drone<span>.io</span></h2>
      </div>
      
      <nav class="sidebar-nav">
        <a @click="navigateTo('/')" class="sidebar-link">
          <span class="icon">📊</span>
          <span>Dashboard</span>
        </a>
        <a @click="navigateTo('/drones')" class="sidebar-link active">
          <span class="icon">🛸</span>
          <span>Drones</span>
        </a>
        <a @click="navigateTo('/misiones')" class="sidebar-link">
          <span class="icon">🎯</span>
          <span>Misiones</span>
        </a>
        <a @click="navigateTo('/reportes')" class="sidebar-link">
          <span class="icon">📈</span>
          <span>Reportes</span>
        </a>
      </nav>
      
      <div class="sidebar-footer">
        <button class="logout-btn" @click="logout">
          <span>Cerrar sesión</span>
        </button>
      </div>
    </aside>
    
    <!-- Main Content -->
    <main class="main-content">
      <!-- Header -->
      <header class="content-header">
        <h1 class="header-title">Gestión de Drones</h1>
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
              <h3>{{ statusCounts.total }}</h3>
              <p>Total de Drones</p>
            </div>
          </div>
          
          <div class="summary-card">
            <div class="card-icon">✅</div>
            <div class="card-info">
              <h3>{{ statusCounts.disponible }}</h3>
              <p>Disponibles</p>
            </div>
          </div>
          
          <div class="summary-card">
            <div class="card-icon">🔵</div>
            <div class="card-info">
              <h3>{{ statusCounts['en vuelo'] }}</h3>
              <p>En Vuelo</p>
            </div>
          </div>

          <div class="summary-card">
            <div class="card-icon">🔧</div>
            <div class="card-info">
              <h3>{{ statusCounts['en mantenimiento'] }}</h3>
              <p>En Mantenimiento</p>
            </div>
          </div>
        </div>

        <!-- Drones Section -->
        <div class="section-title">Gestión de la Flota</div>
        
        <div class="data-card">
          <div class="card-header">
            <h2><span class="icon">🛸</span> Lista de Drones</h2>
            <button class="refresh-btn" @click="loadDrones" :disabled="loading">
              {{ loading ? 'Cargando...' : 'Refrescar' }}
            </button>
          </div>

          <!-- Controles de filtrado y búsqueda -->
          <div class="controls">
            <div class="search-input">
              <input
                v-model="searchQuery"
                type="text"
                placeholder="Buscar por modelo o ID..."
                :aria-label="'Buscar drones'"
              />
            </div>
            
            <div class="filter-select">
              <select v-model="statusFilter" :aria-label="'Filtrar por estado'">
                <option v-for="estado in estados" :key="estado.value" :value="estado.value">
                  {{ estado.label }}
                </option>
              </select>
            </div>

            <div class="sort-select">
              <select v-model="sortBy" :aria-label="'Ordenar por'">
                <option v-for="option in sortOptions" :key="option.value" :value="option.value">
                  {{ option.label }}
                </option>
              </select>
            </div>
          </div>

          <!-- Estados de carga y contenido -->
          <div class="table-container">
            <!-- Loading state -->
            <div v-if="loading" class="loading-state">
              <div class="spinner"></div>
              <p class="empty-msg">Cargando drones...</p>
            </div>

            <!-- Error state -->
            <div v-else-if="error" class="error-state">
              <div class="error-icon">⚠️</div>
              <h3>Error al cargar los drones</h3>
              <p class="empty-msg">{{ error }}</p>
              <button @click="retryLoad" class="retry-button">
                Reintentar
              </button>
            </div>

            <!-- Empty state -->
            <div v-else-if="filteredDrones.length === 0" class="empty-state">
              <div class="empty-icon">🚁</div>
              <h3>No se encontraron drones</h3>
              <p v-if="searchQuery || statusFilter !== 'all'" class="empty-msg">
                Intenta ajustar los filtros de búsqueda
              </p>
              <p v-else class="empty-msg">
                No hay drones registrados en el sistema
              </p>
            </div>

            <!-- Lista de drones - Vista móvil (cards) -->
            <div v-else class="drones-container">
              <div class="drones-grid mobile-view">
                <article
                  v-for="drone in filteredDrones"
                  :key="drone.id"
                  class="drone-card"
                  :aria-label="`Dron ${drone.modelo}`"
                >
                  <div class="card-header">
                    <h3 class="drone-model">{{ drone.modelo }}</h3>
                    <span class="drone-id">{{ drone.id }}</span>
                  </div>
                  
                  <div class="card-body">
                    <div class="spec">
                      <span class="spec-label">Capacidad:</span>
                      <span class="spec-value">{{ drone.capacidadCargaKg || 'N/A' }} kg</span>
                    </div>
                    <div class="spec">
                      <span class="spec-label">Autonomía:</span>
                      <span class="spec-value">{{ drone.autonomiaMin || 'N/A' }} min</span>
                    </div>
                  </div>

                  <div class="card-footer">
                    <span
                      class="status-badge"
                      :class="drone.estado.toLowerCase().replace(' ', '_')"
                      :aria-label="`Estado: ${drone.estado}`"
                    >
                      {{ drone.estado }}
                    </span>
                  </div>
                </article>
              </div>

              <!-- Vista desktop (tabla) -->
              <div class="drones-table desktop-view">
                <table role="table" aria-label="Lista de drones">
                  <thead>
                    <tr>
                      <th>ID</th>
                      <th>Modelo</th>
                      <th>Capacidad (kg)</th>
                      <th>Autonomía (min)</th>
                      <th>Estado</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr v-for="drone in filteredDrones" :key="drone.id">
                      <td class="drone-id-cell">{{ drone.id }}</td>
                      <td class="drone-model-cell">{{ drone.modelo }}</td>
                      <td class="drone-capacity-cell">{{ drone.capacidadCargaKg || 'N/A' }}</td>
                      <td class="drone-autonomy-cell">{{ drone.autonomiaMin || 'N/A' }}</td>
                      <td class="drone-status-cell">
                        <span
                          class="status-badge"
                          :class="drone.estado.toLowerCase().replace(' ', '_')"
                          :aria-label="`Estado: ${drone.estado}`"
                        >
                          {{ drone.estado }}
                        </span>
                      </td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        </div>
      </div>
    </main>
  </div>
</template>

<!-- src/pages/Drones.vue -->
<script setup>
import { onMounted, ref, computed } from 'vue';
import { useRouter } from 'vue-router';
import { useAuthStore } from '../stores/auth';
import { api } from '../api';

const auth = useAuthStore();
const router = useRouter();

// Estado principal
const drones = ref([]);
const loading = ref(true);
const error = ref('');

// Filtros y búsqueda
const searchQuery = ref('');
const statusFilter = ref('all');
const sortBy = ref('modelo');

// Estados disponibles
const estados = [
  { value: 'all', label: 'Todos los estados' },
  { value: 'disponible', label: 'Disponible' },
  { value: 'en vuelo', label: 'En vuelo' },
  { value: 'en mantenimiento', label: 'En mantenimiento' }
];

// Opciones de ordenamiento
const sortOptions = [
  { value: 'modelo', label: 'Modelo (A-Z)' },
  { value: 'modelo-desc', label: 'Modelo (Z-A)' },
  { value: 'capacidad', label: 'Capacidad (menor)' },
  { value: 'capacidad-desc', label: 'Capacidad (mayor)' },
  { value: 'autonomia', label: 'Autonomía (menor)' },
  { value: 'autonomia-desc', label: 'Autonomía (mayor)' }
];

// Datos mock para desarrollo
const mockDrones = [
  {
    id: "DRN-001",
    modelo: "Aquila X2",
    capacidadCargaKg: 5.5,
    autonomiaMin: 42,
    estado: "disponible"
  },
  {
    id: "DRN-002",
    modelo: "Falcon M1",
    capacidadCargaKg: 3.2,
    autonomiaMin: 30,
    estado: "en vuelo"
  },
  {
    id: "DRN-003",
    modelo: "Orion L",
    capacidadCargaKg: 8.0,
    autonomiaMin: 55,
    estado: "en mantenimiento"
  },
  {
    id: "DRN-004",
    modelo: "Phoenix Pro",
    capacidadCargaKg: 12.0,
    autonomiaMin: 75,
    estado: "disponible"
  },
  {
    id: "DRN-005",
    modelo: "Eagle V3",
    capacidadCargaKg: 7.8,
    autonomiaMin: 48,
    estado: "en vuelo"
  },
  {
    id: "DRN-006",
    modelo: "Hawk Mini",
    capacidadCargaKg: 2.1,
    autonomiaMin: 25,
    estado: "en mantenimiento"
  }
];

// Computadas para filtrado y ordenamiento
const filteredDrones = computed(() => {
  let result = [...drones.value];

  // Filtrar por búsqueda
  if (searchQuery.value.trim()) {
    const query = searchQuery.value.toLowerCase();
    result = result.filter(drone => 
      drone.modelo.toLowerCase().includes(query) ||
      drone.id.toLowerCase().includes(query)
    );
  }

  // Filtrar por estado (insensible a mayúsculas y espacios)
  if (statusFilter.value !== 'all') {
    const filtro = statusFilter.value.trim().toLowerCase();
    result = result.filter(drone =>
      drone.estado && drone.estado.trim().toLowerCase() === filtro
    );
  }

  // Ordenar
  result.sort((a, b) => {
    let aVal, bVal;
    
    if (sortBy.value.includes('modelo')) {
      aVal = a.modelo.toLowerCase();
      bVal = b.modelo.toLowerCase();
    } else if (sortBy.value.includes('capacidad')) {
      aVal = a.capacidadCargaKg;
      bVal = b.capacidadCargaKg;
    } else if (sortBy.value.includes('autonomia')) {
      aVal = a.autonomiaMin;
      bVal = b.autonomiaMin;
    }

    if (sortBy.value.includes('-desc')) {
      return bVal > aVal ? 1 : -1;
    }
    return aVal > bVal ? 1 : -1;
  });

  return result;
});

// Contadores por estado
const statusCounts = computed(() => {
  const counts = {
    disponible: 0,
    'en vuelo': 0,
    'en mantenimiento': 0,
    total: drones.value.length
  };

  drones.value.forEach(drone => {
    if (drone && drone.estado) {
      const estado = drone.estado.trim().toLowerCase();
      if (estado === 'disponible') counts.disponible++;
      else if (estado === 'en vuelo') counts['en vuelo']++;
      else if (estado === 'en mantenimiento') counts['en mantenimiento']++;
    }
  });

  return counts;
});



// Función para cargar drones
const loadDrones = async () => {
  loading.value = true;
  error.value = '';
  
  try {
    // Intentar cargar desde API primero
    const { data } = await api.get('/drones');
    if (data && Array.isArray(data)) {
      drones.value = data;
    } else {
      throw new Error('Datos de API inválidos');
    }
  } catch (e) {
    console.warn('API no disponible, usando datos mock:', e.message);
    // Si falla la API, usar datos mock
    await new Promise(resolve => setTimeout(resolve, 800)); // Simular carga
    drones.value = [...mockDrones]; // Clonar array para forzar reactividad
  } finally {
    loading.value = false;
  }
};

// Función para reintentar carga
const retryLoad = () => {
  loadDrones();
};



// Función para navegar
const navigateTo = (route) => {
  router.push(route);
};

// Función para cerrar sesión
const logout = () => {
  auth.logout();
  router.push('/login');
};

// Inicializar con datos mock inmediatamente para testing
drones.value = [...mockDrones];

onMounted(() => {
  loadDrones();
});
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
  cursor: pointer;
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
  grid-template-columns: repeat(4, 1fr);
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

.controls {
  display: flex;
  gap: 1rem;
  margin-bottom: 1.5rem;
  flex-wrap: wrap;
  align-items: center;
}

.search-input {
  flex: 2;
  min-width: 250px;
}

.search-input input {
  width: 100%;
  padding: 10px 14px;
  border: 1px solid #e0e7ff;
  border-radius: 8px;
  font-size: 0.95rem;
  outline: none;
  transition: border-color 0.2s;
  background: white;
}

.search-input input:focus {
  border-color: #6366f1;
  box-shadow: 0 0 0 3px rgba(99, 102, 241, 0.1);
}

.filter-select, .sort-select {
  flex: 1;
  min-width: 180px;
}

.filter-select select, .sort-select select {
  width: 100%;
  padding: 10px 14px;
  border: 1px solid #e0e7ff;
  border-radius: 8px;
  font-size: 0.95rem;
  background: white;
  outline: none;
  cursor: pointer;
  transition: border-color 0.2s;
}

.filter-select select:focus, .sort-select select:focus {
  border-color: #6366f1;
  box-shadow: 0 0 0 3px rgba(99, 102, 241, 0.1);
}

/* === TABLAS === */
.table-container {
  overflow-x: auto;
  border-radius: 8px;
  background: white;
}

/* Estados de carga */
.loading-state, .error-state, .empty-state {
  text-align: center;
  padding: 3rem 2rem;
}

.spinner {
  width: 40px;
  height: 40px;
  border: 4px solid #e0e7ff;
  border-top: 4px solid #6366f1;
  border-radius: 50%;
  animation: spin 1s linear infinite;
  margin: 0 auto 20px;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

.error-icon, .empty-icon {
  font-size: 3rem;
  margin-bottom: 16px;
}

.error-state h3, .empty-state h3 {
  color: #1f2937;
  margin: 0 0 12px 0;
  font-size: 1.5rem;
}

.empty-msg {
  text-align: center;
  color: #9ca3af;
  margin: 0 0 20px 0;
}

.retry-button {
  background: #6366f1;
  color: white;
  border: none;
  padding: 12px 24px;
  border-radius: 8px;
  font-size: 1rem;
  cursor: pointer;
  transition: background-color 0.2s;
  box-shadow: 0 2px 8px rgba(99,102,241,0.15);
}

.retry-button:hover {
  background: #4f46e5;
}

.retry-button:focus {
  outline: none;
  box-shadow: 0 0 0 3px rgba(99, 102, 241, 0.3);
}

/* Vista móvil - Cards */
.mobile-view {
  display: block;
}

.desktop-view {
  display: none;
}

.drones-grid {
  display: grid;
  gap: 1rem;
  grid-template-columns: 1fr;
}

.drone-card {
  background: white;
  border: 1px solid #e0e7ff;
  border-radius: 8px;
  padding: 1rem;
  transition: box-shadow 0.2s, transform 0.2s;
}

.drone-card:hover {
  box-shadow: 0 4px 12px rgba(99,102,241,0.12);
  transform: translateY(-2px);
}

.card-header {
  margin-bottom: 12px;
}

.drone-model {
  font-size: 1.1rem;
  font-weight: 600;
  color: #1f2937;
  margin: 0 0 4px 0;
}

.drone-id {
  font-size: 0.85rem;
  color: #9ca3af;
  font-family: 'Courier New', monospace;
}

.card-body {
  margin-bottom: 12px;
}

.spec {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 6px;
}

.spec-label {
  font-size: 0.875rem;
  color: #6b7280;
  font-weight: 500;
}

.spec-value {
  font-size: 0.875rem;
  color: #1f2937;
  font-weight: 600;
}

.card-footer {
  display: flex;
  justify-content: flex-end;
}

/* === INDICADORES DE ESTADO === */
.status-badge {
  padding: 6px 10px;
  border-radius: 20px;
  font-size: 0.75rem;
  font-weight: 500;
  text-align: center;
  display: inline-block;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.status-badge.disponible {
  background: rgba(34, 197, 94, 0.15);
  color: #22c55e;
}

.status-badge.en_vuelo {
  background: rgba(37, 99, 235, 0.15);
  color: #2563eb;
}

.status-badge.en_mantenimiento {
  background: rgba(217, 119, 6, 0.15);
  color: #d97706;
}

/* Vista desktop - Tabla */
@media (min-width: 768px) {
  .mobile-view {
    display: none;
  }
  
  .desktop-view {
    display: block;
  }

  .drones-grid {
    grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  }

  .controls {
    flex-wrap: nowrap;
  }

  .search-input {
    flex: 2;
  }

  .filter-select, .sort-select {
    flex: 1;
  }

  .summary-cards {
    grid-template-columns: repeat(4, 1fr);
  }
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

.drone-id-cell {
  font-family: 'Courier New', monospace;
  font-size: 0.875rem;
  color: #9ca3af;
}

.drone-model-cell {
  font-weight: 600;
  color: #1f2937;
}

.drone-capacity-cell, .drone-autonomy-cell {
  color: #374151;
  text-align: right;
}

.drone-status-cell {
  text-align: center;
}

/* === RESPONSIVE === */
@media (max-width: 1024px) {
  .summary-cards {
    grid-template-columns: repeat(2, 1fr);
  }
  .summary-card:nth-child(3), .summary-card:nth-child(4) {
    grid-column: span 1;
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
    padding: 1rem;
  }
  .summary-cards {
    grid-template-columns: repeat(2, 1fr);
    gap: 1rem;
  }
  .content-header {
    flex-direction: column;
    align-items: flex-start;
    gap: 1rem;
  }
  .controls {
    flex-direction: column;
    align-items: stretch;
  }
  .search-input, .filter-select, .sort-select {
    min-width: unset;
    width: 100%;
  }
}

@media (max-width: 640px) {
  .summary-cards {
    grid-template-columns: 1fr;
  }
  .header-title {
    font-size: 1.5rem;
  }
}

/* Accesibilidad - focus states */
.drone-card:focus-within {
  outline: 2px solid #6366f1;
  outline-offset: 2px;
}

table tr:focus-within {
  outline: 2px solid #6366f1;
  outline-offset: -2px;
}
</style>
