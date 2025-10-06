import axios from 'axios';

// Usa el backend directamente (evita 404 en Vite)
const BASE = (import.meta.env.VITE_API_BASE || 'http://localhost:8081/api').trim();

const api = axios.create({
  baseURL: BASE,
  withCredentials: false,
});

api.interceptors.request.use((config) => {
  const token = localStorage.getItem('token');
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});

export default api;
