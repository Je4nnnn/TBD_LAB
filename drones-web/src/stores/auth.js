import { defineStore } from 'pinia';
import api from '../api/axios';

export const useAuthStore = defineStore('auth', {
  state: () => ({
    token: localStorage.getItem('token') || '',
    nombre: localStorage.getItem('nombre') || '',
    rol: localStorage.getItem('rol') || '',
  }),
  getters: {
    isAuth: (s) => !!s.token,
    user:   (s) => ({ nombre: s.nombre, rol: s.rol }),
  },
  actions: {
    async login(email, password) {
      const { data } = await api.post('/auth/login', { email, password });
      this.token  = data.token;
      this.nombre = data.nombre;
      this.rol    = data.rol;
      localStorage.setItem('token', this.token);
      localStorage.setItem('nombre', this.nombre);
      localStorage.setItem('rol', this.rol);
    },
    logout() {
      this.token = ''; this.nombre = ''; this.rol = '';
      localStorage.removeItem('token');
      localStorage.removeItem('nombre');
      localStorage.removeItem('rol');
    },
  },
});
