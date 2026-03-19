import type { Role } from './common'

export interface UserResponse {
  id: number
  email: string
  firstName: string
  lastName: string
  phone: string | null
  blocked: boolean
  roles: Role[]
  createdAt: string
  updatedAt: string
}

export interface CreateUserRequest {
  email: string
  firstName: string
  lastName: string
  phone?: string
  roles: Role[]
}

export interface UpdateUserRequest {
  email?: string
  firstName?: string
  lastName?: string
  phone?: string
}
