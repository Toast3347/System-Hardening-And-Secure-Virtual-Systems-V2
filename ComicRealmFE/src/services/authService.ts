import type { AuthResponse, AuthUser, LoginPayload, RoleName } from '@/types/auth'
import { apiRequest } from './httpClient'

function normalizeRole(role: string): RoleName {
  if (role === 'SuperAdmin' || role === 'superadmin' || role === 'super admin') {
    return 'SuperAdmin'
  }

  if (role === 'Admin' || role === 'admin') {
    return 'Admin'
  }

  return 'Friend'
}

export async function login(payload: LoginPayload): Promise<{ token: string; user: AuthUser }> {
  const response = await apiRequest<AuthResponse>('/auth/login', {
    method: 'POST',
    body: JSON.stringify(payload),
  })

  return {
    token: response.token,
    user: {
      userId: response.userId,
      email: response.email,
      role: normalizeRole(response.role),
    },
  }
}

export async function logout(): Promise<void> {
  try {
    await apiRequest('/auth/logout', { method: 'POST' })
  } catch {
    // Logout should still clear local state even if server session is not present.
  }
}
