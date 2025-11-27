
<script setup>
import { ref, onMounted } from 'vue'
import http from '../lib/http' // cliente que ya usas
import { useAuthStore } from '../stores/auth';
import { RouterLink } from 'vue-router';

const auth = useAuthStore();

// ---- CREAR ----
const tipo = ref('Inspección')
const rutaPlaneada = ref(`{
  "waypoints": [
    { "lat": -33.45, "lon": -70.66 },
    { "lat": -33.44, "lon": -70.65 }
  ]
}`)

// ---- LISTADO / ESTADO ----
const misiones = ref([])
const error = ref('')

// ---- EDICIÓN ----
const editando = ref(false)
const idEditando = ref(null)
const form = ref({
  tipo: '',
  ruta_json: ''
})

// ---- DRONES DISPONIBLES PARA ASIGNAR ----
const dronesDisponibles = ref([])
// selección por misión: { [misionId]: dronId }
const seleccionDron = ref({})

// --------------------- CARGA DE DATOS ---------------------

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

async function cargarDronesDisponibles() {
  try {
    const { data } = await http.get('/drones')
    // solo mostramos drones disponibles
    dronesDisponibles.value = data.filter(d => d.estado === 'Disponible')
  } catch (e) {
    console.error(e)
  }
}

// --------------------- CREAR -----------------------------

async function crearMision() {
  error.value = ''
  try {
    const body = {
      tipo: tipo.value,
      // IMPORTANTE: debe llamarse igual que en el DTO (ruta_json)
      ruta_json: rutaPlaneada.value
    }
    await http.post('/misiones', body)
    await cargarMisiones()
  } catch (e) {
    error.value = 'No se pudo crear la misión'
    console.error(e)
  }
}

// --------------------- EDITAR ----------------------------

function iniciarEdicion(m) {
  editando.value = true
  idEditando.value = m.id

  // m.ruta_planeada viene de Postgres como jsonb (objeto o string)
  let rutaJsonString = ''
  if (typeof m.ruta_planeada === 'string') {
    rutaJsonString = m.ruta_planeada
  } else if (m.ruta_planeada != null) {
    rutaJsonString = JSON.stringify(m.ruta_planeada, null, 2)
  }

  form.value = {
    tipo: m.tipo,
    ruta_json: rutaJsonString
  }
}

async function guardarEdicion() {
  error.value = ''
  try {
    await http.put(`/misiones/${idEditando.value}`, {
      tipo: form.value.tipo,
      ruta_json: form.value.ruta_json
    })
    editando.value = false
    idEditando.value = null
    await cargarMisiones()
  } catch (e) {
    error.value = 'No se pudo actualizar la misión'
    console.error(e)
  }
}

function cancelarEdicion() {
  editando.value = false
  idEditando.value = null
}

// --------------------- ELIMINAR --------------------------

async function eliminarMision(id) {
  if (!confirm('¿Seguro que quieres eliminar esta misión?')) return
  try {
    await http.delete(`/misiones/${id}`)
    await cargarMisiones()
  } catch (e) {
    console.error(e)
    const msg = e.response?.data?.message || 'No se pudo eliminar la misión'
    alert(msg)
  }
}

// --------------------- ASIGNAR DRON ----------------------

async function asignarDron(misionId) {
  const dronId = seleccionDron.value[misionId]
  if (!dronId) {
    alert('Selecciona un dron primero')
    return
  }

  try {
    // Endpoint: /misiones/{misionId}/asignar/{dronId}
    await http.post(`/misiones/${misionId}/asignar/${dronId}`)
    await cargarMisiones()
    await cargarDronesDisponibles()
    seleccionDron.value[misionId] = null
  } catch (e) {
    console.error(e)
    const msg = e.response?.data?.message || 'No se pudo asignar el dron'
    alert(msg)
  }
}

onMounted(async () => {
  await cargarMisiones()
  await cargarDronesDisponibles()
})
</script>

<template>
  <div>
    <h2>Misiones</h2>

    <!-- BOTÓN SOLO PARA ADMIN -->
    <div v-if="auth.user.rol === 'ADMIN'"
        style="margin-bottom: 16px; max-width:600px;">

      <RouterLink class="btn btn-accent" 
                  to="/misiones/nueva"
                  style="display:inline-block; padding:10px 16px;
                        background:#2563eb; color:white; border-radius:6px;
                        text-decoration:none; font-weight:bold;">
        + Crear Nueva Misión
      </RouterLink>

    </div>

    <!-- LISTADO -->
    <div style="margin-top:16px">
      <h4>Listado</h4>
      <p v-if="error" style="color:#c00">{{ error }}</p>
      <button @click="cargarMisiones">Refrescar</button>

      <ul v-if="misiones.length" style="margin-top:8px">
        <li
          v-for="m in misiones"
          :key="m.id"
          style="margin-bottom:12px; border-bottom:1px solid #ddd; padding-bottom:8px"
        >
          <div>
            <strong>{{ m.tipo }}</strong> — {{ m.estado }}
            <span v-if="m.dron_modelo"> ({{ m.dron_modelo }})</span>
          </div>

          <!-- Botones CRUD -->
          <div style="margin-top:6px; display:flex; gap:8px; flex-wrap:wrap;">
            <button @click="iniciarEdicion(m)">Editar</button>
            <button style="color:#b00;" @click="eliminarMision(m.id)">Eliminar</button>
          </div>

          <!-- Asignar dron sólo si no tiene -->
          <div v-if="!m.dron_modelo" style="margin-top:6px;">
            <label>Asignar dron:</label>
            <select
              v-model="seleccionDron[m.id]"
              style="min-width:200px; margin-right:8px;"
            >
              <option :value="null" disabled>Selecciona un dron disponible</option>
              <option v-for="d in dronesDisponibles" :key="d.id" :value="d.id">
                {{ d.modelo }} ({{ d.bateria_pct }}%)
              </option>
            </select>
            <button @click="asignarDron(m.id)">Asignar</button>
          </div>
        </li>
      </ul>
      <p v-else style="color:#555">Sin misiones para mostrar.</p>
    </div>

    <!-- EDITAR MISIÓN -->
    <div
      v-if="editando"
      style="border:1px solid #ccc; padding:12px; border-radius:6px; margin-top:16px; max-width:600px"
    >
      <h4>Editar misión</h4>

      <label>Tipo</label>
      <select v-model="form.tipo" style="width:100%; margin-bottom:8px;">
        <option>Inspección</option>
        <option>Entrega</option>
        <option>Vigilancia</option>
      </select>

      <label>Ruta planeada (JSON)</label>
      <textarea
        v-model="form.ruta_json"
        rows="8"
        style="width:100%; margin-bottom:8px;"
      ></textarea>

      <button @click="guardarEdicion">Guardar cambios</button>
      <button style="margin-left:8px;" @click="cancelarEdicion">Cancelar</button>
    </div>
  </div>
</template>
