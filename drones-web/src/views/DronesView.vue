<template>
  <div class="dashboard-container">
    <Sidebar :active="'drones'" @navigate="navigateTo" @logout="logout" />
    <main class="main-content">
      <section style="max-width:1100px;margin:24px auto;padding:0 16px;">
        <h2 style="margin:0 0 16px;">Drones</h2>
        <div style="display:grid;grid-template-columns:repeat(auto-fill,minmax(260px,1fr));gap:16px;">
          <article v-for="d in drones" :key="d.id"
                   style="border:1px solid #334155;border-radius:12px;padding:12px;background:#0f172a;">
            <header style="display:flex;justify-content:space-between;align-items:center;">
              <strong>{{ d.modelo }}</strong>
              <span :style="pill(d.estado)">{{ d.estado }}</span>
            </header>
            <p style="margin:8px 0 0;">Capacidad: <b>{{ d.capacidad_kg ?? '—' }} kg</b></p>
            <p style="margin:4px 0 0;">Autonomía: <b>{{ d.autonomia_min ?? '—' }} min</b></p>
            <p style="margin:4px 0 0;">Batería: <b>{{ d.bateria_pct ?? '—' }}%</b></p>
            <p style="margin:4px 0 0;">Última pos.: <code v-if="d.ultima_lat !== null">{{ d.ultima_lat }}, {{ d.ultima_lon }}</code><span v-else>—</span></p>
            <button class="btn-elim" @click="eliminarDron(d.id)">Eliminar</button>
          </article>
        </div>
        <!-- Requisito: reservar espacio para mapa -->
        <div style="margin-top:24px;border:2px dashed #334155;border-radius:12px;height:320px;display:grid;place-items:center;">
        </div>
      </section>
    </main>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue';
import http from '../lib/http';
import Sidebar from '../components/Sidebar.vue';
import { useRouter } from 'vue-router';
import { useAuthStore } from '../stores/auth';

const drones = ref([]);

async function eliminarDron(id) {
  if (!confirm('¿Seguro que deseas eliminar este dron?')) return;
  await http.delete(`/drones/${id}`);
  drones.value = drones.value.filter(d => d.id !== id);
}

const router = useRouter();
const auth = useAuthStore();

function pill(estado){
  const colors = {
    'Disponible': '#16a34a',
    'En Vuelo': '#2563eb',
    'En Mantenimiento': '#f59e0b',
  };
  const bg = colors[estado] || '#64748b';
  return `background:${bg}22;border:1px solid ${bg};color:${bg};padding:2px 8px;border-radius:999px;font-size:12px`;
}

const navigateTo = (route) => {
  router.push(route);
};
const logout = () => {
  auth.logout();
  router.push('/login');
};

onMounted(async () => {
  const { data } = await http.get('/drones');
  drones.value = data;
});
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

.btn-elim {
  margin-top: 12px;
  width: 100%;
  background: #dc2626;
  color: white;
  border: none;
  border-radius: 8px;
  padding: 8px 0;
  font-weight: bold;
  cursor: pointer;
  transition: background 0.2s;
}
.btn-elim:hover {
  background: #b91c1c;
}

</style>
