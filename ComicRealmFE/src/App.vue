<script setup lang="ts">
import { computed, onMounted, onBeforeUnmount } from 'vue'
import { RouterLink, RouterView, useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const authStore = useAuthStore()
const router = useRouter()

const isSignedIn = computed(() => authStore.isAuthenticated)
const canManageUsers = computed(() => authStore.isAdmin || authStore.isSuperAdmin)
const canSeeComics = computed(() => authStore.isAdmin || authStore.isFriend)

function handleAuthExpired(): void {
  if (router.currentRoute.value.name !== 'login') {
    router.push({ name: 'login' })
  }
}

async function handleLogout(): Promise<void> {
  await authStore.logout()
  await router.push({ name: 'login' })
}

onMounted(() => {
  window.addEventListener('comicrealm:auth-expired', handleAuthExpired)
})

onBeforeUnmount(() => {
  window.removeEventListener('comicrealm:auth-expired', handleAuthExpired)
})
</script>

<template>
  <div class="app-shell">
    <header class="app-header">
      <div class="brand">
        <h1>ComicRealm</h1>
        <p>Secure comic management with role-based access</p>
      </div>

      <nav class="nav-links">
        <RouterLink v-if="isSignedIn" to="/">Home</RouterLink>
        <RouterLink v-if="canManageUsers" to="/users">User Management</RouterLink>
        <RouterLink v-if="canSeeComics" to="/comics">Comics</RouterLink>
        <RouterLink v-if="!isSignedIn" to="/login">Login</RouterLink>
      </nav>

      <div class="session-block">
        <span v-if="isSignedIn && authStore.user" class="session-user">
          {{ authStore.user.email }} ({{ authStore.user.role }})
        </span>
        <button v-if="isSignedIn" class="logout-button" type="button" @click="handleLogout">
          Logout
        </button>
      </div>
    </header>

    <div class="app-content">
      <RouterView />
    </div>
  </div>
</template>

<style scoped>
.app-shell {
  display: flex;
  flex-direction: column;
  min-height: 100vh;
}

.app-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 1rem;
  flex-wrap: wrap;
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: 14px;
  padding: 1rem 1.2rem;
  margin-bottom: 1.2rem;
}

.brand h1 {
  font-size: 1.25rem;
  font-weight: 700;
}

.brand p {
  color: var(--muted-text);
  font-size: 0.9rem;
}

.nav-links {
  display: flex;
  gap: 0.8rem;
  flex-wrap: wrap;
}

.nav-links a {
  color: var(--accent-text);
  text-decoration: none;
  font-weight: 600;
  padding: 0.35rem 0.55rem;
  border-radius: 8px;
}

.nav-links a.router-link-active {
  background: var(--accent-soft);
}

.session-block {
  display: flex;
  align-items: center;
  gap: 0.8rem;
  flex-wrap: wrap;
}

.session-user {
  color: var(--muted-text);
  font-size: 0.9rem;
}

.logout-button {
  border: 1px solid var(--border-strong);
  background: var(--surface-alt);
  color: var(--text);
  border-radius: 8px;
  padding: 0.45rem 0.8rem;
  cursor: pointer;
}

.logout-button:hover {
  background: var(--accent-soft);
}

.app-content {
  flex: 1;
}

@media (max-width: 700px) {
  .app-header {
    align-items: flex-start;
  }
}
</style>
