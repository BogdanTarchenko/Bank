import { httpClient } from '@/network/httpClient'
import { endpoints } from '@/network/endpoints'
import type { UserResponse, CreateUserRequest, UpdateUserRequest } from '@/entities/user'

export const userApi = {
  async getUsers(portal: 'client' | 'employee' = 'client'): Promise<UserResponse[]> {
    const { data } = await httpClient.get<UserResponse[]>(endpoints[portal].users)
    return data
  },

  async getUser(id: number, portal: 'client' | 'employee' = 'client'): Promise<UserResponse> {
    const { data } = await httpClient.get<UserResponse>(endpoints[portal].user(id))
    return data
  },

  async getUserByEmail(email: string): Promise<UserResponse> {
    const { data } = await httpClient.get<UserResponse>(endpoints.client.userByEmail, {
      params: { email },
    })
    return data
  },

  async createUser(request: CreateUserRequest): Promise<UserResponse> {
    const { data } = await httpClient.post<UserResponse>(endpoints.employee.users, request)
    return data
  },

  async updateUser(id: number, request: UpdateUserRequest): Promise<UserResponse> {
    const { data } = await httpClient.put<UserResponse>(endpoints.employee.user(id), request)
    return data
  },

  async blockUser(id: number): Promise<UserResponse> {
    const { data } = await httpClient.patch<UserResponse>(endpoints.employee.userBlock(id))
    return data
  },

  async unblockUser(id: number): Promise<UserResponse> {
    const { data } = await httpClient.patch<UserResponse>(endpoints.employee.userUnblock(id))
    return data
  },
}
