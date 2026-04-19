import type { RoleName } from './auth'

export interface UserDto {
  userId: number
  email: string
  role: RoleName
  createdBy: number | null
  createdAt: string
  updatedAt: string
  isActive: boolean
}

export interface CreateUserDto {
  email: string
  passwordHash: string
  role: RoleName
  createdBy: number | null
  isActive: boolean
}

export interface UpdateUserDto {
  email: string
  role: RoleName
  createdBy: number | null
  isActive: boolean
}
