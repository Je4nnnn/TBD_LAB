<template>
  <div class="dashboard-container">
    <Sidebar :active="'drones'" @navigate="navigateTo" @logout="logout" />
    
    <main class="main-content">
      <header class="content-header">
        <h1 class="header-title">Registrar Nuevo Dron</h1>
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
            <h2><span class="icon">🛸</span> Registrar Dron</h2>
            <router-link class="btn-back" to="/drones">← Volver a Drones</router-link>
          </div>

          <div class="form-container">
            <div class="form-group">
              <label>Modelo del Dron</label>
              <input v-model="modelo" placeholder="Ej: DJI-Mavic-3" type="text" />
            </div>

      <div class="form-row">
        <div class="form-group">
          <label>Capacidad (Kg)</label>
          <input v-model.number="capacidad" type="number" step="0.1" min="0" placeholder="0.0" />
        </div>

        <div class="form-group">
          <label>Autonomía (minutos)</label>
          <input v-model.number="autonomia" type="number" step="1" min="0" placeholder="0" />
        </div>
      </div>
      <div class="form-row">
        <div class="form-group">
          <label>Latitud inicial</label>
          <input v-model.number="lat" type="number" step="0.000001" min="-90" max="90" placeholder="Ej: -33.450000" />
        </div>
        <div class="form-group">
          <label>Longitud inicial</label>
          <input v-model.number="lon" type="number" step="0.000001" min="-180" max="180" placeholder="Ej: -70.660000" />
        </div>
      </div>

            <div class="info-box">
              <small>El dron se creará con estado <b>Disponible</b> y Batería al <b>100%</b> por defecto.</small>
            </div>

            <p v-if="error" class="error-msg">{{ error }}</p>

            <div class="form-actions">
              <router-link class="btn-secondary" to="/drones">Cancelar</router-link>
              <button class="btn-primary" @click="guardar" :disabled="loading">
                {{ loading ? 'Guardando...' : 'Registrar Dron' }}
              </button>
            </div>
          </div>
        </div>
      </div>
    </main>
  </div>
</template>

<script setup>
import { ref } from 'vue';
import { useRouter } from 'vue-router';
import { useAuthStore } from '../stores/auth';
import Sidebar from '../components/Sidebar.vue';
import api from '../api/axios';

const router = useRouter();
const auth = useAuthStore();
const loading = ref(false);
const error = ref('');

const modelo = ref('');
const capacidad = ref('');
const autonomia = ref('');
const lat = ref(null);
const lon = ref(null);

const navigateTo = (route) => {
  router.push(route);
};

const logout = () => {
  auth.logout();
  router.push('/login');
};

const guardar = async () => {
  if (!modelo.value || !capacidad.value || !autonomia.value || lat.value === null || lon.value === null) {
    error.value = 'Todos los campos son obligatorios, incluida la ubicación.';
    return;
  }

  loading.value = true;
  error.value = '';

  try {
    await api.post('/drones', {
      modelo: modelo.value,
      capacidad_kg: parseFloat(capacidad.value),
      autonomia_min: parseInt(autonomia.value),
      lat: lat.value,
      lon: lon.value
    });

    router.push('/drones');
  } catch (e) {
    console.error(e);
    error.value = 'Error al registrar el dron. Verifique los datos.';
  } finally {
    loading.value = false;
  }
};
</script>

<style scoped>
.dashboard-container {
  display: flex;
  min-height: 100vh;
  background: #f8fafc;
  font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
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
}

.header-title {
  font-size: 1.875rem;
  font-weight: 700;
  color: #1f2937;
  margin: 0;
}

.user-info {
  display: flex;
  align-items: center;
  gap: 1rem;
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
  box-shadow: 0 2px 8px rgba(99, 102, 241, 0.25);
}

.dashboard-content {
  display: flex;
  flex-direction: column;
}

.data-card {
  background: #fff;
  border-radius: 12px;
  padding: 2rem;
  box-shadow: 0 4px 12px rgba(99, 102, 241, 0.08);
  border: 1px solid #e0e7ff;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 2rem;
  padding-bottom: 1rem;
  border-bottom: 2px solid #e0e7ff;
}

.card-header h2 {
  font-size: 1.5rem;
  font-weight: 600;
  color: #1f2937;
  margin: 0;
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.icon {
  font-size: 1.5rem;
}

.btn-back {
  background: transparent;
  color: #6366f1;
  border: 2px solid #6366f1;
  text-decoration: none;
  font-weight: 600;
  padding: 8px 16px;
  border-radius: 8px;
  transition: all 0.2s;
}

.btn-back:hover {
  background: #6366f1;
  color: white;
}

.form-container {
  max-width: 700px;
}

.form-group {
  margin-bottom: 1.5rem;
}

.form-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 1rem;
}

label {
  display: block;
  font-weight: 600;
  margin-bottom: 0.5rem;
  color: #374151;
  font-size: 0.9rem;
}

input {
  width: 100%;
  padding: 0.75rem;
  border-radius: 8px;
  border: 2px solid #e5e7eb;
  background: #fff;
  color: #1f2937;
  font-size: 1rem;
  transition: border-color 0.2s;
  font-family: inherit;
}

input:focus {
  outline: none;
  border-color: #6366f1;
  box-shadow: 0 0 0 3px rgba(99, 102, 241, 0.1);
}

.info-box {
  background: #eff6ff;
  color: #1e40af;
  padding: 1rem;
  border-radius: 8px;
  margin-bottom: 1.5rem;
  text-align: center;
  border: 1px solid #dbeafe;
}

.error-msg {
  color: #dc2626;
  background: #fee2e2;
  padding: 0.75rem;
  border-radius: 8px;
  margin-bottom: 1rem;
  font-weight: 600;
  text-align: center;
  border: 1px solid #fecaca;
}

.form-actions {
  display: flex;
  gap: 1rem;
  justify-content: flex-end;
  margin-top: 2rem;
}

.btn-primary,
.btn-secondary {
  padding: 0.75rem 1.5rem;
  font-size: 1rem;
  font-weight: 600;
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.2s;
  border: none;
  text-decoration: none;
  display: inline-flex;
  align-items: center;
  justify-content: center;
}

.btn-primary {
  background: #6366f1;
  color: white;
}

.btn-primary:hover {
  background: #4f46e5;
  transform: translateY(-1px);
  box-shadow: 0 4px 12px rgba(99, 102, 241, 0.3);
}

.btn-primary:disabled {
  background: #c7d2fe;
  cursor: not-allowed;
  transform: none;
}

.btn-secondary {
  background: transparent;
  color: #6b7280;
  border: 2px solid #e5e7eb;
}

.btn-secondary:hover {
  background: #f9fafb;
  border-color: #d1d5db;
}
</style>