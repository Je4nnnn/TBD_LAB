<template>
  <div class="map-wrap">
    <div ref="mapEl" class="leaflet-map"></div>

    <!-- Leyenda simple -->
    <div class="legend">
      <div><span class="dot blue"></span> Disponible</div>
      <div><span class="dot orange"></span> En Vuelo</div>
      <div><span class="dot gray"></span> En Mantenimiento</div>
      <div class="sep"></div>
      <div><span class="line green"></span> Misión Completada</div>
      <div><span class="line blue"></span> Misión En Progreso</div>
      <div><span class="line gray dotted"></span> Misión Pendiente</div>
      <div><span class="line red"></span> Misión Fallida</div>
    </div>
  </div>
</template>

<script setup>
import { onMounted, onBeforeUnmount, ref, watch } from 'vue'
import L from 'leaflet'
import 'leaflet/dist/leaflet.css'

const props = defineProps({
  drones: { type: Array, default: () => [] },
  missions: { type: Array, default: () => [] },
})

const mapEl = ref(null)
let map
let markerLayer
let routeLayer

// Utilidades
const isNum = (v) => typeof v === 'number' && Number.isFinite(v)
const getLatLon = (d) => {
  // backend expone ultima_lat / ultima_lon; si no, intentar lat/lon
  const lat = isNum(d.ultima_lat) ? d.ultima_lat : d.lat
  const lon = isNum(d.ultima_lon) ? d.ultima_lon : d.lon
  return (isNum(lat) && isNum(lon)) ? [lat, lon] : null
}

function parseWaypoints(rutaPlaneada) {
  // Aceptar:
  // 1) {waypoints:[[lat,lon],...]}
  // 2) '{"waypoints":[[lat,lon],...]}'
  // 3) {type:'jsonb', value:'{"waypoints":[...]}'}
  try {
    if (!rutaPlaneada) return null
    let obj = rutaPlaneada
    if (typeof rutaPlaneada === 'string') obj = JSON.parse(rutaPlaneada)
    else if (rutaPlaneada && typeof rutaPlaneada.value === 'string') obj = JSON.parse(rutaPlaneada.value)
    if (obj && Array.isArray(obj.waypoints) && obj.waypoints.length) {
      // validar números
      const pts = obj.waypoints
        .map((p) => Array.isArray(p) && p.length >= 2 ? [Number(p[0]), Number(p[1])] : null)
        .filter((p) => p && isNum(p[0]) && isNum(p[1]))
      return pts.length ? pts : null
    }
  } catch (e) {
    // ignorar parse errors
  }
  return null
}

function iconByState(estado) {
  const color = estado === 'En Vuelo' ? '#f59e0b'   // orange
              : estado === 'En Mantenimiento' ? '#6b7280' // gray
              : '#2563eb' // azul por defecto (Disponible u otros)
  return L.divIcon({
    className: 'marker-dot',
    html: `<span style="
      display:inline-block;width:14px;height:14px;border-radius:50%;
      background:${color};border:2px solid #fff;box-shadow:0 0 2px rgba(0,0,0,.6);
      "></span>`,
    iconSize: [14, 14],
    iconAnchor: [7, 7],
    popupAnchor: [0, -8],
  })
}

function styleByMissionState(estado) {
  if (estado === 'Completada') return { color: '#2e7d32', weight: 3 }           // green
  if (estado === 'En Progreso') return { color: '#2563eb', weight: 3 }          // blue
  if (estado === 'Fallida')     return { color: '#dc2626', weight: 3 }          // red
  return { color: '#6b7280', weight: 2, dashArray: '6,6' }                      // Pendiente/otros
}

function updateMap() {
  if (!map) return
  markerLayer.clearLayers()
  routeLayer.clearLayers()

  const bounds = []

  // Drones -> marcadores
  for (const d of props.drones || []) {
    const pos = getLatLon(d)
    if (!pos) continue
    const marker = L.marker(pos, { icon: iconByState(d.estado) })
      .bindPopup(`<b>${d.modelo}</b><br/>Estado: ${d.estado}<br/>Batería: ${d.bateria_pct ?? '-'}%`)
    marker.addTo(markerLayer)
    bounds.push(marker.getLatLng())
  }

  // Misiones -> rutas
  for (const m of props.missions || []) {
    const wps = parseWaypoints(m.ruta_planeada)
    if (!wps) continue
    const poly = L.polyline(wps, styleByMissionState(m.estado)).addTo(routeLayer)
    poly.bindPopup(`<b>${m.tipo}</b><br/>Estado: ${m.estado}${m.dron_modelo ? `<br/>Dron: ${m.dron_modelo}` : ''}`)
    // acumular bounds
    for (const p of poly.getLatLngs()) bounds.push(p)
  }

  // Ajustar vista si hay algo que mostrar
  if (bounds.length) {
    map.fitBounds(L.latLngBounds(bounds), { padding: [20, 20] })
  }
}

onMounted(() => {
  map = L.map(mapEl.value, {
    zoomControl: true,
  })
  const osm = L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
    maxZoom: 19,
    attribution: '&copy; OpenStreetMap contributors',
  })
  osm.addTo(map)

  markerLayer = L.layerGroup().addTo(map)
  routeLayer  = L.layerGroup().addTo(map)

  // vista inicial (Santiago aprox.) mientras llegan datos
  map.setView([-33.45, -70.66], 12)

  updateMap()
})

// Actualizar en cambios (incluye cambios profundos)
watch(() => props.drones, updateMap, { deep: true })
watch(() => props.missions, updateMap, { deep: true })

onBeforeUnmount(() => {
  if (map) map.remove()
})
</script>

<style scoped>
.map-wrap {
  position: relative;
}
.leaflet-map {
  width: 100%;
  min-height: 380px; /* el Dashboard también define altura; esto asegura standalone */
  border: 1px solid #dfe3e6;
  border-radius: 8px;
}

/* Leyenda */
.legend {
  position: absolute;
  right: 10px;
  bottom: 10px;
  background: rgba(255,255,255,.95);
  padding: 8px 10px;
  border: 1px solid #e5e7eb;
  border-radius: 6px;
  font-size: 12px;
  line-height: 1.2;
  box-shadow: 0 2px 6px rgba(0,0,0,.1);
}
.legend .sep { height: 6px; }
.legend .dot {
  display:inline-block; width:10px; height:10px; border-radius:50%; margin-right:6px;
  border:1px solid #fff; box-shadow:0 0 1px rgba(0,0,0,.5);
  vertical-align: -1px;
}
.legend .dot.blue   { background:#2563eb; }
.legend .dot.orange { background:#f59e0b; }
.legend .dot.gray   { background:#6b7280; }

.legend .line {
  display:inline-block; width:18px; height:0; border-top:3px solid; margin-right:6px;
  vertical-align: middle;
}
.legend .line.green  { border-color:#2e7d32; }
.legend .line.blue   { border-color:#2563eb; }
.legend .line.red    { border-color:#dc2626; }
.legend .line.gray   { border-color:#6b7280; }
.legend .line.dotted { border-top-style: dotted; }
</style>
