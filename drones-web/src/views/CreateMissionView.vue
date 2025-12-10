<template>
  <div class="page">
    <header>
      <h2>Crear Nueva Misión</h2>
      <router-link class="btn" to="/">Cancelar</router-link>
    </header>

    <div class="form-container">
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
</template>

<script setup>
import { ref, onMounted } from 'vue';
import { useRouter } from 'vue-router';
import api from '../api/axios';

const router = useRouter();
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
</script>

<style scoped>
.form-container { max-width: 600px; margin: 0 auto; }
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