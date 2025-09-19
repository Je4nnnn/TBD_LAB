<!-- src/pages/Drones.vue -->
<script setup>
import { onMounted, ref } from 'vue';
import { api } from '../api';

const drones = ref([]);
const loading = ref(true);
const error = ref('');

onMounted(async () => {
  try {
    const { data } = await api.get('/drones');
    drones.value = data;
  } catch (e) {
    error.value = 'No se pudo cargar la lista';
  } finally {
    loading.value = false;
  }
});
</script>

<template>
  <div style="text-align:center">
    <h1>Drones</h1>
    <div v-if="loading">Cargando...</div>
    <div v-else-if="error" style="color:#f55">{{ error }}</div>
    <div v-else style="max-width:560px; margin:0 auto; text-align:left;">
      <div v-for="d in drones" :key="d.id" style="border:1px solid #444; border-radius:8px; padding:12px; margin:10px 0;">
        <div><b>{{ d.modelo }}</b></div>
        <div>Estado: {{ d.estado }}</div>
        <div>Batería: {{ d.bateria_pct }}%</div>
        <div v-if="d.ultima_lat != null">Última pos: {{ d.ultima_lat }}, {{ d.ultima_lon }}</div>
      </div>
    </div>
  </div>
</template>
