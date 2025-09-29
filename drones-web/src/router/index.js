import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '../stores/auth'
import Login from '../views/LoginView.vue'
import Dashboard from '../views/DashboardView.vue'

const routes = [
  { path: '/login', name: 'login', component: Login },
  { path: '/register', name: 'register', component: () => import('../views/RegisterView.vue') },
  { path: '/', name: 'dashboard', component: Dashboard, meta: { requiresAuth: true } },
  { path: '/misiones', name: 'misiones', component: () => import('../pages/Misiones.vue') },
  { path: '/reportes', name: 'reportes', component: () => import('../pages/Reportes.vue') },
  { path: '/drones', name: 'drones', component: () => import('../pages/Drones.vue') }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

router.beforeEach((to) => {
  const auth = useAuthStore()
  if (to.meta.requiresAuth && !auth.token) {
    return { name: 'login' }
  }
})

export default router
