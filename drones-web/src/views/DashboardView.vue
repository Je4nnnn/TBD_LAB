<template>
  <div class="page">
    <header>
      <h2>Flota de Drones</h2>
      <div>
        <strong>{{ auth.nombre }}</strong> ({{ auth.rol }})
        <button @click="logout">Salir</button>
      </div>
    </header>

    <section class="grid">
      <!-- Drones -->
      <div class="card">
        <h3>Drones</h3>
        <button @click="loadDrones">Refrescar</button>
        <table v-if="drones.length">
          <thead>
            <tr>
              <th>Modelo</th>
              <th>Estado</th>
              <th>Batería%</th>
              <th>Lat</th>
              <th>Lon</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="d in drones" :key="d.id">
              <td>{{ d.modelo }}</td>
              <td>{{ d.estado }}</td>
              <td>{{ d.bateria_pct }}</td>
              <td>{{ fmt(d.ultima_lat) }}</td>
              <td>{{ fmt(d.ultima_lon) }}</td>
            </tr>
          </tbody>
        </table>
        <p v-else>Cargando...</p>
      </div>

      <!-- Misiones -->
      <div class="card">
        <h3>Misiones</h3>
        <button @click="loadMisiones">Refrescar</button>
        <table v-if="misiones.length">
          <thead>
            <tr>
              <th>Tipo</th>
              <th>Estado</th>
              <th>Dron</th>
              <th>Acciones</th>
            </tr>
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

      <!-- Mapa interactivo -->
      <div class="card map">
        <h3>Mapa</h3>
        <DronesMap :drones="drones" :missions="misiones" />
      </div>
    </section>
  </div>
</template>

<script setup>
import { onMounted, onBeforeUnmount, ref } from 'vue'
import { useAuthStore } from '../stores/auth'
import api from '../api/axios'
import DronesMap from '../components/DronesMap.vue' // requiere el componente de mapa

const auth = useAuthStore()
const drones = ref([])
const misiones = ref([])
let pollTimer = null
const POLL_MS = 5000

const fmt = (v) => (typeof v === 'number' ? v.toFixed(6) : '')

const loadDrones = async () => {
  const { data } = await api.get('/drones')
  drones.value = data
}
const loadMisiones = async () => {
  const { data } = await api.get('/misiones')
  misiones.value = data
}

const completar = async (id) => {
  await api.post(`/misiones/${id}/completar`, {})
  await Promise.all([loadMisiones(), loadDrones()])
}
const fallar = async (id) => {
  const motivo = prompt('Motivo de la falla (opcional):') || null
  await api.post(`/misiones/${id}/fallar`, { motivo })
  await Promise.all([loadMisiones(), loadDrones()])
}

const logout = () => auth.logout()

onMounted(async () => {
  await Promise.all([loadDrones(), loadMisiones()])
  // “Tiempo real” simple con polling
  pollTimer = setInterval(() => {
    loadDrones()
    loadMisiones()
  }, POLL_MS)
})

onBeforeUnmount(() => {
  if (pollTimer) clearInterval(pollTimer)
})
</script>

<style>
.page { padding: 1.5rem; }
header { display:flex; align-items:center; justify-content:space-between; margin-bottom: 1rem; }
.grid { display:grid; grid-template-columns: 1fr 1fr; gap: 1rem; }
.card { background:#fff; border:1px solid #ddd; border-radius: 10px; padding: 1rem; }
.map { grid-column: 1 / -1; }
table { width: 100%; border-collapse: collapse; margin-top: .5rem; }
th, td { border: 1px solid #eee; padding: .4rem; text-align: left; }
.actions button { margin-right: .25rem; }

/* Leaflet dentro de la tarjeta */
.map #map, .map .leaflet-container { min-height: 380px; width: 100%; }
</style>
