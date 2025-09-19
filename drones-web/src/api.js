// src/api.js
import axios from 'axios'

const api = axios.create({
  baseURL: import.meta.env.VITE_API_BASE, // p.ej. http://localhost:8081/api
})

api.interceptors.request.use((config) => {
  const token = localStorage.getItem('token')
  if (token) {
    config.headers.Authorization = `Bearer ${token}`
  }
  return config
})

// Antes borraba token y hacía window.location.href='/login' en cualquier 401
api.interceptors.response.use(
  (r) => r,
  (err) => {
    if (err?.response?.status === 401) {
      console.warn('401 recibido. Manejar en la vista según corresponda.')
      // Puedes emitir un evento global, mostrar toast, etc.
    }
    return Promise.reject(err)
  }
)

export { api }
