import { createRouter, createWebHistory } from 'vue-router';
import { useAuthStore } from '../stores/auth';

import LoginView from '../views/LoginView.vue';
import DashboardView from '../views/DashboardView.vue';
import ReportsView from '../views/Reportes.vue'; // ← existe o pega el de abajo

const routes = [
  { path: '/', redirect: '/login' },
  { path: '/login', name: 'login', component: LoginView, meta: { public: true } },
  { path: '/reportes', name: 'reportes', component: ReportsView },
  { path: '/register', name: 'register', component: () => import('../views/RegisterView.vue') },
  { path: '/dashboard', name: 'dashboard', component: DashboardView, meta: { requiresAuth: true } },
  { path: '/misiones', name: 'misiones', component: () => import('../pages/Misiones.vue') },
  { path: '/drones', name: 'drones', component: () => import('../pages/Drones.vue') },
];


const router = createRouter({
  history: createWebHistory(),
  routes,
});

router.beforeEach((to) => {
  const auth = useAuthStore();
  const isAuth = auth.isAuth;

  if (!to.meta.public && !isAuth) {
    return { name: 'login' };
  }
  if (to.name === 'login' && isAuth) {
    return { name: 'dashboard' };
  }
});

export default router;
