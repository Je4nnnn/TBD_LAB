<template>
  <div class="page">
    <header>
      <h2>Crear Nueva Misión</h2>
      <router-link class="btn" to="/">Cancelar</router-link>
    </header>

    <div class="form-container">
      <div class="card">

        <!-- SECCIÓN 1: DATOS BÁSICOS -->
        <div class="form-group">
          <label>Tipo de Misión</label>
          <select v-model="tipo">
            <option>Inspección</option>
            <option>Entrega</option>
            <option>Vigilancia</option>
          </select>
        </div>

        <div class="form-group">
          <label>Asignar Dron (Opcional)</label>
          <select v-model="dronId">
            <option :value="null">-- Dejar Pendiente --</option>
            <option v-for="d in dronesDisponibles" :key="d.id" :value="d.id">
              {{ d.modelo }} (Bat: {{ d.bateria_pct }}% - {{ d.estado }})
            </option>
          </select>
        </div>

        <!-- SECCIÓN 2: MAPA INTERACTIVO -->
        <div class="map-section">
          <label>Planificar Ruta</label>

          <!-- Buscador de Direcciones -->
          <div class="search-box">
            <input
              v-model="direccionBusqueda"
              @keyup.enter="buscarDireccion"
              placeholder="Escribe una dirección (ej: Plaza de Armas, Santiago)"
            />
            <button @click="buscarDireccion" class="btn-small" :disabled="buscando">
              {{ buscando ? '...' : '🔍 Buscar' }}
            </button>
            <button @click="limpiarRuta" class="btn-small btn-red">Borrar Ruta</button>
          </div>

          <div id="map-select" class="map-container"></div>
          <small class="hint">Haz clic en el mapa para añadir puntos o usa el buscador.</small>
        </div>

        <!-- SECCIÓN 3: JSON RESULTANTE (SOLO LECTURA) -->
        <div class="form-group">
          <label>Ruta Generada (JSON)</label>
          <textarea v-model="rutaJson" rows="3" readonly class="readonly-area"></textarea>
        </div>

        <p v-if="error" class="error-msg">{{ error }}</p>

        <button class="btn-primary" @click="guardar" :disabled="loading || waypoints.length === 0">
          {{ loading ? 'Guardando...' : 'Crear Misión' }}
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, watch } from 'vue';
import { useRouter } from 'vue-router';
import api from '../api/axios';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';

// Configuración de Iconos de Leaflet (Fix estándar de Vue/Vite)
import markerIcon from 'leaflet/dist/images/marker-icon.png';
import markerIconRetina from 'leaflet/dist/images/marker-icon-2x.png';
import markerShadow from 'leaflet/dist/images/marker-shadow.png';

const DefaultIcon = L.icon({
  iconUrl: markerIcon,
  iconRetinaUrl: markerIconRetina,
  shadowUrl: markerShadow,
  iconSize: [25, 41],
  iconAnchor: [12, 41],
  popupAnchor: [1, -34],
  shadowSize: [41, 41]
});
L.Marker.prototype.options.icon = DefaultIcon;

// --- ESTADO ---
const router = useRouter();
const loading = ref(false);
const error = ref('');
const dronesDisponibles = ref([]);

const tipo = ref('Entrega');
const dronId = ref(null);
const waypoints = ref([]); // Array de arrays [[lat, lon], ...]
const rutaJson = ref('{"waypoints": []}');

// Mapa y Buscador
let map = null;
let markersLayer = null;
let routeLine = null;
const direccionBusqueda = ref('');
const buscando = ref(false);

// --- CARGA INICIAL ---
onMounted(async () => {
  // 1. Cargar Drones
  try {
    const { data } = await api.get('/drones');
    dronesDisponibles.value = data.filter(d => d.estado === 'Disponible');
  } catch (e) { console.error(e); }

  // 2. Inicializar Mapa
  initMap();
});

// --- LÓGICA DEL MAPA ---
function initMap() {
  // Centro inicial (Santiago)
  map = L.map('map-select').setView([-33.4489, -70.6693], 13);

  L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
    maxZoom: 19,
    attribution: '© OpenStreetMap'
  }).addTo(map);

  markersLayer = L.layerGroup().addTo(map);

  // Evento Clic en Mapa
  map.on('click', (e) => {
    agregarPunto(e.latlng.lat, e.latlng.lng);
  });
}

function agregarPunto(lat, lon) {
  // Guardar en el array reactivo
  waypoints.value.push([lat, lon]);

  // Dibujar marcador
  const marker = L.marker([lat, lon]).addTo(markersLayer);
  marker.bindPopup(`Punto ${waypoints.value.length}`).openPopup();

  // Dibujar/Actualizar línea
  actualizarLinea();

  // Actualizar el JSON string
  actualizarJSON();
}

function actualizarLinea() {
  if (routeLine) map.removeLayer(routeLine);
  if (waypoints.value.length > 1) {
    routeLine = L.polyline(waypoints.value, { color: 'blue', weight: 4 }).addTo(map);
  }
}

function actualizarJSON() {
  const obj = { waypoints: waypoints.value };
  rutaJson.value = JSON.stringify(obj, null, 2);
}

function limpiarRuta() {
  waypoints.value = [];
  markersLayer.clearLayers();
  if (routeLine) map.removeLayer(routeLine);
  actualizarJSON();
}

// --- BUSCADOR DE DIRECCIONES (Nominatim API) ---
async function buscarDireccion() {
  if (!direccionBusqueda.value) return;
  buscando.value = true;

  try {
    // Usamos fetch nativo para llamar a OpenStreetMap
    const url = `https://nominatim.openstreetmap.org/search?format=json&q=${encodeURIComponent(direccionBusqueda.value)}`;
    const res = await fetch(url);
    const data = await res.json();

    if (data && data.length > 0) {
      const lat = parseFloat(data[0].lat);
      const lon = parseFloat(data[0].lon);

      // Mover mapa y agregar punto
      map.setView([lat, lon], 16);
      agregarPunto(lat, lon);
      direccionBusqueda.value = ''; // Limpiar input
    } else {
      alert("Dirección no encontrada");
    }
  } catch (e) {
    console.error(e);
    alert("Error al buscar dirección");
  } finally {
    buscando.value = false;
  }
}

// --- GUARDAR MISIÓN ---
const guardar = async () => {
  if (waypoints.value.length === 0) {
    error.value = "Debes seleccionar al menos un punto en el mapa.";
    return;
  }

  loading.value = true;
  error.value = '';

  try {
    const res = await api.post('/misiones', {
      tipo: tipo.value,
      ruta_json: rutaJson.value
    });

    const nuevaMisionId = res.data.id;

    if (dronId.value) {
      await api.post(`/misiones/${nuevaMisionId}/asignar/${dronId.value}`);
    }

    router.push('/');
  } catch (e) {
    console.error(e);
    error.value = 'Error al crear la misión.';
  } finally {
    loading.value = false;
  }
};
</script>

<style scoped>
.form-container { max-width: 800px; margin: 0 auto; } /* Hacemos el container más ancho para el mapa */
.form-group { margin-bottom: 1.2rem; text-align: left; }
.map-section { margin-bottom: 1.5rem; text-align: left; }

label { display: block; font-weight: 600; margin-bottom: 0.5rem; }
select, textarea, input {
  width: 100%; padding: 0.75rem; border-radius: 6px;
  border: 1px solid #ccc; background: #fff; color: #333;
}

/* Estilos del Mapa y Buscador */
.map-container {
  height: 400px;
  width: 100%;
  border: 2px solid #ddd;
  border-radius: 8px;
  margin-top: 10px;
  cursor: crosshair; /* Cursor de mira para indicar que se puede cliquear */
}

.search-box {
  display: flex;
  gap: 8px;
  margin-bottom: 8px;
}

.readonly-area {
  background-color: #f3f4f6;
  color: #666;
  font-family: monospace;
  font-size: 0.85rem;
}

/* Botones */
.btn-primary {
  background-color: #2563eb; color: white; border: none;
  padding: 12px 24px; font-size: 1rem; width: 100%;
  border-radius: 6px; cursor: pointer; font-weight: bold;
}
.btn-primary:disabled { background-color: #93c5fd; cursor: not-allowed; }

.btn-small {
  padding: 0 16px;
  border-radius: 6px;
  border: 1px solid #ccc;
  cursor: pointer;
  background: #eee;
  font-weight: 600;
  color: #333;
}
.btn-red {
  background: #fee2e2;
  color: #dc2626;
  border-color: #fecaca;
}

.hint { color: #666; font-style: italic; display: block; margin-top: 5px; }
.error-msg { color: #dc2626; margin-bottom: 1rem; font-weight: bold; }
</style>