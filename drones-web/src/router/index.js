import { createRouter, createWebHistory } from 'vue-router';
import { useAuthStore } from '../stores/auth';

import LoginView from '../views/LoginView.vue';
import DashboardView from '../views/DashboardView.vue';
import ReportsView from '../views/ReportsView.vue';
import CreateMissionView from '../views/CreateMissionView.vue';
import CreateDroneView from '../views/CreateDroneView.vue';

// 1. IMPORTANTE: Importar la nueva vista que creamos
import AdvancedReportsView from '../views/AdvancedReportsView.vue';

const routes = [
  { path: '/login', name: 'login', component: LoginView, meta: { public: true } },
  { path: '/',      name: 'home',  component: DashboardView },
  { path: '/reportes', name: 'reportes', component: ReportsView },
  { path: '/misiones/nueva', name: 'crear-mision', component: CreateMissionView },
  { path: '/drones/nuevo', name: 'crear-dron', component: CreateDroneView },

  // 2. IMPORTANTE: Agregar la ruta al arreglo
  { path: '/reportes/avanzados', name: 'reportes-avanzados', component: AdvancedReportsView },
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
    return { name: 'home' };
  }
});

export default router;