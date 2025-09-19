<template>
  <div class="login">
    <h1>Ingreso</h1>
    <form @submit.prevent="doLogin">
      <label>Email</label>
      <input v-model="email" type="email" required />
      <label>Contraseña</label>
      <input v-model="password" type="password" required />
      <button :disabled="loading">{{ loading ? 'Ingresando...' : 'Entrar' }}</button>
      <p v-if="error" style="color:red">{{ error }}</p>
    </form>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { useAuthStore } from '../stores/auth'
import { useRouter } from 'vue-router'

const email = ref('admin@drones.local')
const password = ref('admin123')
const loading = ref(false)
const error = ref('')
const auth = useAuthStore()
const router = useRouter()

const doLogin = async () => {
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

<style>
.login { max-width: 360px; margin: 3rem auto; display: flex; flex-direction: column; gap: .5rem; }
label { margin-top: .5rem; }
button { margin-top: 1rem; }
</style>
