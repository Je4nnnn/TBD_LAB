<template>
  <div class="page">
    <header>
      <h2>Registrar Nuevo Dron</h2>
      <router-link class="btn" to="/">Cancelar</router-link>
    </header>

    <div class="form-container">
      <div class="card">

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

        <div class="info-box">
          <small>El dron se creará con estado <b>Disponible</b> y Batería al <b>100%</b> por defecto.</small>
        </div>

        <p v-if="error" class="error-msg">{{ error }}</p>

        <button class="btn-primary" @click="guardar" :disabled="loading">
          {{ loading ? 'Guardando...' : 'Registrar Dron' }}
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue';
import { useRouter } from 'vue-router';
import api from '../api/axios';

const router = useRouter();
const loading = ref(false);
const error = ref('');

// Form Data
const modelo = ref('');
const capacidad = ref('');
const autonomia = ref('');

const guardar = async () => {
  if (!modelo.value || !capacidad.value || !autonomia.value) {
    error.value = 'Todos los campos son obligatorios.';
    return;
  }

  loading.value = true;
  error.value = '';

  try {
    await api.post('/drones', {
      modelo: modelo.value,
      capacidad_kg: parseFloat(capacidad.value),
      autonomia_min: parseInt(autonomia.value)
    });

    // Volver al dashboard tras éxito
    router.push('/');
  } catch (e) {
    console.error(e);
    error.value = 'Error al registrar el dron. Verifique los datos.';
  } finally {
    loading.value = false;
  }
};
</script>

<style scoped>
.form-container { max-width: 500px; margin: 0 auto; }
.form-group { margin-bottom: 1.2rem; text-align: left; }
.form-row { display: grid; grid-template-columns: 1fr 1fr; gap: 1rem; }

label { display: block; font-weight: 600; margin-bottom: 0.5rem; font-size: 0.9rem; }
input {
  width: 100%; padding: 0.75rem; border-radius: 6px;
  border: 1px solid #ccc; background: #fff; color: #333; font-size: 1rem;
}

.info-box {
  background: #eff6ff; color: #1e40af; padding: 10px;
  border-radius: 6px; margin-bottom: 1rem; text-align: center; border: 1px solid #dbeafe;
}

.btn-primary {
  background-color: #2563eb; color: white; border: none;
  padding: 12px 24px; font-size: 1rem; width: 100%;
  border-radius: 6px; cursor: pointer; font-weight: bold;
}
.btn-primary:hover { background-color: #1d4ed8; }
.btn-primary:disabled { background-color: #93c5fd; cursor: not-allowed; }
.error-msg { color: #dc2626; margin-bottom: 1rem; font-weight: bold; text-align: center; }
</style>