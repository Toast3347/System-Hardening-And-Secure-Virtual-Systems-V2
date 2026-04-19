import type { ComicDto, CreateComicDto, UpdateComicDto } from '@/types/comic'
import { apiRequest } from './httpClient'

export function getComics(): Promise<ComicDto[]> {
  return apiRequest<ComicDto[]>('/comics')
}

export function createComic(payload: CreateComicDto): Promise<ComicDto> {
  return apiRequest<ComicDto>('/comics', {
    method: 'POST',
    body: JSON.stringify(payload),
  })
}

export function updateComic(comicId: number, payload: UpdateComicDto): Promise<void> {
  return apiRequest<void>(`/comics/${comicId}`, {
    method: 'PUT',
    body: JSON.stringify(payload),
  })
}

export function deleteComic(comicId: number): Promise<void> {
  return apiRequest<void>(`/comics/${comicId}`, {
    method: 'DELETE',
  })
}
