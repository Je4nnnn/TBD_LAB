<template>
  <div class="dashboard-container">
    <!-- Sidebar reutilizable -->
    <Sidebar :active="'misiones'" @navigate="navigateTo" @logout="logout" />
    
    <!-- Main Content -->
    <main class="main-content">
      <!-- Header -->
      <header class="content-header">
        <h1 class="header-title">Gestión de Misiones</h1>
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
            <div class="card-icon">🎯</div>
            <div class="card-info">
              <h3>{{ statusCounts.total }}</h3>
              <p>Total de Misiones</p>
            </div>
          </div>
          
          <div class="summary-card">
            <div class="card-icon">⏳</div>
            <div class="card-info">
              <h3>{{ statusCounts['Pendiente'] }}</h3>
              <p>Pendientes</p>
            </div>
          </div>
          
          <div class="summary-card">
            <div class="card-icon">🚀</div>
            <div class="card-info">
              <h3>{{ statusCounts['En Progreso'] }}</h3>
              <p>En Progreso</p>
            </div>
          </div>

          <div class="summary-card">
            <div class="card-icon">✅</div>
            <div class="card-info">
              <h3>{{ statusCounts['Completada'] }}</h3>
              <p>Completadas</p>
            </div>
          </div>
        </div>

        <!-- Misiones Section -->
        <div class="section-title">Control de Misiones</div>
        
        <div class="data-card">
          <div class="card-header">
            <h2><span class="icon">🎯</span> Lista de Misiones</h2>
            <div style="display: flex; gap: 1rem;">
                <router-link class="crear-btn" :to="{ name: 'crear-mision' }">+ Crear Misión</router-link>
              <button class="refresh-btn" @click="loadMisiones" :disabled="loading">
                {{ loading ? 'Cargando...' : 'Refrescar' }}
              </button>
            </div>
          </div>
          <!-- Modal Crear Misión, solo HTML y Vue -->
          <div v-if="showCrearModal" class="modal-overlay">
            <div class="modal-content">
              <h2>Crear Nueva Misión</h2>
              <form @submit.prevent="crearMision">
                <div class="form-group">
                  <label for="tipoNueva">Tipo de misión</label>
                  <input id="tipoNueva" v-model="tipoNueva" type="text" required placeholder="Ej: Inspección" />
                </div>
                <div class="form-group">
                  <label for="rutaNueva">Ruta planeada</label>
                  <input id="rutaNueva" v-model="rutaNueva" type="text" required placeholder="Ej: Punto A, Punto B" />
                </div>
                <div class="form-group">
                  <label for="dronNueva">Asignar dron</label>
                  <select id="dronNueva" v-model="dronNueva" required class="select-dron">
                    <option value="" disabled>Selecciona un dron</option>
                    <template v-for="d in dronesDisponibles" :key="d.id">
                      <option :value="d.id">{{ d.modelo }} ({{ d.id }})</option>
                    </template>
                  </select>
                </div>
                <div class="modal-actions">
                  <button type="submit" class="crear-btn" :disabled="creando">
                    {{ creando ? 'Creando...' : 'Crear' }}
                  </button>
                  <button type="button" class="cancelar-btn" @click="showCrearModal = false" :disabled="creando">
                    Cancelar
                  </button>
                </div>
              </form>
            </div>
          </div>


          <!-- Controles de filtrado y búsqueda -->
          <div class="controls">
            <div class="search-input">
              <input
                v-model="searchQuery"
                type="text"
                placeholder="Buscar por tipo, ID o dron..."
                :aria-label="'Buscar misiones'"
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
              <p class="empty-msg">Cargando misiones...</p>
            </div>

            <!-- Error state -->
            <div v-else-if="error" class="error-state">
              <div class="error-icon">⚠️</div>
              <h3>Error al cargar las misiones</h3>
              <p class="empty-msg">{{ error }}</p>
              <button @click="retryLoad" class="retry-button">
                Reintentar
              </button>
            </div>

            <!-- Empty state -->
            <div v-else-if="filteredMisiones.length === 0" class="empty-state">
              <div class="empty-icon">🎯</div>
              <h3>No se encontraron misiones</h3>
              <p v-if="searchQuery || statusFilter !== 'all'" class="empty-msg">
                Intenta ajustar los filtros de búsqueda
              </p>
              <p v-else class="empty-msg">
                No hay misiones registradas en el sistema
              </p>
            </div>

            <!-- Lista de misiones - Vista móvil (cards) -->
            <div v-else class="misiones-container">
              <div class="misiones-grid mobile-view">
                <article
                  v-for="mision in filteredMisiones"
                  :key="mision.id"
                  class="mision-card"
                  :aria-label="`Misión ${mision.tipo}`"
                >
                  <div class="card-header">
                    <h3 class="mision-tipo">{{ mision.tipo }}</h3>
                    <span class="mision-id">{{ mision.id }}</span>
                  </div>
                  
                  <div class="card-body">
                    <div class="spec">
                      <span class="spec-label">Dron:</span>
                      <span class="spec-value">{{ mision.dron_modelo || 'No asignado' }}</span>
                    </div>
                    <div class="spec">
                      <span class="spec-label">Inicio:</span>
                      <span class="spec-value">{{ formatDate(mision.fecha_inicio) }}</span>
                    </div>
                    <div class="spec">
                      <span class="spec-label">Duración:</span>
                      <span class="spec-value">{{ calculateDuration(mision.fecha_inicio, mision.fecha_fin) }}</span>
                    </div>
                    <div class="spec">
                      <span class="spec-label">Puntos ruta:</span>
                      <span class="spec-value">{{ mision.ruta?.waypoints?.length || 0 }}</span>
                    </div>
                  </div>

                  <div class="card-footer">
                    <span
                      class="status-badge"
                      :class="mision.estado.toLowerCase().replace(' ', '_')"
                      :aria-label="`Estado: ${mision.estado}`"
                    >
                      {{ mision.estado }}
                    </span>
                  </div>
                </article>
              </div>

              <!-- Vista desktop (tabla) -->
              <div class="misiones-table desktop-view">
                <table role="table" aria-label="Lista de misiones">
                  <thead>
                    <tr>
                      <th>ID</th>
                      <th>Tipo</th>
                      <th>Dron</th>
                      <th>Inicio</th>
                      <th>Duración</th>
                      <th>Puntos</th>
                      <th>Estado</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr v-for="mision in filteredMisiones" :key="mision.id">
                      <td class="mision-id-cell">{{ mision.id }}</td>
                      <td class="mision-tipo-cell">{{ mision.tipo }}</td>
                      <td class="mision-dron-cell">{{ mision.dron_modelo || 'No asignado' }}</td>
                      <td class="mision-fecha-cell">{{ formatDate(mision.fecha_inicio) }}</td>
                      <td class="mision-duracion-cell">{{ calculateDuration(mision.fecha_inicio, mision.fecha_fin) }}</td>
                      <td class="mision-puntos-cell">{{ mision.ruta?.waypoints?.length || 0 }}</td>
                      <td class="mision-status-cell">
                        <span
                          class="status-badge"
                          :class="mision.estado.toLowerCase().replace(' ', '_')"
                          :aria-label="`Estado: ${mision.estado}`"
                        >
                          {{ mision.estado }}
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

<script setup>
import { onMounted, ref, computed } from 'vue';
import { useRouter } from 'vue-router';
import { useAuthStore } from '../stores/auth';
import { api } from '../api';
import Sidebar from '../components/Sidebar.vue';

const auth = useAuthStore();
const router = useRouter();

// Estado principal
const misiones = ref([]);
const loading = ref(true);
const error = ref('');

// Estado para crear misión (no afecta nada existente)
const showCrearModal = ref(false);
const tipoNueva = ref('');
const rutaNueva = ref('');
const dronNueva = ref('');
const creando = ref(false);
const dronesDisponibles = ref([]);

const crearMision = async () => {
  creando.value = true;
  error.value = '';
  try {
    const body = {
      tipo: tipoNueva.value,
      ruta_planeada: rutaNueva.value,
      dron_id: dronNueva.value
    };
    await api.post('/misiones', body);
    tipoNueva.value = '';
    rutaNueva.value = '';
    dronNueva.value = '';
    showCrearModal.value = false;
    loadMisiones();
  } catch (e) {
    error.value = 'No se pudo crear la misión';
    console.error(e);
  } finally {
    creando.value = false;
  }
};

const loadDrones = async () => {
  try {
    const { data } = await api.get('/drones', {
      headers: {
        Authorization: `Bearer ${auth.token}`
      }
    });
    dronesDisponibles.value = data;
  } catch (e) {
    dronesDisponibles.value = [];
  }
};

// Filtros y búsqueda
const searchQuery = ref('');
const statusFilter = ref('all');
const sortBy = ref('fecha');

// Estados disponibles
const estados = [
  { value: 'all', label: 'Todos los estados' },
  { value: 'Pendiente', label: 'Pendiente' },
  { value: 'En Progreso', label: 'En Progreso' },
  { value: 'Completada', label: 'Completada' }
];

// Opciones de ordenamiento
const sortOptions = [
  { value: 'fecha', label: 'Fecha (más reciente)' },
  { value: 'fecha-desc', label: 'Fecha (más antigua)' },
  { value: 'tipo', label: 'Tipo (A-Z)' },
  { value: 'tipo-desc', label: 'Tipo (Z-A)' },
  { value: 'estado', label: 'Estado (A-Z)' },
  { value: 'estado-desc', label: 'Estado (Z-A)' }
];

// Datos mock para desarrollo
const mockMisiones = [
  {
    id: "MSN-001",
    tipo: "Inspección",
    estado: "Completada",
    dron_id: "DRN-001",
    dron_modelo: "Aquila X2",
    fecha_inicio: "2024-01-15T08:30:00Z",
    fecha_fin: "2024-01-15T10:15:00Z",
    ruta: {
      waypoints: [
        { lat: -33.45, lon: -70.66 },
        { lat: -33.44, lon: -70.65 },
        { lat: -33.43, lon: -70.64 }
      ]
    }
  },
  {
    id: "MSN-002",
    tipo: "Entrega",
    estado: "En Progreso",
    dron_id: "DRN-002",
    dron_modelo: "Falcon M1",
    fecha_inicio: "2024-01-16T14:00:00Z",
    fecha_fin: null,
    ruta: {
      waypoints: [
        { lat: -33.42, lon: -70.63 },
        { lat: -33.41, lon: -70.62 }
      ]
    }
  },
  {
    id: "MSN-003",
    tipo: "Vigilancia",
    estado: "Pendiente",
    dron_id: "DRN-003",
    dron_modelo: "Orion L",
    fecha_inicio: "2024-01-17T09:00:00Z",
    fecha_fin: null,
    ruta: {
      waypoints: [
        { lat: -33.40, lon: -70.61 },
        { lat: -33.39, lon: -70.60 },
        { lat: -33.38, lon: -70.59 },
        { lat: -33.37, lon: -70.58 }
      ]
    }
  },
  {
    id: "MSN-004",
    tipo: "Inspección",
    estado: "Completada",
    dron_id: "DRN-004",
    dron_modelo: "Phoenix Pro",
    fecha_inicio: "2024-01-14T16:30:00Z",
    fecha_fin: "2024-01-14T18:45:00Z",
    ruta: {
      waypoints: [
        { lat: -33.46, lon: -70.67 },
        { lat: -33.47, lon: -70.68 }
      ]
    }
  },
  {
    id: "MSN-005",
    tipo: "Entrega",
    estado: "Pendiente",
    dron_id: "DRN-005",
    dron_modelo: "Eagle V3",
    fecha_inicio: "2024-01-18T11:00:00Z",
    fecha_fin: null,
    ruta: {
      waypoints: [
        { lat: -33.48, lon: -70.69 },
        { lat: -33.49, lon: -70.70 }
      ]
    }
  },
  {
    id: "MSN-006",
    tipo: "Vigilancia",
    estado: "En Progreso",
    dron_id: "DRN-006",
    dron_modelo: "Hawk Mini",
    fecha_inicio: "2024-01-16T07:15:00Z",
    fecha_fin: null,
    ruta: {
      waypoints: [
        { lat: -33.50, lon: -70.71 },
        { lat: -33.51, lon: -70.72 },
        { lat: -33.52, lon: -70.73 }
      ]
    }
  }
];

// Computadas para filtrado y ordenamiento
const filteredMisiones = computed(() => {
  let result = [...misiones.value];

  // Filtrar por búsqueda
  if (searchQuery.value.trim()) {
    const query = searchQuery.value.toLowerCase();
    result = result.filter(mision => 
      mision.tipo.toLowerCase().includes(query) ||
      mision.id.toLowerCase().includes(query) ||
      (mision.dron_modelo && mision.dron_modelo.toLowerCase().includes(query))
    );
  }

  // Filtrar por estado
  if (statusFilter.value !== 'all') {
    result = result.filter(mision => mision.estado === statusFilter.value);
  }

  // Ordenar
  result.sort((a, b) => {
    let aVal, bVal;
    
    if (sortBy.value.includes('fecha')) {
      aVal = new Date(a.fecha_inicio);
      bVal = new Date(b.fecha_inicio);
    } else if (sortBy.value.includes('tipo')) {
      aVal = a.tipo.toLowerCase();
      bVal = b.tipo.toLowerCase();
    } else if (sortBy.value.includes('estado')) {
      aVal = a.estado.toLowerCase();
      bVal = b.estado.toLowerCase();
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
    'Pendiente': 0,
    'En Progreso': 0,
    'Completada': 0,
    total: misiones.value.length
  };

  misiones.value.forEach(mision => {
    counts[mision.estado]++;
  });

  return counts;
});

// Función para formatear fecha
const formatDate = (dateString) => {
  if (!dateString) return 'N/A';
  const date = new Date(dateString);
  return date.toLocaleDateString('es-ES', {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit'
  });
};

// Función para calcular duración
const calculateDuration = (inicio, fin) => {
  if (!inicio || !fin) return 'En curso';
  const start = new Date(inicio);
  const end = new Date(fin);
  const diffMs = end - start;
  const diffHours = Math.floor(diffMs / (1000 * 60 * 60));
  const diffMinutes = Math.floor((diffMs % (1000 * 60 * 60)) / (1000 * 60));
  return `${diffHours}h ${diffMinutes}m`;
};

// Función para cargar misiones
const loadMisiones = async () => {
  loading.value = true;
  error.value = '';
  
  try {
    // Intentar cargar desde API primero
    const { data } = await api.get('/misiones');
    misiones.value = data;
  } catch (e) {
    console.warn('API no disponible, usando datos mock:', e.message);
    // Si falla la API, usar datos mock
    await new Promise(resolve => setTimeout(resolve, 1000)); // Simular carga
    misiones.value = mockMisiones;
  } finally {
    loading.value = false;
  }
};

// Función para reintentar carga
const retryLoad = () => {
  loadMisiones();
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

onMounted(() => {
  loadMisiones();
  loadDrones();
});
</script>

<style scoped>
/* === SELECT DRON === */
.select-dron {
  width: 100%;
  padding: 0.5rem;
  border-radius: 6px;
  border: 1px solid #cbd5e1;
  background: #f1f5f9;
  font-size: 1rem;
  margin-top: 0.25rem;
}

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

.misiones-grid {
  display: grid;
  gap: 1rem;
  grid-template-columns: 1fr;
}

.mision-card {
  background: white;
  border: 1px solid #e0e7ff;
  border-radius: 8px;
  padding: 1rem;
  transition: box-shadow 0.2s, transform 0.2s;
}

.mision-card:hover {
  box-shadow: 0 4px 12px rgba(99,102,241,0.12);
  transform: translateY(-2px);
}

.card-header {
  margin-bottom: 12px;
}

.mision-tipo {
  font-size: 1.1rem;
  font-weight: 600;
  color: #1f2937;
  margin: 0 0 4px 0;
}

.mision-id {
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

.status-badge.pendiente {
  background: rgba(217, 119, 6, 0.15);
  color: #d97706;
}

.status-badge.en_progreso {
  background: rgba(37, 99, 235, 0.15);
  color: #2563eb;
}

.status-badge.completada {
  background: rgba(34, 197, 94, 0.15);
  color: #22c55e;
}

/* Vista desktop - Tabla */
@media (min-width: 768px) {
  .mobile-view {
    display: none;
  }
  
  .desktop-view {
    display: block;
  }

  .misiones-grid {
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

.mision-id-cell {
  font-family: 'Courier New', monospace;
  font-size: 0.875rem;
  color: #9ca3af;
}

.mision-tipo-cell {
  font-weight: 600;
  color: #1f2937;
}

.mision-dron-cell {
  color: #374151;
}

.mision-fecha-cell {
  color: #374151;
  font-size: 0.875rem;
}

.mision-duracion-cell {
  color: #374151;
  text-align: center;
}

.mision-puntos-cell {
  color: #374151;
  text-align: center;
}

.mision-status-cell {
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
.mision-card:focus-within {
  outline: 2px solid #6366f1;
  outline-offset: 2px;
}

table tr:focus-within {
  outline: 2px solid #6366f1;
  outline-offset: -2px;
}

/* Modal Crear Misión */
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  width: 100vw;
  height: 100vh;
  background: rgba(99,102,241,0.15);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
}
.modal-content {
  background: #fff;
  border-radius: 16px;
  box-shadow: 0 8px 32px rgba(99,102,241,0.18);
  padding: 2rem 2.5rem;
  min-width: 320px;
  max-width: 90vw;
  width: 400px;
  display: flex;
  flex-direction: column;
  gap: 1rem;
}
.modal-content h2 {
  margin: 0 0 1rem 0;
  color: #6366f1;
  font-size: 1.3rem;
  font-weight: 700;
  text-align: center;
}
.form-group {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
  margin-bottom: 1rem;
}
.form-group label {
  font-weight: 500;
  color: #374151;
}
.form-group input {
  padding: 10px 14px;
  border: 1px solid #e0e7ff;
  border-radius: 8px;
  font-size: 1rem;
  outline: none;
  background: #f8fafc;
  transition: border-color 0.2s;
}
.form-group input:focus {
  border-color: #6366f1;
  box-shadow: 0 0 0 2px rgba(99,102,241,0.12);
}
.modal-actions {
  display: flex;
  gap: 1rem;
  justify-content: flex-end;
  margin-top: 1rem;
}
.crear-btn {
  background: #6366f1;
  color: white;
  border: none;
  border-radius: 8px;
  padding: 10px 18px;
  font-weight: 600;
  cursor: pointer;
  box-shadow: 0 2px 8px rgba(99,102,241,0.15);
  transition: background 0.2s;
}
.crear-btn:hover:not(:disabled) {
  background: #4f46e5;
}
.crear-btn:disabled {
  background: #a5b4fc;
  cursor: not-allowed;
}
.cancelar-btn {
  background: #e0e7ff;
  color: #6366f1;
  border: none;
  border-radius: 8px;
  padding: 10px 18px;
  font-weight: 600;
  cursor: pointer;
  transition: background 0.2s;
}
.cancelar-btn:hover:not(:disabled) {
  background: #c7d2fe;
}
</style>
