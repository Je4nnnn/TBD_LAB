<template>
  <div class="page">
    <header class="hdr">
      <h2>Flota de Drones</h2>

      <div class="hdr-actions">
        <router-link to="/reportes" class="btn outline">Reportes</router-link>
        <span class="user">
          <strong>{{ auth.nombre }}</strong> ({{ auth.rol }})
        </span>
        <button class="btn" @click="logout">Salir</button>
      </div>
    </header>

    <section class="grid">
      <!-- DRONES -->
      <div class="card">
        <div class="card-hdr">
          <h3>Drones</h3>
          <button class="btn sm" @click="loadDrones">Refrescar</button>
        </div>

        <table v-if="drones.length" class="tbl">
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
              <td>{{ fmtCoord(d.ultima_lat) }}</td>
              <td>{{ fmtCoord(d.ultima_lon) }}</td>
            </tr>
          </tbody>
        </table>
        <p v-else class="muted">Cargando…</p>
      </div>

      <!-- MISIONES -->
      <div class="card">
        <div class="card-hdr">
          <h3>Misiones</h3>
          <button class="btn sm" @click="loadMisiones">Refrescar</button>
        </div>

        <table v-if="misiones.length" class="tbl">
          <thead>
            <tr>
              <th>Tipo</th>
              <th>Estado</th>
              <th>Dron</th>
              <th class="actions-th">Acciones</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="m in misiones" :key="m.id">
              <td>{{ m.tipo }}</td>
              <td>{{ m.estado }}</td>
              <td>{{ m.dron_modelo || '-' }}</td>
              <td class="actions">
                <button class="btn xs" @click="completar(m.id)">Completar</button>
                <button class="btn xs outline" @click="fallar(m.id)">Fallar</button>
              </td>
            </tr>
          </tbody>
        </table>
        <p v-else class="muted">Cargando…</p>
      </div>

      <!-- MAPA -->
      <div class="card map">
        <h3>Mapa</h3>
        <DronesMap class="mapbox" :drones="drones" :misiones="misiones" />
      </div>
    </section>
  </div>
</template>

<script setup>
import { onMounted, onUnmounted, ref } from 'vue'
import { useAuthStore } from '../stores/auth'
import api from '../api/axios'
import DronesMap from '../components/DronesMap.vue'

const auth = useAuthStore()
const drones = ref([])
const misiones = ref([])
let poll = null

const fmtCoord = (v) => {
  if (v === null || v === undefined) return ''
  const n = Number(v)
  return Number.isFinite(n) ? n.toFixed(6) : ''
}

async function loadDrones() {
  const { data } = await api.get('/drones')
  drones.value = Array.isArray(data) ? data : []
}

async function loadMisiones() {
  const { data } = await api.get('/misiones')
  misiones.value = Array.isArray(data) ? data : []
}

async function completar(id) {
  await api.post(`/misiones/${id}/completar`, {})
  await loadMisiones()
  await loadDrones()
}

async function fallar(id) {
  const motivo = prompt('Motivo de la falla (opcional):') || null
  await api.post(`/misiones/${id}/fallar`, { motivo })
  await loadMisiones()
  await loadDrones()
}

function logout() {
  auth.logout()
}

// carga inicial + polling liviano para “tiempo real”
onMounted(async () => {
  await Promise.all([loadDrones(), loadMisiones()])
  poll = setInterval(() => {
    loadDrones()
    loadMisiones()
  }, 10000) // 10s
})
onUnmounted(() => poll && clearInterval(poll))
</script>

<style scoped>
.page { padding: 1.5rem; }
.hdr { display:flex; align-items:center; justify-content:space-between; margin-bottom: 1rem; }
.hdr-actions { display:flex; align-items:center; gap:.5rem; }
.user { color:#444; }

.grid { display:grid; grid-template-columns: 1fr 1fr; gap: 1rem; }
.card { background:#fff; border:1px solid #ddd; border-radius: 10px; padding: 1rem; }
.card-hdr { display:flex; align-items:center; justify-content:space-between; margin-bottom:.5rem; }

.tbl { width: 100%; border-collapse: collapse; }
.tbl th, .tbl td { border: 1px solid #eee; padding: .45rem .5rem; text-align: left; }
.actions-th { width: 160px; }
.actions { display:flex; gap:.35rem; }

.map { grid-column: 1 / -1; }
.mapbox { height: 420px; margin-top:.5rem; border:1px solid #e5e7eb; border-radius:8px; overflow:hidden; }

.muted { color:#666; }

/* Botones */
.btn { padding:.45rem .75rem; border-radius:8px; border:1px solid #ddd; background:#0f62fe; color:#fff; cursor:pointer; }
.btn:hover { filter:brightness(.95); }
.btn:disabled { opacity:.6; cursor:not-allowed; }
.btn.outline { background:#fff; color:#333; }
.btn.sm { padding:.3rem .55rem; font-size:.9rem; }
.btn.xs { padding:.22rem .45rem; font-size:.85rem; }
</style>
