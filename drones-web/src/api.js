// src/api.js
import axios from 'axios';

export const api = axios.create({
  baseURL: 'http://localhost:8081/api',
});

api.interceptors.request.use((cfg) => {
  const t = localStorage.getItem('token');
  if (t) {
    // Asegurar que el header se establezca correctamente
    if (!cfg.headers) {
      cfg.headers = {};
    }
    cfg.headers['Authorization'] = `Bearer ${t}`;
    // Log para debugging DELETE
    if (cfg.method?.toLowerCase() === 'delete' && cfg.url?.includes('/drones/')) {
      console.log('[API] DELETE request con token:', {
        url: cfg.url,
        method: cfg.method,
        hasAuth: !!cfg.headers.Authorization,
        headers: Object.keys(cfg.headers),
        tokenPreview: t.substring(0, 20) + '...'
      });
    }
  } else {
    console.warn('No token found in localStorage for request:', cfg.method, cfg.url);
  }
  return cfg;
});

api.interceptors.response.use(
  (r) => r,
  (err) => {
    // Solo cerrar sesión si es un 401 real (no autorizado)
    // No cerrar sesión si es un error de validación (400) u otro error del servidor
    if (err?.response?.status === 401 && err?.config?.url) {
      const url = err.config.url;
      const method = err.config.method?.toLowerCase();
      
      // NO cerrar sesión automáticamente para DELETE de drones
      // Dejar que el componente maneje el error
      if (method === 'delete' && url.includes('/drones/')) {
        console.warn('Error 401 al eliminar dron - el componente manejará el error:', err);
        return Promise.reject(err);
      }
      
      // Para otros 401 (GET, POST, etc.), cerrar sesión normalmente
      localStorage.removeItem('token');
      localStorage.removeItem('rol');
      localStorage.removeItem('nombre');
      window.location.href = '/login';
    }
    return Promise.reject(err);
  }
);
