<!-- src/pages/Login.vue -->
<script setup>
import { ref } from 'vue';
import { useRouter } from 'vue-router';
import { api } from '../api';

const email = ref('admin@drones.local');
const password = ref('admin123');
const loading = ref(false);
const error = ref('');
const router = useRouter();

const doLogin = async () => {
  loading.value = true;
  error.value = '';
  try {
    const { data } = await api.post('/auth/login', {
      email: email.value,
      password: password.value
    });
    localStorage.setItem('token', data.token);
    router.push('/drones');
  } catch (e) {
    error.value = 'Credenciales inválidas';
  } finally {
    loading.value = false;
  }
};
</script>

<template>
  <div style="min-height:100vh; display:flex; align-items:center; justify-content:center;">
    <div style="width:360px; padding:24px; border:1px solid #444; border-radius:8px; text-align:center;">
      <h1 style="margin-bottom:16px;">Iniciar sesión</h1>
      <input
        v-model="email"
        placeholder="Email"
        style="width:100%; padding:8px; margin-bottom:8px;"
        autocomplete="username"
      />
      <input
        v-model="password"
        type="password"
        placeholder="Contraseña"
        style="width:100%; padding:8px; margin-bottom:12px;"
        autocomplete="current-password"
      />
      <button :disabled="loading" @click="doLogin" style="width:100%; padding:8px;">
        {{ loading ? 'Ingresando...' : 'Entrar' }}
      </button>
      <p v-if="error" style="color:#f55; margin-top:8px;">{{ error }}</p>
    </div>
  </div>
</template>
