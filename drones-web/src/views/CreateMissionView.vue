<template>
  <div class="dashboard-container">
    <Sidebar :active="'misiones'" @navigate="navigateTo" @logout="logout" />

    <main class="main-content">
      <header class="content-header">
        <h1 class="header-title">Crear Nueva Misión</h1>
        <div class="user-info">
          <div class="user-details">
            <span class="user-name">{{ auth.nombre }}</span>
            <span class="user-role">({{ auth.rol }})</span>
          </div>
          <div class="user-avatar">{{ auth.nombre.charAt(0) }}</div>
        </div>
      </header>

      <div class="dashboard-content">
        <div class="data-card">
          <div class="card-header">
            <h2><span class="icon">🎯</span> Crear Misión</h2>
            <router-link class="btn-back" :to="{ name: 'dashboard' }">← Volver al Dashboard</router-link>
          </div>

          <div class="card">
        <div class="form-group">
          <label>Tipo de Misión</label>
          <select v-model="tipo">
            <option>Inspección</option>
            <option>Entrega</option>
            <option>Vigilancia</option>
          </select>
        </div>

        <div class="form-group">
          <label>Asignar Dron (Opcional)</label>
          <select v-model="dronId">
            <option :value="null">-- Dejar Pendiente --</option>
            <option v-for="d in dronesDisponibles" :key="d.id" :value="d.id">
              {{ d.modelo }} (Bat: {{ d.bateria_pct }}% - {{ d.estado }})
            </option>
          </select>
          <p class="hint" v-if="dronesDisponibles.length === 0">
            No hay drones disponibles en este momento.
          </p>
        </div>

        <div class="form-group">
          <label>Ruta Planeada (JSON)</label>
          <textarea v-model="rutaJson" rows="6"></textarea>
          <p class="hint">Formato: {"waypoints": [[lat, lon], [lat, lon]]}</p>
        </div>

            <p v-if="error" class="error-msg">{{ error }}</p>

            <button class="btn-primary" @click="guardar" :disabled="loading">
              {{ loading ? 'Guardando...' : 'Crear Misión' }}
            </button>
          </div>
        </div>
      </div>
    </main>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue';
import { useRouter } from 'vue-router';
import { useAuthStore } from '../stores/auth';
import api from '../api/axios';
import Sidebar from '../components/Sidebar.vue';

const router = useRouter();
const auth = useAuthStore();
const loading = ref(false);
const error = ref('');
const dronesDisponibles = ref([]);

// Datos del formulario
const tipo = ref('Inspección');
const dronId = ref(null);
// Valor por defecto para facilitar la prueba
const rutaJson = ref(`{
  "waypoints": [
    [-33.450, -70.660],
    [-33.460, -70.670]
  ]
}`);

onMounted(async () => {
  try {
    // Cargamos drones para llenar el select
    const { data } = await api.get('/drones');
    // Filtramos solo los disponibles
    dronesDisponibles.value = data.filter(d => d.estado === 'Disponible');
  } catch (e) {
    console.error(e);
  }
});

const guardar = async () => {
  loading.value = true;
  error.value = '';
  try {
    // 1. Crear la misión
    const res = await api.post('/misiones', {
      tipo: tipo.value,
      ruta_json: rutaJson.value
    });

    const nuevaMisionId = res.data.id;

    // 2. Si seleccionó un dron, asignarlo inmediatamente
    if (dronId.value) {
      await api.post(`/misiones/${nuevaMisionId}/asignar/${dronId.value}`);
    }

    // 3. Volver al dashboard
    router.push('/');
  } catch (e) {
    console.error(e);
    error.value = 'Ocurrió un error al crear la misión. Verifique el formato JSON.';
  } finally {
    loading.value = false;
  }
};

const logout = () => {
  auth.logout();
  router.push('/login');
};

const navigateTo = (route) => {
  router.push(route);
};
</script>

<style scoped>
/* Reused dashboard layout styles */

.dashboard-container {
  font-family: 'Inter', Arial, Helvetica, sans-serif;
  display: flex;
  min-height: 100vh;
  background: #f8fafc;
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

.user-info {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 8px 16px;
  background: #eef2ff;
  border-radius: 50px;
  box-shadow: 0 2px 10px rgba(0,0,0,0.05);
}
.user-details { display: flex; flex-direction: column; align-items: flex-end; }
.user-name { font-weight: 600; color: #1f2937; }
.user-role { font-size: 0.9rem; color: #6366f1; }
.user-avatar {
  width: 40px; height: 40px; background: #6366f1; color: white;
  border-radius: 50%; display: flex; align-items: center; justify-content: center;
  font-weight: 600; box-shadow: 0 2px 8px rgba(99,102,241,0.25);
}

.dashboard-content { 
  display: flex; 
  flex-direction: column; 
  text-decoration: none;
}
.data-card { 
  background: #fff; 
  border-radius: 12px; 
  padding: 1.5rem; 
  box-shadow: 0 4px 12px rgba(99,102,241,0.08); border: 1px solid #e0e7ff; 
}
.card-header { 
  display:flex; 
  justify-content:space-between; 
  align-items:center; 
  margin-bottom:1rem; 
  text-decoration: none;
}

.card { background: white; padding: 1rem; border-radius: 8px; border: 1px solid #e6eefc; }
.btn-back { 
  background: transparent; 
  color: #6366f1; border: 
  none; text-decoration: none; 
  font-weight:600; padding: 8px 12px; 
  border-radius: 8px; 
}
.btn-back:hover { 
  background: #eef2ff; 
  text-decoration: none;
}

/* Original form styles */
.form-container { max-width: 700px; margin: 0 auto; }
.form-group { margin-bottom: 1.5rem; text-align: left; }
label { display: block; font-weight: 600; margin-bottom: 0.5rem; }
select, textarea {
  width: 100%; padding: 0.75rem; border-radius: 6px;
  border: 1px solid #ccc; font-family: monospace; background: #fff; color: #333;
}
.btn-primary {
  background-color: #2563eb; color: white; border: none;
  padding: 12px 24px; font-size: 1rem; width: 100%;
  border-radius: 6px; cursor: pointer;
}
.btn-primary:hover { background-color: #1d4ed8; }
.btn-primary:disabled { background-color: #93c5fd; cursor: not-allowed; }
.hint { font-size: 0.85rem; color: #666; margin-top: 4px; }
.error-msg { color: #dc2626; margin-bottom: 1rem; font-weight: bold; }
</style>