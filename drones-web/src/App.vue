<!-- src/App.vue -->
<script setup>
import { useRouter } from 'vue-router';

const router = useRouter();

function isLogged() {
  return !!localStorage.getItem('token');
}
function logout() {
  localStorage.removeItem('token');
  router.push('/login');
}
</script>

<template>
  <div class="min-h-screen bg-[#0b1220] text-white">
    <header class="border-b border-white/10">
      <nav class="max-w-4xl mx-auto flex items-center justify-between p-4">
        <div class="font-semibold">DroneOps</div>
        <div class="flex gap-4 items-center">
          <RouterLink to="/drones" class="hover:underline">Drones</RouterLink>
          <RouterLink to="/misiones" class="hover:underline">Misiones</RouterLink>
          <RouterLink to="/reportes" class="hover:underline">Reportes</RouterLink>
          <button
            v-if="isLogged()"
            @click="logout"
            class="ml-2 rounded bg-white/10 px-3 py-1 hover:bg-white/20"
          >
            Cerrar sesión
          </button>
        </div>
      </nav>
    </header>
    <main class="max-w-4xl mx-auto p-4">
      <RouterView />
    </main>
  </div>
</template>

<style>
body { margin: 0; }
</style>
