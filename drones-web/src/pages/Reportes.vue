<script setup>
import { ref, onMounted } from 'vue'
import http from '../lib/http' // ← usamos SIEMPRE este cliente

const filas = ref([])
const error = ref('')

async function cargarResumen() {
  error.value = ''
  try {
    // Endpoint correcto del backend: GET /reportes/resumen
    const { data } = await http.get('/reportes/resumen')
    filas.value = data
  } catch (e) {
    error.value = 'No se pudo cargar el reporte'
    console.error(e)
  }
}

async function refrescarMV() {
  try {
    await http.post('/reportes/resumen/refresh')
    await cargarResumen()
  } catch (e) {
    console.error(e)
  }
}

onMounted(cargarResumen)
</script>

<template>
  <div>
    <h2>Reportes</h2>
    <p v-if="error" style="color:#c00">{{ error }}</p>

    <div style="margin: 8px 0">
      <button @click="refrescarMV">Refrescar materialized view</button>
      <button @click="cargarResumen" style="margin-left:8px">Recargar</button>
    </div>

    <table v-if="filas.length" border="1" cellpadding="6">
      <thead>
        <tr>
          <th>Tipo</th>
          <th>Total</th>
          <th>Horas promedio</th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="r in filas" :key="r.tipo">
          <td>{{ r.tipo }}</td>
          <td>{{ r.total }}</td>
          <td>{{ (r.horas_promedio ?? r.horasPromedio ?? 0).toFixed(2) }}</td>
        </tr>
      </tbody>
    </table>

    <p v-else style="color:#555">No hay datos en el resumen.</p>
  </div>
</template>