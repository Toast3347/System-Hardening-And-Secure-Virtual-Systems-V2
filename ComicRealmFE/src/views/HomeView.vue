<script setup lang="ts">
import { computed } from 'vue'
import { RouterLink } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const authStore = useAuthStore()

const roleText = computed(() => authStore.user?.role ?? 'Unknown')
</script>

<template>
  <main class="home-view">
    <section class="hero-card">
      <h2>Welcome to ComicRealm</h2>
      <p v-if="authStore.user">
        Signed in as <strong>{{ authStore.user.email }}</strong> with role
        <strong>{{ roleText }}</strong>.
      </p>
      <p>Use the options below to access only what your role permits.</p>
    </section>

    <section class="action-grid">
      <article class="action-card" v-if="authStore.isSuperAdmin || authStore.isAdmin">
        <h3>User Management</h3>
        <p>
          Super Admin can create Admin users. Admin can create other users except Super Admin.
        </p>
        <RouterLink class="action-link" to="/users">Go to User Management</RouterLink>
      </article>

      <article class="action-card" v-if="authStore.isAdmin || authStore.isFriend">
        <h3>Comics</h3>
        <p>
          Admin can add, edit, and delete comics. Friends can browse the comics catalog.
        </p>
        <RouterLink class="action-link" to="/comics">Open Comics</RouterLink>
      </article>
    </section>

    <section class="note-card">
      <h4>Access Policy</h4>
      <p>
        Visitors without login cannot access protected pages. Route guards enforce role based access.
      </p>
    </section>
  </main>
</template>

<style scoped>
.home-view {
  display: grid;
  gap: 1rem;
}

.hero-card,
.action-card,
.note-card {
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: 14px;
  padding: 1rem;
}

.hero-card h2 {
  margin-bottom: 0.5rem;
  font-size: 1.3rem;
}

.hero-card p,
.action-card p,
.note-card p {
  color: var(--muted-text);
}

.action-grid {
  display: grid;
  gap: 1rem;
  grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
}

.action-card h3 {
  margin-bottom: 0.45rem;
}

.action-link {
  display: inline-block;
  margin-top: 0.8rem;
  color: var(--accent-text);
  font-weight: 600;
  text-decoration: none;
}

.action-link:hover {
  text-decoration: underline;
}

.note-card h4 {
  margin-bottom: 0.4rem;
}
</style>
