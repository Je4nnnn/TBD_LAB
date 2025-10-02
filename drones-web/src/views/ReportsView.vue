<template>
  <section>
    <h2>Reportes</h2>
    <button @click="refresh" :disabled="loading">Refrescar</button>
    <table>
      <thead><tr><th>Tipo</th><th>Total</th><th>Horas Promedio</th></tr></thead>
      <tbody>
        <tr v-for="r in rows" :key="r.tipo">
          <td>{{ r.tipo }}</td>
          <td>{{ r.total }}</td>
          <td>{{ Number(r.horas_promedio).toFixed(2) }}</td>
        </tr>
      </tbody>
    </table>
  </section>
</template>

<script setup>
import { ref, onMounted } from 'vue';
import { api } from '../api';
const rows = ref([]); const loading = ref(false);
async function refresh(){
  loading.value = true;
  try {
    await api.post('/reportes/resumen/refresh');
    rows.value = (await api.get('/reportes/resumen')).data;
  } finally { loading.value = false; }
}
onMounted(refresh);
</script>
