<template>
  <div class="page">
    <header>
      <h2>Reportes</h2>
      <RouterLink class="btn" to="/">← Volver</RouterLink>
    </header>

    <div class="card">
      <div class="toolbar">
        <button @click="refresh" :disabled="loading">{{ loading ? 'Actualizando…' : 'Refrescar vista materializada' }}</button>
      </div>

      <table v-if="rows.length">
        <thead>
          <tr><th>Tipo</th><th>Total</th><th>Horas promedio</th></tr>
        </thead>
        <tbody>
          <tr v-for="r in rows" :key="r.tipo">
            <td>{{ r.tipo }}</td>
            <td>{{ r.total }}</td>
            <td>{{ Number(r.horas_promedio).toFixed(2) }}</td>
          </tr>
        </tbody>
      </table>
      <p v-else>Cargando…</p>
    </div>
  </div>
</template>

<script setup>
import { onMounted, ref } from 'vue';
import api from '../api/axios';

const rows = ref([]);
const loading = ref(false);

const load = async () => {
  const { data } = await api.get('/reportes/resumen');
  rows.value = data;
};

const refresh = async () => {
  loading.value = true;
  try {
    await api.post('/reportes/resumen/refresh');
    await load();
  } finally {
    loading.value = false;
  }
};

onMounted(load);
</script>

<style>
.page { padding: 1.5rem; }
header { display:flex; align-items:center; justify-content:space-between; margin-bottom: 1rem; }
.card { background:#fff; border:1px solid #ddd; border-radius: 10px; padding: 1rem; }
.btn { padding:.35rem .6rem; border:1px solid #ddd; border-radius:6px; background:#f7f7f7; text-decoration:none; }
.toolbar { margin-bottom: .75rem; }
table { width: 100%; border-collapse: collapse; }
th, td { border: 1px solid #eee; padding: .4rem; text-align: left; }
</style>
