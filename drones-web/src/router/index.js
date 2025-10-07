import { createRouter, createWebHistory } from 'vue-router';
import { useAuthStore } from '../stores/auth';

import LoginView from '../views/LoginView.vue';
import DashboardView from '../views/DashboardView.vue';
import ReportsView from '../views/ReportsView.vue'; // ← existe o pega el de abajo

const routes = [
  { path: '/login', name: 'login', component: LoginView, meta: { public: true } },
  { path: '/',      name: 'home',  component: DashboardView },
  { path: '/reportes', name: 'reportes', component: ReportsView },
  // { path: '/:pathMatch(.*)*', redirect: '/' },
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
