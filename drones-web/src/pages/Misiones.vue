<!-- src/pages/Misiones.vue -->
<script setup>
import { ref, onMounted } from 'vue';
import { Misiones, Drones, Telemetria } from '../api';

const cargando = ref(false);
const error = ref('');
const misiones = ref([]);
const drones = ref([]);

const form = ref({
  tipo: 'Inspección',
  ruta_planeada: JSON.stringify({ waypoints: [[-33.45, -70.66], [-33.44, -70.65]] }, null, 2),
});

async function cargar() {
  cargando.value = true;
  error.value = '';
  try {
    const [ms, ds] = await Promise.all([Misiones.list(), Drones.list()]);
    misiones.value = ms;
    drones.value = ds;
  } catch (e) {
    error.value = e?.response?.data?.message || e.message || 'Error al cargar';
  } finally {
    cargando.value = false;
  }
}

async function crearMision() {
  error.value = '';
  try {
    const body = {
      tipo: form.value.tipo,
      ruta_planeada: JSON.parse(form.value.ruta_planeada), // backend espera JSON
    };
    const creada = await Misiones.create(body);
    misiones.value.unshift(creada);
  } catch (e) {
    error.value = e?.response?.data?.message || e.message;
  }
}

async function asignar(m) {
  error.value = '';
  try {
    // elige un dron disponible (o el primero)
    const candidato = drones.value.find(d => d.estado === 'Disponible') || drones.value[0];
    if (!candidato) throw new Error('No hay drones para asignar');
    await Misiones.assign(m.id, candidato.id);
    await cargar();
  } catch (e) {
    error.value = e?.response?.data?.message || e.message;
  }
}

async function completar(m) {
  error.value = '';
  try {
    await Misiones.completar(m.id);
    await cargar();
  } catch (e) {
    error.value = e?.response?.data?.message || e.message;
  }
}

// Enviar 3 puntos de telemetría de ejemplo
async function enviarTelemetriaDemo(m) {
  error.value = '';
  try {
    const pts = [
      { lat: -33.45, lon: -70.66, bateria: 98 },
      { lat: -33.449, lon: -70.659, bateria: 96 },
      { lat: -33.448, lon: -70.658, bateria: 95 },
    ];
    for (const p of pts) {
      await Telemetria.enviar(m.id, p.lat, p.lon, p.bateria);
    }
    alert('Telemetría enviada (demo)');
  } catch (e) {
    error.value = e?.response?.data?.message || e.message;
  }
}

onMounted(cargar);
</script>

<template>
  <div class="space-y-6">
    <h1 class="text-2xl font-semibold">Misiones</h1>

    <div class="grid md:grid-cols-2 gap-6">
      <!-- Crear misión -->
      <div class="rounded-xl border border-white/10 p-4 bg-white/5">
        <h2 class="font-medium mb-3">Crear misión</h2>

        <label class="block text-sm mb-1">Tipo</label>
        <select v-model="form.tipo" class="w-full rounded bg-white/10 p-2 mb-3">
          <option>Inspección</option>
          <option>Entrega</option>
          <option>Vigilancia</option>
        </select>

        <label class="block text-sm mb-1">Ruta planeada (JSON)</label>
        <textarea
          v-model="form.ruta_planeada"
          rows="8"
          class="w-full rounded bg-white/10 p-2 font-mono text-sm"
        ></textarea>

        <button @click="crearMision" class="mt-3 rounded bg-blue-600 px-4 py-2 hover:bg-blue-500">
          Crear
        </button>
      </div>

      <!-- Lista -->
      <div class="rounded-xl border border-white/10 p-4 bg-white/5">
        <div class="flex items-center justify-between mb-3">
          <h2 class="font-medium">Listado</h2>
          <button @click="cargar" class="rounded bg-white/10 px-3 py-1 hover:bg-white/20">Refrescar</button>
        </div>

        <p v-if="cargando" class="text-sm opacity-70">Cargando…</p>
        <p v-if="error" class="text-sm text-red-400">{{ error }}</p>

        <div v-for="m in misiones" :key="m.id" class="mb-3 rounded bg-white/5 p-3">
          <div class="flex items-center justify-between">
            <div>
              <div class="font-semibold">{{ m.tipo }}</div>
              <div class="text-xs opacity-70">estado: {{ m.estado }}</div>
            </div>
            <div class="flex gap-2">
              <button @click="asignar(m)" class="rounded bg-white/10 px-3 py-1 hover:bg-white/20">Asignar</button>
              <button @click="enviarTelemetriaDemo(m)" class="rounded bg-white/10 px-3 py-1 hover:bg-white/20">Telemetría</button>
              <button @click="completar(m)" class="rounded bg-green-600 px-3 py-1 hover:bg-green-500">Completar</button>
            </div>
          </div>
        </div>

        <p v-if="!cargando && misiones.length === 0" class="text-sm opacity-70">Sin misiones aún.</p>
      </div>
    </div>
  </div>
</template>
