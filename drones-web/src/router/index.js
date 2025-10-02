// src/router/index.js
import { createRouter, createWebHistory } from 'vue-router';

// Si ya tienes tus vistas, ajusta las rutas a tus nombres reales
const Login = () => import('../views/LoginView.vue');
const Dashboard = () => import('../views/DashboardView.vue'); // tu vista principal
const Reports = () => import('../views/ReportsView.vue');     // opcional

const routes = [
  { path: '/login', name: 'login', component: Login },
  { path: '/', name: 'home', component: Dashboard, meta: { requiresAuth: true } },
  { path: '/reportes', name: 'reportes', component: Reports, meta: { requiresAuth: true, roles: ['ADMIN'] } },
];

const router = createRouter({ history: createWebHistory(), routes });

router.beforeEach((to, from, next) => {
  const token = localStorage.getItem('token');
  const rol = localStorage.getItem('rol') || 'OPERADOR';
  if (to.meta.requiresAuth && !token) return next('/login');
  if (to.meta.roles && !to.meta.roles.includes(rol)) return next('/');
  next();
});

export default router;
