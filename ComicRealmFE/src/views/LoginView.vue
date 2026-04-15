<script setup lang="ts">
import { reactive, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { ApiError } from '@/services/httpClient'

const authStore = useAuthStore()
const router = useRouter()
const route = useRoute()

const form = reactive({
  email: '',
  passwordHash: '',
})

const isSubmitting = ref(false)
const errorMessage = ref('')

async function onSubmit(): Promise<void> {
  errorMessage.value = ''
  isSubmitting.value = true

  try {
    await authStore.login({
      email: form.email,
      passwordHash: form.passwordHash,
    })

    const redirect = typeof route.query.redirect === 'string' ? route.query.redirect : '/'
    await router.push(redirect)
  } catch (error) {
    if (error instanceof ApiError) {
      errorMessage.value = error.message
    } else {
      errorMessage.value = 'Login failed. Please try again.'
    }
  } finally {
    isSubmitting.value = false
  }
}
</script>

<template>
  <main class="login-view">
    <section class="login-card">
      <h2>Login</h2>
      <p>Use your account credentials to access role-specific pages.</p>

      <form class="login-form" @submit.prevent="onSubmit">
        <label>
          Email
          <input v-model.trim="form.email" type="email" required autocomplete="email" />
        </label>

        <label>
          Password
          <input
            v-model="form.passwordHash"
            type="password"
            required
            autocomplete="current-password"
          />
        </label>

        <button type="submit" :disabled="isSubmitting">
          {{ isSubmitting ? 'Signing in...' : 'Login' }}
        </button>
      </form>

      <p v-if="errorMessage" class="error-text">{{ errorMessage }}</p>
    </section>
  </main>
</template>

<style scoped>
.login-view {
  min-height: 65vh;
  display: grid;
  place-items: center;
}

.login-card {
  width: 100%;
  max-width: 420px;
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: 14px;
  padding: 1.2rem;
}

.login-card h2 {
  margin-bottom: 0.4rem;
}

.login-card p {
  color: var(--muted-text);
  margin-bottom: 1rem;
}

.login-form {
  display: grid;
  gap: 0.8rem;
}

.login-form label {
  display: grid;
  gap: 0.3rem;
  font-weight: 600;
}

.login-form input {
  border: 1px solid var(--border-strong);
  border-radius: 8px;
  padding: 0.55rem 0.7rem;
  background: var(--surface-alt);
  color: var(--text);
}

.login-form button {
  border: none;
  border-radius: 8px;
  padding: 0.6rem 0.8rem;
  background: var(--accent);
  color: #fff;
  cursor: pointer;
}

.login-form button:disabled {
  opacity: 0.7;
  cursor: not-allowed;
}

.error-text {
  margin-top: 0.9rem;
  color: var(--danger);
}
</style>
