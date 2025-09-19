<template>
  <header style="display:flex;align-items:center;gap:16px;padding:12px 16px;border-bottom:1px solid #334155;">
    <strong>DroneOps</strong>
    <nav style="display:flex;gap:12px;">
      <RouterLink to="/drones">Drones</RouterLink>
    </nav>
    <div style="margin-left:auto;">
      <button @click="logout" style="padding:6px 10px;border:1px solid #475569;background:#0f172a;color:#e2e8f0;border-radius:6px">
        Cerrar sesión
      </button>
    </div>
  </header>
</template>

<script setup>
import { useAuth } from '../stores/auth';
import { useRouter, RouterLink } from 'vue-router';

const auth = useAuth();
const router = useRouter();
function logout() { auth.logout(); router.push({ name:'login' }); }
</script>
