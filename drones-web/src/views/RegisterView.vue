<template>
    <div class="registerform-wrapper">
        <div class="registerform-form">
            <div class="registerform-innerform">
                <h2 class="registerform-title">Crear Cuenta</h2>
                <p class="registerform-subtitle">Regístrate para acceder a tu cuenta</p>
                <form @submit.prevent="handleRegister">
                <div class="registerform-group">
                    <label for="username" class="registerform-label">Nombre de Usuario</label>
                    <input v-model="username" type="text" id="username" class="registerform-input" required />
                </div>
                <div class="registerform-group">
                    <label for="email" class="registerform-label">Correo Electrónico</label>
                    <input v-model="email" type="email" id="email" class="registerform-input" required />
                </div>
                <div class="registerform-group">
                    <label for="password" class="registerform-label">Contraseña</label>
                    <input v-model="password" type="password" id="password" class="registerform-input" required />
                </div>
                <div class="registerform-group">
                    <label for="confirmPassword" class="registerform-label">Confirmar Contraseña</label>
                    <input v-model="confirmPassword" type="password" id="confirmPassword" class="registerform-input" required />
                </div>
                <button type="submit" class="registerform-btn">Registrarse</button>
                <p v-if="error" class="registerform-error">{{ error }}</p>
                </form>
                <p class="registerform-login-link">
                    ¿Ya tienes una cuenta?
                    <a href="/" class="registerform-login-link-anchor">Inicia Sesión</a>
                </p>
            </div>
        </div>
    </div>
</template>

<script>
import axios from 'axios'
// O usa tu servicio de autenticación

export default {
  name: 'RegisterView',
  data() {
    return {
      nombre: '',
      email: '',
      password: '',
      error: '',
      success: ''
    }
  },
  methods: {
    async handleRegister() {
      try {
        await axios.post('http://localhost:8080/api/register', {
          nombre: this.nombre,
          email: this.email,
          password: this.password
        })
        this.success = 'Usuario registrado correctamente'
        this.error = ''
      } catch (e) {
        this.error = 'Error al registrar usuario'
        this.success = ''
      }
    }
  }
}
</script>

<style scoped>
.registerform-wrapper,
.registerform-form,
.registerform-title,
.registerform-subtitle,
.registerform-label,
.registerform-input,
.registerform-btn,
.registerform-login-link,
.registerform-login-link-anchor,
.registerform-error {
  font-family: 'Inter', Arial, Helvetica, sans-serif;
}
.registerform-wrapper {
  display: flex;
  justify-content: center;
  align-items: center;
  height: 100%;
  width: 100%;
  background: #f8fafc;
  border-radius: 0;
  box-shadow: none;
  margin: 0;
  padding: 0;
}
.registerform-form {
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
.registerform-innerform {
  width: 100%;
  max-width: 340px;
  
}
.registerform-innerform p {
    display: flex;
    justify-content: center;
    align-items: center;
}
.registerform-title {
  font-size: 2rem;
  font-weight: 600;
  color: #1f2937;
  margin-bottom: 8px;
  display: flex;
  align-items: center;
  justify-content: center;
}
.registerform-subtitle {
  font-size: 1rem;
  color: #9ca3af;
  margin-bottom: 28px;
}
.registerform-label {
  display: block;
  margin-top: 20px;
  margin-bottom: 10px;
  font-weight: 500;
  color: #4b5563;
  font-size: 1rem;
}
.registerform-input {
  width: 100%;
  box-sizing: border-box;
  padding: 14px 16px;
  margin-bottom: 16px;
  border: 1px solid #e0e7ff;
  border-radius: 8px;
  background: #eef2ff;
  font-size: 1rem;
  color: #374151;
  transition: border 0.2s;
}
.registerform-input:focus {
  border: 1.5px solid #6366f1;
  outline: none;
}
.registerform-btn {
  width: 100%;
  box-sizing: border-box;
  padding: 14px 16px;
  background: #6366f1;
  color: #fff;
  border: none;
  border-radius: 8px;
  font-size: 1rem;
  font-weight: 600;
  cursor: pointer;
  margin-top: 16px;
  margin-bottom: 16px;
  box-shadow: 0 2px 8px rgba(99,102,241,0.15);
  transition: background 0.2s;
}

.registerform-btn:hover {
  background: #4f46e5;
}
.registerform-error {
  color: #d32f2f;
  margin-top: 12px;
}
.registerform-login-link {
  margin-top: 10px;
  margin-bottom: 10px;
  gap: 8px;
  font-size: 0.95rem;
  display: flex;
  align-items: center;
  justify-content: center;
}
.registerform-login-link-anchor {
  color: #6366f1;
  text-decoration: none;
  font-weight: 500;
}
</style>