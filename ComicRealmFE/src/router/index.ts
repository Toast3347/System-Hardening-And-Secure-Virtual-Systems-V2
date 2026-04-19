import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import HomeView from '../views/HomeView.vue'

type Role = 'SuperAdmin' | 'Admin' | 'Friend'

declare module 'vue-router' {
  interface RouteMeta {
    requiresAuth?: boolean
    guestOnly?: boolean
    allowedRoles?: Role[]
  }
}

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/',
      name: 'home',
      component: HomeView,
      meta: {
        requiresAuth: true,
        allowedRoles: ['SuperAdmin', 'Admin', 'Friend'],
      },
    },
    {
      path: '/login',
      name: 'login',
      component: () => import('../views/LoginView.vue'),
      meta: {
        guestOnly: true,
      },
    },
    {
      path: '/users',
      name: 'users',
      component: () => import('../views/UserManagementView.vue'),
      meta: {
        requiresAuth: true,
        allowedRoles: ['SuperAdmin', 'Admin'],
      },
    },
    {
      path: '/comics',
      name: 'comics',
      component: () => import('../views/ComicsView.vue'),
      meta: {
        requiresAuth: true,
        allowedRoles: ['Admin', 'Friend'],
      },
    },
    {
      path: '/:pathMatch(.*)*',
      redirect: '/',
    },
  ],
})

router.beforeEach((to) => {
  const authStore = useAuthStore()
  authStore.restoreSession()

  if (to.meta.guestOnly && authStore.isAuthenticated) {
    return { name: 'home' }
  }

  if (to.meta.requiresAuth && !authStore.isAuthenticated) {
    return { name: 'login', query: { redirect: to.fullPath } }
  }

  if (to.meta.allowedRoles && authStore.role && !to.meta.allowedRoles.includes(authStore.role)) {
    return { name: 'home' }
  }

  return true
})

export default router
