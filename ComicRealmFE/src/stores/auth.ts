import { computed, ref } from 'vue'
import { defineStore } from 'pinia'
import type { AuthUser, LoginPayload, RoleName } from '@/types/auth'
import { login as loginRequest, logout as logoutRequest } from '@/services/authService'
import {
  clearAuthSession,
  getStoredToken,
  getStoredUser,
  registerUnauthorizedHandler,
  saveAuthSession,
} from '@/services/authSession'

export const useAuthStore = defineStore('auth', () => {
  const token = ref<string | null>(null)
  const user = ref<AuthUser | null>(null)

  registerUnauthorizedHandler(() => {
    clearSession()
    window.dispatchEvent(new Event('comicrealm:auth-expired'))
  })

  const isAuthenticated = computed(() => Boolean(token.value && user.value))

  const role = computed<RoleName | null>(() => user.value?.role ?? null)

  const isSuperAdmin = computed(() => role.value === 'SuperAdmin')
  const isAdmin = computed(() => role.value === 'Admin')
  const isFriend = computed(() => role.value === 'Friend')

  function restoreSession(): void {
    const savedToken = getStoredToken()
    const savedUser = getStoredUser()

    if (!savedToken || !savedUser) {
      return
    }

    token.value = savedToken
    user.value = savedUser
  }

  function saveSession(newToken: string, newUser: AuthUser): void {
    token.value = newToken
    user.value = newUser
    saveAuthSession(newToken, newUser)
  }

  function clearSession(): void {
    token.value = null
    user.value = null
    clearAuthSession()
  }

  async function login(payload: LoginPayload): Promise<void> {
    const { token: authToken, user: authUser } = await loginRequest(payload)
    saveSession(authToken, authUser)
  }

  async function logout(): Promise<void> {
    await logoutRequest()
    clearSession()
  }

  return {
    token,
    user,
    role,
    isAuthenticated,
    isSuperAdmin,
    isAdmin,
    isFriend,
    restoreSession,
    login,
    logout,
    clearSession,
  }
})
