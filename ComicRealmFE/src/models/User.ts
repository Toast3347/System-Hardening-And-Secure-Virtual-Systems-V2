import type { Comic } from './Comic'
import type { UserRole } from './enums/UserRole'

export interface User {
  userId: number
  email: string
  passwordHash: string
  role: UserRole
  createdBy: number | null
  createdAt: string
  updatedAt: string
  isActive: boolean
  createdByUser: User | null
  createdUsers: User[]
  comics: Comic[]
}
