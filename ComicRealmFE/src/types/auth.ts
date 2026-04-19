export type RoleName = 'SuperAdmin' | 'Admin' | 'Friend'

export interface AuthResponse {
  token: string
  userId: number
  email: string
  role: string
}

export interface AuthUser {
  userId: number
  email: string
  role: RoleName
}

export interface LoginPayload {
  email: string
  passwordHash: string
}
