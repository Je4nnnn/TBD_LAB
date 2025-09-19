// src/api.js
import axios from 'axios';

const api = axios.create({
  baseURL: import.meta.env.VITE_API_BASE || 'http://localhost:8081/api',
});

// Adjunta el token en cada request
api.interceptors.request.use((config) => {
  const t = localStorage.getItem('token');
  if (t) config.headers.Authorization = `Bearer ${t}`;
  return config;
});

// Si el token vence → a /login
api.interceptors.response.use(
  (r) => r,
  (err) => {
    if (err?.response?.status === 401) {
      localStorage.removeItem('token');
      if (location.pathname !== '/login') location.href = '/login';
    }
    return Promise.reject(err);
  }
);

export const Auth = {
  login(email, password) {
    return api.post('/auth/login', { email, password }).then((r) => r.data);
  },
};

export const Drones = {
  list() {
    return api.get('/drones').then((r) => r.data);
  },
};

export const Misiones = {
  list() {
    return api.get('/misiones').then((r) => r.data);
  },
  create(body) {
    return api.post('/misiones', body).then((r) => r.data);
  },
  assign(id, droneId) {
    return api.post(`/misiones/${id}/asignar/${droneId}`).then((r) => r.data);
  },
  completar(id) {
    return api.post(`/misiones/${id}/completar`).then((r) => r.data);
  },
};

export const Telemetria = {
  enviar(misionId, lat, lon, bateria) {
    return api.post('/telemetria', { misionId, lat, lon, bateria }).then((r) => r.data);
  },
};

export const Reportes = {
  resumen() {
    // si expusiste un resumen “en vivo”
    return api.get('/reportes/resumen').then((r) => r.data);
  },
  resumenMV() {
    // si expusiste la MV de “resumen_misiones_completadas”
    return api.get('/reportes/resumen-mv').then((r) => r.data);
  },
};

export default api;
