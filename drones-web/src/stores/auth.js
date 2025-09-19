import { defineStore } from 'pinia';
import http from '../lib/http';

export const useAuth = defineStore('auth', {
  state: () => ({
    token: localStorage.getItem('token') || null,
    user: null,
  }),
  getters: {
    isAuth: (s) => !!s.token,
  },
  actions: {
    async login(email, password) {
      // Tu backend devuelve { token: "..." } en /auth/login
      const { data } = await http.post('/auth/login', { email, password });
      const token = data.token || data; // por si devolvieras sólo el string
      this.token = token;
      localStorage.setItem('token', token);
    },
    logout() {
      this.token = null;
      this.user = null;
      localStorage.removeItem('token');
    },
  },
});
