<script setup>
import { ref, onMounted } from 'vue'
import http from '../lib/http' // ← usamos SIEMPRE este cliente

const tipo = ref('Inspección')
const rutaPlaneada = ref(`{
  "waypoints": [
    { "lat": -33.45, "lon": -70.66 },
    { "lat": -33.44, "lon": -70.65 }
  ]
}`)
const misiones = ref([])
const error = ref('')

async function cargarMisiones() {
  error.value = ''
  try {
    const { data } = await http.get('/misiones')
    misiones.value = data
  } catch (e) {
    error.value = 'No se pudo listar misiones'
    console.error(e)
  }
}

async function crearMision() {
  error.value = ''
  try {
    const body = {
      tipo: tipo.value,
      ruta_planeada: rutaPlaneada.value
    }
    await http.post('/misiones', body)
    await cargarMisiones()
  } catch (e) {
    error.value = 'No se pudo crear la misión'
    console.error(e)
  }
}

onMounted(cargarMisiones)
</script>

<template>
  <div>
    <h2>Misiones</h2>

    <div style="border:1px solid #ccc; padding:12px; border-radius:6px; max-width:600px">
      <label>Tipo&nbsp;</label>
      <select v-model="tipo">
        <option>Inspección</option>
        <option>Entrega</option>
        <option>Vigilancia</option>
      </select>

      <div style="margin-top:8px">
        <label>Ruta planeada (JSON)</label>
        <textarea v-model="rutaPlaneada" rows="8" style="width:100%"></textarea>
      </div>

      <button @click="crearMision" style="margin-top:8px">Crear</button>
    </div>

    <div style="margin-top:16px">
      <h4>Listado</h4>
      <p v-if="error" style="color:#c00">{{ error }}</p>
      <button @click="cargarMisiones">Refrescar</button>

      <ul v-if="misiones.length" style="margin-top:8px">
        <li v-for="m in misiones" :key="m.id">
          <strong>{{ m.tipo }}</strong> — {{ m.estado }}
          <span v-if="m.dron_modelo"> ({{ m.dron_modelo }})</span>
        </li>
      </ul>
      <p v-else style="color:#555">Sin misiones para mostrar.</p>
    </div>
  </div>
</template>
