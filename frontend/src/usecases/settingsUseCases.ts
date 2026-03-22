/**
 * Use-case: Настройки пользователя
 * Содержит бизнес-логику загрузки/обновления темы и скрытых счетов.
 */
import { settingsApi } from '@/api/settingsApi'
import { accountApi } from '@/api/accountApi'
import type { AccountResponse } from '@/entities/account'
import type { SettingsResponse } from '@/entities/settings'
import type { Theme } from '@/entities/common'

/** Данные для страницы настроек клиента */
export interface ClientSettingsData {
  accounts: AccountResponse[]
  settings: SettingsResponse | null
}

/** Загружает настройки и счета для клиентского портала */
export async function fetchClientSettings(userId: number): Promise<ClientSettingsData> {
  const [accounts, settings] = await Promise.all([
    accountApi.getAccounts(),
    settingsApi.getSettings(userId).catch(() => null),
  ])
  return {
    accounts: accounts.filter((a) => !a.isClosed),
    settings,
  }
}

/** Обновляет тему */
export async function updateTheme(
  userId: number,
  theme: Theme,
  portal: 'client' | 'employee' = 'client',
): Promise<void> {
  await settingsApi.updateSettings(userId, { theme }, portal)
}

/** Обновляет список скрытых счетов */
export async function updateHiddenAccounts(
  userId: number,
  hiddenAccounts: number[],
): Promise<void> {
  await settingsApi.updateSettings(userId, { hiddenAccounts })
}

export async function fetchEmployeeSettings(userId: number): Promise<SettingsResponse | null> {
  return settingsApi.getSettings(userId, 'employee').catch(() => null)
}
