<!-- src/pages/Reportes.vue -->
<script setup>
import { ref, onMounted } from 'vue';
import { api } from '../api';

const resumen = ref(null);
const err = ref('');

onMounted(async () => {
  try {
    // Ajusta al endpoint real de tu backend si es distinto
    const { data } = await api.get('/reportes/resumen-mensual');
    resumen.value = data;
  } catch (e) {
    err.value = 'No se pudo cargar el reporte';
  }
});
</script>

<template>
  <div style="text-align:center">
    <h1>Reportes</h1>
    <p v-if="err" style="color:#f55">{{ err }}</p>
    <pre v-else-if="resumen" style="text-align:left; max-width:720px; margin:0 auto; border:1px solid #444; border-radius:8px; padding:12px; overflow:auto;">
{{ resumen }}
    </pre>
    <p v-else>Cargando...</p>
  </div>
</template>
