<script setup>
import { ref, onMounted } from 'vue'
import { Drones } from '@/api'

const lista = ref([])
const error = ref('')
const cargando = ref(false)

async function cargar () {
  cargando.value = true; error.value = ''
  try { lista.value = await Drones.list() }
  catch (e) { error.value = e?.response?.data?.message || e.message }
  finally { cargando.value = false }
}
onMounted(cargar)
</script>

<template>
  <div class="text-white space-y-4">
    <h1 class="text-2xl font-semibold">Drones</h1>
    <p v-if="error" class="text-red-400 text-sm">{{ error }}</p>
    <div v-for="d in lista" :key="d.id" class="p-4 rounded-xl bg-white/5 border border-white/10">
      <div class="font-semibold">{{ d.modelo }}</div>
      <div class="text-xs opacity-70">Batería: {{ d.bateria_pct }}%</div>
      <div class="text-xs opacity-70">Estado: {{ d.estado }}</div>
      <div class="text-xs opacity-70" v-if="d.ultima_lat != null">Última pos: {{ d.ultima_lat }}, {{ d.ultima_lon }}</div>
    </div>
  </div>
</template>
