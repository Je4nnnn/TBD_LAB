// src/api.js
import axios from 'axios';

export const api = axios.create({
  baseURL: 'http://localhost:8081/api',
});

api.interceptors.request.use((cfg) => {
  const t = localStorage.getItem('token');
  if (t) cfg.headers.Authorization = `Bearer ${t}`;
  return cfg;
});

api.interceptors.response.use(
  (r) => r,
  (err) => {
    if (err?.response?.status === 401) {
      localStorage.removeItem('token');
      localStorage.removeItem('rol');
      localStorage.removeItem('nombre');
      // redirige a login
      window.location.href = '/login';
    }
    return Promise.reject(err);
  }
);
