import type { User } from './User'

export interface Comic {
  comicId: number
  serie: string
  number: string
  title: string
  createdBy: number
  createdAt: string
  updatedAt: string
  createdByUser: User
}
