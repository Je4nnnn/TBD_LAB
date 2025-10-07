<template>
  <section style="max-width:1100px;margin:24px auto;padding:0 16px;">
    <h2 style="margin:0 0 16px;">Drones</h2>

    <div style="display:grid;grid-template-columns:repeat(auto-fill,minmax(260px,1fr));gap:16px;">
      <article v-for="d in drones" :key="d.id"
               style="border:1px solid #334155;border-radius:12px;padding:12px;background:#0f172a;">
        <header style="display:flex;justify-content:space-between;align-items:center;">
          <strong>{{ d.modelo }}</strong>
          <span :style="pill(d.estado)">{{ d.estado }}</span>
        </header>
        <p style="margin:8px 0 0;">Batería: <b>{{ d.bateria_pct ?? '—' }}%</b></p>
        <p style="margin:4px 0 0;">Última pos.: <code v-if="d.ultima_lat !== null">{{ d.ultima_lat }}, {{ d.ultima_lon }}</code><span v-else>—</span></p>
      </article>
    </div>

    <!-- Requisito: reservar espacio para mapa -->
    <div style="margin-top:24px;border:2px dashed #334155;border-radius:12px;height:320px;display:grid;place-items:center;">
      <em>Mapa (placeholder). Aquí irá Leaflet/Mapbox con rutas y posiciones en vivo.</em>
    </div>
  </section>
</template>

<script setup>
import { ref, onMounted } from 'vue';
import http from '../lib/http';

const drones = ref([]);

function pill(estado){
  const colors = {
    'Disponible': '#16a34a',
    'En Vuelo': '#2563eb',
    'En Mantenimiento': '#f59e0b',
  };
  const bg = colors[estado] || '#64748b';
  return `background:${bg}22;border:1px solid ${bg};color:${bg};padding:2px 8px;border-radius:999px;font-size:12px`;
}

onMounted(async () => {
  const { data } = await http.get('/drones');
  drones.value = data;
});
</script>
