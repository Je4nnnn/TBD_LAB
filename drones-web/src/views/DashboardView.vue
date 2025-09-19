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
              <td>{{ (d.ultima_lat ?? '').toFixed?.(6) }}</td>
              <td>{{ (d.ultima_lon ?? '').toFixed?.(6) }}</td>
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
        <h3>Mapa (placeholder)</h3>
        <div id="map" style="height: 380px; background:#eef; border:1px dashed #99c;
             display:flex; align-items:center; justify-content:center;">
          Aquí va el mapa (Leaflet/MapLibre/Google)
        </div>
      </div>
    </section>
  </div>
</template>

<script setup>
import { onMounted, ref } from 'vue'
import { useAuthStore } from '../stores/auth'
import api from '../api/axios'

const auth = useAuthStore()
const drones = ref([])
const misiones = ref([])

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
  await loadMisiones()
}
const fallar = async (id) => {
  const motivo = prompt('Motivo de la falla (opcional):') || null
  await api.post(`/misiones/${id}/fallar`, { motivo })
  await loadMisiones()
}

const logout = () => auth.logout()

onMounted(() => {
  loadDrones()
  loadMisiones()
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
</style>
