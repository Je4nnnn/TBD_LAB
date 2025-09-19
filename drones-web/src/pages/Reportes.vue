<!-- src/pages/Reportes.vue -->
<script setup>
import { ref, onMounted } from 'vue';
import { Reportes } from '../api';

const filas = ref([]);
const error = ref('');
const usandoMV = ref(true); // cambia a false si prefieres el “resumen” no materializado

async function cargar() {
  error.value = '';
  try {
    filas.value = usandoMV.value
      ? await Reportes.resumenMV()
      : await Reportes.resumen();
  } catch (e) {
    error.value = e?.response?.data?.message || e.message;
  }
}
onMounted(cargar);
</script>

<template>
  <div>
    <h1 class="text-2xl font-semibold mb-4">Reportes</h1>

    <div class="flex items-center gap-3 mb-3">
      <label class="flex items-center gap-2 text-sm">
        <input type="checkbox" v-model="usandoMV" @change="cargar" />
        Usar vista materializada
      </label>
      <button @click="cargar" class="rounded bg-white/10 px-3 py-1 hover:bg-white/20">Refrescar</button>
    </div>

    <p v-if="error" class="text-sm text-red-400 mb-3">{{ error }}</p>

    <div class="rounded-xl border border-white/10 bg-white/5 overflow-auto">
      <table class="min-w-full text-sm">
        <thead class="bg-white/10">
          <tr>
            <th class="text-left p-2">Tipo de misión</th>
            <th class="text-left p-2">Total</th>
            <th class="text-left p-2">Horas promedio</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="(f,i) in filas" :key="i" class="border-t border-white/10">
            <td class="p-2">{{ f.tipo }}</td>
            <td class="p-2">{{ f.total }}</td>
            <td class="p-2">{{ Number(f.horas_promedio).toFixed(2) }}</td>
          </tr>
          <tr v-if="filas.length === 0">
            <td colspan="3" class="p-3 opacity-70">Sin datos.</td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>
