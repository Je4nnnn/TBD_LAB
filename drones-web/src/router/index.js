import { createRouter, createWebHistory } from 'vue-router'
import Login from '@/pages/Login.vue'
import Drones from '@/pages/Drones.vue'
import Misiones from '@/pages/Misiones.vue'
import Reportes from '@/pages/Reportes.vue'

const router = createRouter({
  history: createWebHistory(),
  routes: [
    { path: '/login', component: Login, meta: { public: true } },
    { path: '/', redirect: '/drones' },
    { path: '/drones', component: Drones },
    { path: '/misiones', component: Misiones },
    { path: '/reportes', component: Reportes },
    { path: '/:pathMatch(.*)*', redirect: '/' },
  ],
})

router.beforeEach((to) => {
  const isPublic = to.meta?.public
  const token = localStorage.getItem('token')
  if (!isPublic && !token) return '/login'
  return true
})

export default router
