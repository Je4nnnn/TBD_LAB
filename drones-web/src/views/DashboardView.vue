<template>
  <div class="page">
    <header>
      <h2>Flota de Drones</h2>
      <div class="right">

        <!-- --- BOTONES DE ADMINISTRADOR --- -->
        <template v-if="auth.user.rol === 'ADMIN'">
          <RouterLink class="btn btn-accent" to="/misiones/nueva">
            + Nueva Misión
          </RouterLink>

          <RouterLink class="btn btn-secondary" to="/drones/nuevo">
            + Nuevo Dron
          </RouterLink>
        </template>
        <!-- -------------------------------- -->

        <RouterLink class="btn" to="/reportes">Reportes</RouterLink>
        <strong>{{ auth.user.nombre }}</strong> ({{ auth.user.rol }})
        <button @click="logout">Salir</button>
      </div>
    </header>

    <section class="grid">
      <div class="card">
        <h3>Drones</h3>
        <button @click="loadDrones">Refrescar</button>
        <table v-if="drones.length">
          <thead>
            <tr><th>Modelo</th><th>Estado</th><th>Batería%</th><th>Lat</th><th>Lon</th></tr>
          </thead>
          <tbody>
            <tr v-for="d in drones" :key="d.id">
              <td>{{ d.modelo }}</td>
              <td>{{ d.estado }}</td>
              <td>{{ d.bateria_pct }}</td>
              <td>{{ d.ultima_lat ?? '-' }}</td>
              <td>{{ d.ultima_lon ?? '-' }}</td>
            </tr>
          </tbody>
        </table>
        <p v-else>Cargando...</p>
      </div>

      <div class="card">
        <h3>Misiones</h3>
        <button @click="loadMisiones">Refrescar</button>
        <table v-if="misiones.length">
          <thead>
            <tr><th>Tipo</th><th>Estado</th><th>Dron</th><th>Acciones</th></tr>
          </thead>
          <tbody>
            <tr v-for="m in misiones" :key="m.id">
              <td>{{ m.tipo }}</td>
              <td>{{ m.estado }}</td>
              <td>{{ m.dron_modelo || '-' }}</td>
              <td class="actions">
                <button @click="completar(m.id)">Completar</button>
                <button @click="fallar(m.id)">Fallar</button>
              </td>
            </tr>
          </tbody>
        </table>
        <p v-else>Cargando...</p>
      </div>

      <div class="card map">
        <h3>Mapa</h3>
        <DronesMap :drones="drones" :misiones="misiones" />
      </div>
    </section>
  </div>
</template>

<script setup>
import { onMounted, ref } from 'vue';
import { useAuthStore } from '../stores/auth';
import api from '../api/axios';
import DronesMap from '../components/DronesMap.vue';

const auth = useAuthStore();
const drones = ref([]);
const misiones = ref([]);

const loadDrones = async () => {
  const { data } = await api.get('/drones');
  drones.value = data;
};
const loadMisiones = async () => {
  const { data } = await api.get('/misiones');
  misiones.value = data;
};

const completar = async (id) => {
  await api.post(`/misiones/${id}/completar`, {});
  await loadMisiones();
};
const fallar = async (id) => {
  const motivo = prompt('Motivo de la falla (opcional):') || null;
  await api.post(`/misiones/${id}/fallar`, { motivo });
  await loadMisiones();
};

const logout = () => auth.logout();

onMounted(() => {
  loadDrones();
  loadMisiones();
});
</script>

<style>
.page { padding: 1.5rem; }
header { display:flex; align-items:center; justify-content:space-between; margin-bottom: 1rem; gap: .75rem; }
.right { display:flex; align-items:center; gap:.5rem; }
.btn { padding:.35rem .6rem; border:1px solid #ddd; border-radius:6px; background:#f7f7f7; text-decoration:none; color: #333; font-size: 0.9rem; }

/* Botón Azul para Misiones */
.btn-accent { background-color: #2563eb; color: white; border: 1px solid #2563eb; font-weight: bold; }
.btn-accent:hover { background-color: #1d4ed8; color: white; }

/* Botón Verde Oscuro para Drones */
.btn-secondary { background-color: #059669; color: white; border: 1px solid #059669; font-weight: bold; }
.btn-secondary:hover { background-color: #047857; color: white; }

.grid { display:grid; grid-template-columns: 1fr 1fr; gap: 1rem; }
.card { background:#fff; border:1px solid #ddd; border-radius: 10px; padding: 1rem; }
.map { grid-column: 1 / -1; }
table { width: 100%; border-collapse: collapse; margin-top: .5rem; }
th, td { border: 1px solid #eee; padding: .4rem; text-align: left; }
.actions button { margin-right: .25rem; }
</style>