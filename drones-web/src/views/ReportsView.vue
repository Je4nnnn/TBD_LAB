<template>
  <div class="dashboard-container">
    <Sidebar :active="'reportes'" @navigate="navigateTo" @logout="logout" />
    <main class="main-content">
      <header class="content-header">
        <h1 class="header-title">Reportes</h1>
      </header>
      <div class="dashboard-content">
        <div class="data-card">
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
    </main>
  </div>
</template>

<script setup>
import { onMounted, ref } from 'vue';
import api from '../api/axios';
import Sidebar from '../components/Sidebar.vue';
import { useRouter } from 'vue-router';
import { useAuthStore } from '../stores/auth';

const rows = ref([]);
const loading = ref(false);
const router = useRouter();
const auth = useAuthStore();

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

const navigateTo = (route) => {
  router.push(route);
};
const logout = () => {
  auth.logout();
  router.push('/login');
};

onMounted(load);
</script>

<style scoped>
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
.dashboard-content {
  display: flex;
  flex-direction: column;
}
.data-card {
  background: #fff;
  border-radius: 12px;
  padding: 1.5rem;
  box-shadow: 0 4px 12px rgba(99,102,241,0.08);
  margin-bottom: 1.5rem;
  border: 1px solid #e0e7ff;
}
.toolbar {
  margin-bottom: .75rem;
}
table {
  width: 100%;
  border-collapse: collapse;
}
th, td {
  border: 1px solid #eee;
  padding: .4rem;
  text-align: left;
}
</style>
