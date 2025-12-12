<template>
  <div class="page">
    <header>
      <h2>Reportes SQL Avanzados</h2>
      <div class="actions">
        <router-link class="btn" to="/reportes">Reporte Resumen</router-link>
        <router-link class="btn" to="/">Volver al Inicio</router-link>
      </div>
    </header>

    <div class="grid-layout">

      <!-- 1. Horas de Vuelo -->
      <div class="card">
        <h3>1. Horas Totales (Último Mes)</h3>
        <table class="compact">
          <thead><tr><th>Modelo</th><th>Horas</th></tr></thead>
          <tbody>
            <tr v-for="i in data.horas" :key="i.modelo">
              <td>{{ i.modelo }}</td>
              <td>{{ i.horas_totales }} h</td>
            </tr>
          </tbody>
        </table>
      </div>

      <!-- 2. Fallas Recurrentes -->
      <div class="card">
        <h3>2. Top Fallas Recurrentes</h3>
        <table class="compact">
          <thead><tr><th>Dron ID</th><th>Modelo</th><th>Fallas</th></tr></thead>
          <tbody>
            <tr v-for="i in data.fallas" :key="i.dron_id">
              <td><small>{{ i.dron_id }}</small></td>
              <td>{{ i.modelo }}</td>
              <td class="red">{{ i.fallas }}</td>
            </tr>
          </tbody>
        </table>
      </div>

      <!-- 3. Comparación Modelos -->
      <div class="card full-width">
        <h3>3. Comparación Tipos de Misión (Top 2 Modelos)</h3>
        <table class="compact">
          <thead>
            <tr>
              <th>Tipo Misión</th>
              <th v-if="data.comparacion.length">{{ data.comparacion[0].modelo_a_name }}</th>
              <th v-if="data.comparacion.length">{{ data.comparacion[0].modelo_b_name }}</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="i in data.comparacion" :key="i.tipo">
              <td>{{ i.tipo }}</td>
              <td>{{ i.modelo_a_count }}</td>
              <td>{{ i.modelo_b_count }}</td>
            </tr>
          </tbody>
        </table>
      </div>

      <!-- 4. Eficiencia Batería -->
      <div class="card">
        <h3>4. Anomalías Batería (Largas y bajo consumo)</h3>
        <ul>
          <li v-for="i in data.bateria" :key="i.id">
            <b>{{ i.tipo }}</b>: {{ i.dur_min }} min, solo {{ i.consumo_pct }}% bat.
          </li>
        </ul>
      </div>

      <!-- 8. Inactivos -->
      <div class="card">
        <h3>8. Drones Inactivos (>30 días)</h3>
        <div v-if="data.inactivos.length === 0" class="good">No hay drones inactivos</div>
        <ul v-else>
          <li v-for="i in data.inactivos" :key="i.id">
            {{ i.modelo }} ({{ i.estado }}) - Última: {{ formatDate(i.ultima_mision) }}
          </li>
        </ul>
      </div>

      <!-- 9. Cerca POI -->
      <div class="card">
        <h3>9. Cercanía a POI (-70.66, -33.45)</h3>
        <table class="compact">
          <thead><tr><th>Dron</th><th>Distancia</th></tr></thead>
          <tbody>
            <tr v-for="i in data.poi" :key="i.dron_id">
              <td>{{ i.modelo }}</td>
              <td>{{ i.distancia_min_m }} m</td>
            </tr>
          </tbody>
        </table>
      </div>

      <!-- 5. Promedio Mensual -->
      <div class="card full-width">
        <h3>5. Desempeño Semanal (Histórico)</h3>
        <div class="scroll-x">
          <table class="compact">
            <thead><tr><th>Mes</th><th>Total Misiones</th><th>Prom. Semanal</th><th>Variación</th></tr></thead>
            <tbody>
              <tr v-for="i in data.mensual" :key="i.mes">
                <td>{{ formatMonth(i.mes) }}</td>
                <td>{{ i.completas }}</td>
                <td>{{ i.prom_semanal }}</td>
                <td :class="i.delta_vs_mes_ant >= 0 ? 'green' : 'red'">
                  {{ i.delta_vs_mes_ant }}
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

      <!-- 7. Mantenimiento Masivo -->
      <div class="card danger-zone">
        <h3>7. Procedimiento: Mantenimiento Masivo</h3>
        <p>Marca drones con >100h de vuelo como 'En Mantenimiento'.</p>
        <div class="input-group">
          <input v-model="modeloMant" placeholder="Modelo (ej: DJI-M380)" />
          <button @click="ejecutarMant">Ejecutar</button>
        </div>
      </div>

      <!-- 10. Referencia -->
      <div class="card info-zone">
        <h3>Referencias</h3>
        <p><b>Pregunta 6:</b> La asignación de misión se realiza en "Nueva Misión" (Procedimiento almacenado <code>asignar_mision_a_dron</code>).</p>
        <p><b>Pregunta 10:</b> Ver "Reporte Resumen" (Vista Materializada).</p>
      </div>

    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue';
import api from '../api/axios';

const data = ref({
  horas: [],
  fallas: [],
  comparacion: [],
  bateria: [],
  mensual: [],
  inactivos: [],
  poi: []
});

const modeloMant = ref('');

const formatDate = (ts) => ts ? new Date(ts).toLocaleDateString() : 'Nunca';
const formatMonth = (ts) => ts ? ts.substring(0, 7) : '-';

const loadAll = async () => {
  const [r1, r2, r3, r4, r5, r8, r9] = await Promise.all([
    api.get('/reportes/horas-vuelo'),
    api.get('/reportes/fallas-recurrentes'),
    api.get('/reportes/comparacion-modelos'),
    api.get('/reportes/eficiencia-bateria'),
    api.get('/reportes/promedio-mensual'),
    api.get('/reportes/inactivos'),
    api.get('/reportes/cerca-poi')
  ]);

  data.value.horas = r1.data;
  data.value.fallas = r2.data;
  data.value.comparacion = r3.data;
  data.value.bateria = r4.data;
  data.value.mensual = r5.data;
  data.value.inactivos = r8.data;
  data.value.poi = r9.data;
};

const ejecutarMant = async () => {
  if(!modeloMant.value) return alert("Ingrese un modelo");
  if(!confirm("¿Seguro que desea cambiar estado a 'En Mantenimiento' para todos los " + modeloMant.value + " que superen 100h?")) return;

  try {
    const res = await api.post('/reportes/mantenimiento', { modelo: modeloMant.value });
    alert(res.data.mensaje);
  } catch(e) {
    alert("Error ejecutando procedimiento");
  }
};

onMounted(loadAll);
</script>

<style scoped>
.page { padding: 1.5rem; max-width: 1200px; margin: 0 auto; }
header { display:flex; justify-content:space-between; align-items:center; margin-bottom: 2rem; }
.actions { display:flex; gap:10px; }
.grid-layout { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 1.5rem; }
.card { background: #1e1e1e; border: 1px solid #333; padding: 1rem; border-radius: 8px; color: #ddd; }
.card h3 { margin-top: 0; color: #646cff; font-size: 1.1rem; border-bottom: 1px solid #444; padding-bottom: 0.5rem; }
.full-width { grid-column: 1 / -1; }
.compact { width: 100%; font-size: 0.9rem; border-collapse: collapse; }
.compact th, .compact td { padding: 6px; border-bottom: 1px solid #333; text-align: left; }
.red { color: #f87171; font-weight: bold; }
.green { color: #4ade80; font-weight: bold; }
.good { color: #4ade80; padding: 10px; font-style: italic; }
.danger-zone { border-color: #7f1d1d; background: #2a0f0f; }
.info-zone { background: #111827; border: 1px dashed #4b5563; }
.input-group { display: flex; gap: 8px; margin-top: 10px; }
.scroll-x { overflow-x: auto; }
</style>