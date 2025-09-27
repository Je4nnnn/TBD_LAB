<template>
  <div class="login-modern-wrapper">
    <div class="login-modern-form">
      <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
      <h1 class="login-modern-title">Bienvenido</h1>
      <p class="login-modern-subtitle">Inicia sesión para continuar</p>
      <form @submit.prevent="handleLogin" class="login-modern-innerform">
        <label class="login-modern-label" for="email">Email</label>
        <input v-model="email" class="login-modern-input" type="email" id="email" required />
        <label class="login-modern-label" for="password">Contraseña</label>
        <input v-model="password" class="login-modern-input" type="password" id="password" required />
        <div class="login-modern-options">
          <input type="checkbox" v-model="remember" id="remember" />
          <span class="login-modern-remember">Recordarme</span>
          <a href="#" class="login-modern-forgot">¿Olvidaste tu contraseña?</a>
        </div>
        <button type="submit" class="login-modern-btn" :disabled="loading">
          {{ loading ? 'Ingresando...' : 'Iniciar sesión' }}
        </button>
        <p v-if="error" class="login-modern-error">{{ error }}</p>
        <div class="login-modern-register-link">
          <span>¿No tienes una cuenta?</span>
          <a href="/register">Registrarse</a>
        </div>
      </form>
    </div>
    <div class="login-modern-logo">
      <img src="@/Assets/vue.svg" alt="Logo" />
      <h2 style="margin-top: 20px; color: #4f46e5; font-weight: 600; font-size: 2rem;">
        Drone<span style="color: #6366f1">.io</span>
      </h2>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { useAuthStore } from '../stores/auth'
import { useRouter } from 'vue-router'

const email = ref('')
const password = ref('')
const remember = ref(false)
const loading = ref(false)
const error = ref('')
const auth = useAuthStore()
const router = useRouter()

const handleLogin = async () => {
  error.value = ''
  loading.value = true
  try {
    await auth.login(email.value, password.value)
    router.push({ name: 'dashboard' })
  } catch (e) {
    error.value = 'Credenciales inválidas'
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
.login-modern-wrapper,
.login-modern-form,
.login-modern-title,
.login-modern-subtitle,
.login-modern-label,
.login-modern-input,
.login-modern-btn,
.login-modern-register-link,
.login-modern-remember,
.login-modern-forgot {
  font-family: 'Inter', Arial, Helvetica, sans-serif;
}
.login-modern-wrapper {
  display: flex;
  min-height: 100vh;
  height: 100vh;
  width: 100vw;
  background: #f8fafc;
  border-radius: 0;
  box-shadow: none;
  overflow: hidden;
  margin: 0;
  padding: 0;
}
.login-modern-form {
  flex: 1;
  background: #fff;
  padding: 24px 24px;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  min-width: 0;
  max-width: none;
}
.login-modern-innerform {
  width: 100%;
  max-width: 340px;
}
.login-modern-title {
  font-size: 2rem;
  font-weight: 600;
  color: #1f2937;
  margin-bottom: 8px;
}
.login-modern-subtitle {
  font-size: 1rem;
  color: #9ca3af;
  margin-bottom: 28px;
}
.login-modern-label {
  display: block;
  margin-top: 20px;
  margin-bottom: 10px;
  font-weight: 500;
  color: #4b5563;
  font-size: 1rem;
}
.login-modern-input {
  width: 100%;
  padding: 14px 16px;
  margin-bottom: 16px;
  border: 1px solid #e0e7ff;
  border-radius: 8px;
  background: #eef2ff;
  font-size: 1rem;
  color: #374151;
  transition: border 0.2s;
}
.login-modern-input:focus {
  border: 1.5px solid #6366f1;
  outline: none;
}
.login-modern-options {
  display: flex;
  align-items: center;
  margin-bottom: 16px;
}
.login-modern-remember {
  margin-left: 8px;
  font-size: 0.95rem;
  color: #6b7280;
}
.login-modern-forgot {
  margin-left: auto;
  font-size: 0.95rem;
  color: #6366f1;
  text-decoration: none;
}
.login-modern-forgot:hover {
  text-decoration: underline;
}
.login-modern-btn {
  width: 100%;
  padding: 14px;
  background: #6366f1;
  color: #fff;
  border: none;
  border-radius: 8px;
  font-size: 1rem;
  font-weight: 600;
  cursor: pointer;
  margin-top: 16px;
  margin-bottom: 12px;
  box-shadow: 0 2px 8px rgba(99,102,241,0.15);
  transition: background 0.2s;
}
.login-modern-btn:hover {
  background: #4f46e5;
}
.login-modern-error {
  color: #d32f2f;
  margin-top: 12px;
}
.login-modern-register-link {
  margin-top: 24px;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  font-size: 0.95rem;
}
.login-modern-register-link a {
  color: #6366f1;
  text-decoration: none;
  font-weight: 500;
}
.login-modern-register-link a:hover {
  text-decoration: underline;
}
.login-modern-logo {
  flex: 1;
  background: #f8fafc;
  display: flex;
  align-items: center;
  justify-content: center;
  min-width: 0;
  background-color: #fff;
}
.login-modern-logo img {
  max-width: 250px;
  filter: drop-shadow(0 2px 8px rgba(0,0,0,0.08));
}
</style>