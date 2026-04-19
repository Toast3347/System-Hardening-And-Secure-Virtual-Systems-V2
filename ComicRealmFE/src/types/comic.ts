export interface ComicDto {
  comicId: number
  serie: string
  number: string
  title: string
  createdBy: number
  createdAt: string
  updatedAt: string
}

export interface CreateComicDto {
  serie: string
  number: string
  title: string
  createdBy: number
}

export interface UpdateComicDto {
  serie: string
  number: string
  title: string
}
