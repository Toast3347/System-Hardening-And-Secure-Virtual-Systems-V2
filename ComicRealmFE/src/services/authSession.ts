import type { AuthUser } from '@/types/auth'

const TOKEN_KEY = 'comicrealm.auth.token'
const USER_KEY = 'comicrealm.auth.user'

let unauthorizedHandler: (() => void) | null = null

export function registerUnauthorizedHandler(handler: (() => void) | null): void {
  unauthorizedHandler = handler
}

export function notifyUnauthorized(): void {
  unauthorizedHandler?.()
}

export function getStoredToken(): string | null {
  return localStorage.getItem(TOKEN_KEY)
}

export function getStoredUser(): AuthUser | null {
  const savedUser = localStorage.getItem(USER_KEY)
  if (!savedUser) {
    return null
  }

  try {
    return JSON.parse(savedUser) as AuthUser
  } catch {
    return null
  }
}

export function saveAuthSession(token: string, user: AuthUser): void {
  localStorage.setItem(TOKEN_KEY, token)
  localStorage.setItem(USER_KEY, JSON.stringify(user))
}

export function clearAuthSession(): void {
  localStorage.removeItem(TOKEN_KEY)
  localStorage.removeItem(USER_KEY)
}
