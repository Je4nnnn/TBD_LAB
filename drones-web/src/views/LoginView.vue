<template>
  <div style="display:grid;place-items:center;min-height:calc(100vh - 60px);">
    <form @submit.prevent="submit" style="width:360px;padding:24px;border:1px solid #334155;border-radius:12px;background:#0f172a;">
      <h2 style="margin:0 0 16px;">Iniciar sesión</h2>

      <label>Email</label>
      <input v-model="email" type="email" required
             style="width:100%;padding:10px;margin:6px 0 14px;border-radius:8px;border:1px solid #475569;background:#0b1220;color:#e2e8f0" />

      <label>Contraseña</label>
      <input v-model="password" type="password" required
             style="width:100%;padding:10px;margin:6px 0 18px;border-radius:8px;border:1px solid #475569;background:#0b1220;color:#e2e8f0" />

      <button :disabled="loading" style="width:100%;padding:10px;border:none;border-radius:8px;background:#2563eb;color:white">
        {{ loading ? 'Ingresando…' : 'Entrar' }}
      </button>

      <p v-if="error" style="color:#f87171;margin-top:12px">{{ error }}</p>
    </form>
  </div>
</template>

<script setup>
import { ref } from 'vue';
import { useRouter } from 'vue-router';
import { useAuth } from '../stores/auth';

const router = useRouter();
const auth = useAuth();

const email = ref('admin@drones.local');
const password = ref('admin123');
const error = ref('');
const loading = ref(false);

async function submit() {
  error.value = ''; loading.value = true;
  try {
    await auth.login(email.value, password.value);
    router.push({ name: 'drones' });
  } catch {
    error.value = 'Credenciales inválidas';
  } finally {
    loading.value = false;
  }
}
</script>
