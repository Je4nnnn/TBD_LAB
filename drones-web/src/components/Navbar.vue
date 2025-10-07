<!-- src/components/NavBar.vue -->
<script setup>
import { RouterLink, useRouter } from 'vue-router';

const router = useRouter();
const logout = () => {
  localStorage.removeItem('token');
  router.push('/login');
};
</script>

<template>
  <nav style="display:flex; gap:16px; justify-content:center; align-items:center; margin:16px 0;">
    <strong>DroneOps</strong>
    <RouterLink to="/drones">Drones</RouterLink>
    <RouterLink to="/misiones">Misiones</RouterLink>
    <RouterLink to="/reportes">Reportes</RouterLink>
    <button @click="logout" style="margin-left:16px;">Cerrar sesión</button>
  </nav>
</template>
