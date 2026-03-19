import type { Theme } from './common'

export interface SettingsResponse {
  userId: number
  theme: Theme
  hiddenAccounts: number[]
}

export interface UpdateSettingsRequest {
  theme?: Theme
  hiddenAccounts?: number[]
}
