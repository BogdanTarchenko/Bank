import { create } from 'zustand'
import type { UserInfo } from '@/entities/auth'
import type { Role } from '@/entities/common'

interface AuthState {
  isAuthenticated: boolean
  user: UserInfo | null
  activeRole: 'client' | 'employee'
  setAuth: (user: UserInfo, accessToken: string, refreshToken: string) => void
  logout: () => void
  setActiveRole: (role: 'client' | 'employee') => void
  hasRole: (role: Role) => boolean
}

export const useAuthStore = create<AuthState>((set, get) => ({
  isAuthenticated: !!localStorage.getItem('access_token'),
  user: null,
  activeRole: (localStorage.getItem('active_role') as 'client' | 'employee') || 'client',

  setAuth: (user, accessToken, refreshToken) => {
    localStorage.setItem('access_token', accessToken)
    localStorage.setItem('refresh_token', refreshToken)
    set({ isAuthenticated: true, user })
  },

  logout: () => {
    localStorage.removeItem('access_token')
    localStorage.removeItem('refresh_token')
    localStorage.removeItem('active_role')
    set({ isAuthenticated: false, user: null, activeRole: 'client' })
  },

  setActiveRole: (role) => {
    localStorage.setItem('active_role', role)
    set({ activeRole: role })
  },

  hasRole: (role) => {
    const { user } = get()
    return user?.roles.includes(role) ?? false
  },
}))
