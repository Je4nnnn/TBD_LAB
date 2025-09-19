<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { Auth } from '@/api'

const email = ref('admin@drones.local')
const password = ref('admin123')
const cargando = ref(false)
const error = ref('')
const router = useRouter()

async function onSubmit () {
  cargando.value = true; error.value = ''
  try {
    const { token } = await Auth.login(email.value, password.value)
    localStorage.setItem('token', token)
    router.push('/drones')
  } catch (e) {
    error.value = e?.response?.data?.message || e.message || 'Error de login'
  } finally { cargando.value = false }
}
</script>

<template>
  <div class="max-w-sm mx-auto mt-16 p-6 rounded-xl bg-white/5 border border-white/10 text-white">
    <h1 class="text-xl font-semibold mb-4">Iniciar sesión</h1>
    <p v-if="error" class="text-red-400 text-sm mb-3">{{ error }}</p>
    <form @submit.prevent="onSubmit" class="space-y-3">
      <input v-model="email" type="email" placeholder="Email" class="w-full p-2 rounded bg-white/10" />
      <input v-model="password" type="password" placeholder="Contraseña" class="w-full p-2 rounded bg-white/10" />
      <button :disabled="cargando" class="w-full p-2 rounded bg-blue-600 hover:bg-blue-500">
        {{ cargando ? 'Entrando…' : 'Entrar' }}
      </button>
    </form>
  </div>
</template>
