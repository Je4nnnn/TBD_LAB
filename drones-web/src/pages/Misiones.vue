<!-- src/pages/Misiones.vue -->
<script setup>
import { ref, onMounted } from 'vue';
import { api } from '../api';

const tipo = ref('Inspección');
const rutaJson = ref(JSON.stringify({ waypoints: [[-33.45,-70.66],[-33.44,-70.65]] }, null, 2));
const misiones = ref([]);
const loading = ref(false);
const msg = ref('');
const err = ref('');

const listar = async () => {
  loading.value = true;
  err.value = '';
  try {
    const { data } = await api.get('/misiones');
    misiones.value = data;
  } catch (e) {
    err.value = 'No se pudo listar misiones';
  } finally {
    loading.value = false;
  }
};

const crear = async () => {
  msg.value = '';
  err.value = '';
  try {
    const body = {
      tipo: tipo.value,
      ruta_planeada: JSON.parse(rutaJson.value)
    };
    await api.post('/misiones', body);
    msg.value = 'Misión creada';
    await listar();
  } catch (e) {
    err.value = 'Error al crear misión (JSON o permisos)';
  }
};

onMounted(listar);
</script>

<template>
  <div style="text-align:center">
    <h1>Misiones</h1>

    <div style="margin:16px auto; max-width:520px; text-align:left; border:1px solid #444; border-radius:8px; padding:12px;">
      <label>Tipo</label>
      <select v-model="tipo" style="display:block; margin:6px 0 10px 0;">
        <option>Inspección</option>
        <option>Entrega</option>
        <option>Vigilancia</option>
      </select>

      <label>Ruta planeada (JSON)</label>
      <textarea v-model="rutaJson" rows="8" style="width:100%; margin-top:6px; font-family:monospace;"></textarea>

      <button @click="crear" style="margin-top:10px;">Crear</button>
      <span v-if="msg" style="color:#0a0; margin-left:10px;">✔ {{ msg }}</span>
      <span v-if="err" style="color:#f55; margin-left:10px;">✖ {{ err }}</span>
    </div>

    <h3>Listado</h3>
    <div v-if="loading">Cargando...</div>
    <ul v-else style="max-width:520px; margin:0 auto; text-align:left;">
      <li v-for="m in misiones" :key="m.id" style="border-bottom:1px dashed #555; padding:8px 0;">
        <b>{{ m.tipo }}</b> — {{ m.estado }} <span v-if="m.inicio">— {{ m.inicio }}</span>
      </li>
    </ul>
  </div>
</template>
