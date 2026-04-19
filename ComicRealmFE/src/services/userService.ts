import type { CreateUserDto, UpdateUserDto, UserDto } from '@/types/user'
import { apiRequest } from './httpClient'

export function getUsers(): Promise<UserDto[]> {
  return apiRequest<UserDto[]>('/users')
}

export function createUser(payload: CreateUserDto): Promise<UserDto> {
  return apiRequest<UserDto>('/users', {
    method: 'POST',
    body: JSON.stringify(payload),
  })
}

export function updateUser(userId: number, payload: UpdateUserDto): Promise<UserDto> {
  return apiRequest<UserDto>(`/users/${userId}`, {
    method: 'PUT',
    body: JSON.stringify(payload),
  })
}

export function deleteUser(userId: number): Promise<void> {
  return apiRequest<void>(`/users/${userId}`, {
    method: 'DELETE',
  })
}
