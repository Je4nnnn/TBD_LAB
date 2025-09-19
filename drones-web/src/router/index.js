// src/router/index.js
import { createRouter, createWebHistory } from 'vue-router';
import Login from '../pages/Login.vue';
import Drones from '../pages/Drones.vue';
import Misiones from '../pages/Misiones.vue';
import Reportes from '../pages/Reportes.vue';

const routes = [
  { path: '/login', component: Login },
  { path: '/drones', component: Drones, meta: { auth: true } },
  { path: '/misiones', component: Misiones, meta: { auth: true } },
  { path: '/reportes', component: Reportes, meta: { auth: true } },
  { path: '/', redirect: '/drones' },
  { path: '/:pathMatch(.*)*', redirect: '/drones' },
];

const router = createRouter({
  history: createWebHistory(),
  routes,
});

router.beforeEach((to) => {
  const hasToken = !!localStorage.getItem('token');

  if (to.meta?.auth && !hasToken) return '/login';
  if (to.path === '/login' && hasToken) return '/drones';
  return true;
});

export default router;
