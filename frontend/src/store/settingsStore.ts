import { create } from 'zustand'
import { Theme } from '@/entities/common'

interface SettingsState {
  theme: Theme
  hiddenAccounts: number[]
  setTheme: (theme: Theme) => void
  setHiddenAccounts: (accounts: number[]) => void
  toggleAccountVisibility: (accountId: number) => void
  isAccountHidden: (accountId: number) => boolean
}

export const useSettingsStore = create<SettingsState>((set, get) => ({
  theme: (localStorage.getItem('theme') as Theme) || Theme.LIGHT,
  hiddenAccounts: JSON.parse(localStorage.getItem('hidden_accounts') || '[]') as number[],

  setTheme: (theme) => {
    localStorage.setItem('theme', theme)
    set({ theme })
  },

  setHiddenAccounts: (accounts) => {
    localStorage.setItem('hidden_accounts', JSON.stringify(accounts))
    set({ hiddenAccounts: accounts })
  },

  toggleAccountVisibility: (accountId) => {
    const { hiddenAccounts } = get()
    const updated = hiddenAccounts.includes(accountId)
      ? hiddenAccounts.filter((id) => id !== accountId)
      : [...hiddenAccounts, accountId]
    localStorage.setItem('hidden_accounts', JSON.stringify(updated))
    set({ hiddenAccounts: updated })
  },

  isAccountHidden: (accountId) => {
    return get().hiddenAccounts.includes(accountId)
  },
}))
