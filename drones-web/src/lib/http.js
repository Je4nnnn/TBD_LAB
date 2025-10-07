// src/lib/http.js
import axios from 'axios'

// Cliente único para toda la app (protege rutas con JWT)
const http = axios.create({
  baseURL: import.meta.env.VITE_API_BASE, // ej: http://localhost:8081/api
  withCredentials: false,
})

// Inyecta el token en cada request
http.interceptors.request.use((config) => {
  const token = localStorage.getItem('token')
  if (token) {
    config.headers.Authorization = `Bearer ${token}`
  }
  return config
})

export default http
