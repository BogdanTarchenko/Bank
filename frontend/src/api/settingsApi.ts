import { httpClient } from '@/network/httpClient'
import { endpoints } from '@/network/endpoints'
import type { SettingsResponse, UpdateSettingsRequest } from '@/entities/settings'

export const settingsApi = {
  async getSettings(userId: number, portal: 'client' | 'employee' = 'client'): Promise<SettingsResponse> {
    const { data } = await httpClient.get<SettingsResponse>(endpoints[portal].settings, {
      params: { userId },
    })
    return data
  },

  async updateSettings(
    userId: number,
    request: UpdateSettingsRequest,
    portal: 'client' | 'employee' = 'client',
  ): Promise<SettingsResponse> {
    const { data } = await httpClient.put<SettingsResponse>(endpoints[portal].settings, request, {
      params: { userId },
    })
    return data
  },
}
